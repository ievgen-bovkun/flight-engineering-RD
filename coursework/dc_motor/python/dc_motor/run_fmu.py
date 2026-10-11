"""Run genuine Simulink tool-coupling FMUs with a dedicated local MATLAB session.

No standalone license is used. FMPy calls the FMI DLL; the DLL delegates
simulation to the same-release licensed MATLAB/Simulink installation.
"""
from contextlib import nullcontext
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from zipfile import ZipFile

import numpy as np
from fmpy import read_model_description, extract
from fmpy.fmi2 import FMU2Slave

from .model import PROJECT_ROOT, load_config, simulate_plant
from .controller import simulate
from .metrics import performance_metrics
from .run_comparison import validated_gains

SOURCE_SHA256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def inspect_fmu(path, kind):
    path = Path(path)
    if not path.is_file():
        raise FileNotFoundError(path)
    with ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('FMU CRC check failed')
        names = archive.namelist()
        if 'resources/obj/blank_project.zip' not in names:
            raise ValueError('Expected documented Simulink tool-coupling project')
    description = read_model_description(str(path), validate=True)
    inputs = ['Vin', 'TL'] if kind == 'plant' else ['omega_ref', 'TL']
    outputs = ['omega', 'i'] if kind == 'plant' else ['omega', 'i', 'Vin']
    actual_inputs = [v.name for v in description.modelVariables if v.causality == 'input']
    actual_outputs = [v.name for v in description.modelVariables if v.causality == 'output']
    if (description.fmiVersion != '2.0' or description.coSimulation is None
            or 'Simulink (R2026a)' != description.generationTool
            or actual_inputs != inputs or actual_outputs != outputs):
        raise ValueError('FMU generation metadata/interface does not match coursework')
    units = {'Vin': 'V', 'TL': 'N*m', 'omega_ref': 'rad/s', 'omega': 'rad/s', 'i': 'A'}
    for variable in description.modelVariables:
        if variable.name in units and variable.unit != units[variable.name]:
            raise ValueError('Incorrect FMU unit: ' + variable.name)
    binary = 'binaries/win64/' + description.coSimulation.modelIdentifier + '.dll'
    if binary not in names:
        raise ValueError('Missing executable win64 FMU binary')
    return {'route': 'tool_coupling', 'generationTool': description.generationTool,
            'inputs': actual_inputs, 'outputs': actual_outputs,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


class MatlabSession:
    """Own only the dedicated MathWorks FMU manager and its MATLAB child."""
    def __init__(self, matlab_root=None):
        self.root = Path(matlab_root or os.environ.get('DC_MOTOR_MATLAB_ROOT', r'C:\Program Files\MATLAB\R2026a'))
        self.share = self.root / 'toolbox/shared/fmu_share'
        self.exe = self.share / 'bin/win64/fmu_matlab_setup.exe'
        self.process = None

    def __enter__(self):
        if not self.exe.is_file():
            raise FileNotFoundError(f'MATLAB tool-coupling manager missing: {self.exe}')
        environment = os.environ.copy()
        environment.update(FMU_MW_ARCH='win64', FMU_MW_INSTALL=str(self.share),
                           FMU_MW_MATLABROOT=str(self.root))
        environment['PATH'] = str(self.exe.parent) + os.pathsep + str(self.root / 'extern/bin/win64') + os.pathsep + environment['PATH']
        self.scratch = tempfile.TemporaryDirectory(prefix='dc_motor_fmu_session_')
        self.log = tempfile.TemporaryFile(mode='w+b')
        self.process = subprocess.Popen([str(self.exe), '1'], stdin=subprocess.PIPE,
            stdout=self.log, stderr=subprocess.STDOUT, env=environment,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            self.log.seek(0)
            text = self.log.read().decode(errors='replace')
            if 'Launched MATLAB #1' in text:
                return self
            if self.process.poll() is not None:
                self.close()
                raise RuntimeError(f'MATLAB FMU session failed to start: {text}')
            time.sleep(.2)
        self.close()
        raise TimeoutError('MATLAB FMU session did not become ready')

    def directory(self):
        return tempfile.mkdtemp(dir=self.scratch.name, prefix='instance_')

    def close(self):
        if self.process is not None:
            if self.process.poll() is None:
                self.process.stdin.write(b'quit\n')
                self.process.stdin.flush()
                try:
                    self.process.wait(timeout=60)
                except subprocess.TimeoutExpired:
                    self.process.terminate()
                    self.process.wait(timeout=10)
            self.process.stdin.close()
            self.log.close()
            self.process = None
            # The CLI manager exits before its MATLAB child finishes closing.
            deadline = time.monotonic() + 30
            while True:
                try:
                    self.scratch.cleanup()
                    break
                except PermissionError:
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(.25)

    def __exit__(self, *args):
        self.close()


def run_fmu(path, scenario, communication_step=.001, session=None):
    """Right-continuous ZOH inputs, fresh FMI instance, event-aligned grid.

    The local MATLAB session must be ready before this function is called.
    Outputs are sampled after each completed step; no time-shift correction.
    """
    if session is None:
        with MatlabSession() as runtime:
            return run_fmu(path, scenario, communication_step, session=runtime)
    kind = 'plant' if scenario['kind'] == 'plant' else 'pid'
    info = inspect_fmu(path, kind)
    if any(abs(x) > 0 for x in scenario.get('x0', [0, 0])):
        raise ValueError('Delivered FMUs have documented zero initial states')
    horizon = scenario['tEnd']
    load_time = scenario.get('loadTime')
    if communication_step <= 0 or abs(communication_step / .00001 - round(communication_step / .00001)) > 1e-10:
        raise ValueError('Communication step must be a positive multiple of FMU fixed step')
    for event in [horizon] + ([] if load_time is None else [load_time]):
        if abs(event / communication_step - round(event / communication_step)) > 1e-8:
            raise ValueError('All events and horizon must align with communication grid')
    description = read_model_description(str(path))
    references = {v.name: v.valueReference for v in description.modelVariables}
    with nullcontext(session.directory()) as directory:
        extract(str(path), unzipdir=directory)
        slave = FMU2Slave(guid=description.guid, unzipDirectory=directory,
                         modelIdentifier=description.coSimulation.modelIdentifier,
                         instanceName='dc_motor_' + scenario['id'])
        initialized = False
        instantiated = False
        try:
            slave.instantiate(visible=False)
            instantiated = True
            slave.setupExperiment(startTime=0, stopTime=horizon)
            slave.enterInitializationMode()
            primary = scenario['voltage'] if kind == 'plant' else scenario['reference']
            input_refs = [references[n] for n in info['inputs']]
            initial_load = scenario.get('loadTorque', 0) if load_time is None or load_time <= 0 else 0
            slave.setReal(input_refs, [primary, initial_load])
            slave.exitInitializationMode()
            initialized = True
            times = np.arange(round(horizon / communication_step) + 1) * communication_step
            values = np.empty((len(times), len(info['outputs'])))
            output_refs = [references[n] for n in info['outputs']]
            values[0] = slave.getReal(output_refs)
            for index, current_time in enumerate(times[:-1]):
                load = scenario.get('loadTorque', 0) if load_time is None or current_time >= load_time - 1e-12 else 0
                slave.setReal(input_refs, [primary, load])
                slave.doStep(float(current_time), communication_step)
                values[index + 1] = slave.getReal(output_refs)
            if not np.isfinite(values).all():
                raise RuntimeError('Nonfinite FMU trajectory')
            return {'time': times, 'omega': values[:, 0], 'current': values[:, 1],
                    'voltage': values[:, 2] if kind == 'pid' else np.full(len(times), primary),
                    'reference': scenario.get('reference', 100)}
        finally:
            if initialized:
                slave.terminate()
            if instantiated:
                slave.freeInstance()


def compare_fmus(communication_step=.001, write_outputs=True):
    config = load_config()
    scenarios = json.loads((PROJECT_ROOT / 'config/scenarios.json').read_text(encoding='utf-8-sig'))['scenarios']
    gains = validated_gains()
    records = []
    with MatlabSession() as session:
        for scenario in scenarios:
            if scenario['id'] not in ('zero_input', 'open_loop_12V', 'plant_load_step', 'pid_nominal', 'pid_required_load'):
                continue
            kind = 'plant' if scenario['kind'] == 'plant' else 'pid'
            print('FMU scenario:', scenario['id'], 'step:', communication_step, flush=True)
            output = run_fmu(PROJECT_ROOT / f'fmu/dc_motor_{kind}.fmu', scenario, communication_step, session=session)
            scenario = dict(scenario, outputStep=communication_step)
            independent = simulate_plant(config, scenario) if kind == 'plant' else simulate(config, scenario, gains)
            # MATLAB reference CSV is sampled at 1 ms, so compare only common samples.
            filename = scenario['id'] + '.csv' if kind == 'plant' else ('pid_optimized.csv' if scenario['id'] == 'pid_nominal' else 'disturbance_1_PID.csv')
            reference = np.genfromtxt(PROJECT_ROOT / 'results/csv' / filename, delimiter=',', names=True)
            indices = np.rint(reference['time_s'] / communication_step).astype(int)
            np.testing.assert_allclose(output['time'][indices], reference['time_s'], atol=1e-10)
            wc, ic = ('omega_reference', 'current_reference') if kind == 'plant' else ('omega_rad_s', 'current_A')
            row = {'scenario': scenario['id'], 'communication_step_s': communication_step,
                   'max_speed_error_python': float(np.max(abs(output['omega'] - independent['omega']))),
                   'max_current_error_python': float(np.max(abs(output['current'] - independent['current']))),
                   'max_speed_error_matlab': float(np.max(abs(output['omega'][indices] - reference[wc]))),
                   'max_current_error_matlab': float(np.max(abs(output['current'][indices] - reference[ic]))),
                   'max_voltage_error': float(np.max(abs(output['voltage'] - independent['voltage']))),
                   'settling_difference_s': 0.0}
            if kind == 'pid':
                row['settling_difference_s'] = abs(performance_metrics(output)['ts'] - performance_metrics(independent)['ts'])
            validate_comparison(row)
            records.append(row)
            if write_outputs:
                np.savetxt(PROJECT_ROOT / f'results/csv/fmu_{scenario["id"]}.csv',
                           np.column_stack([output[k] for k in ('time', 'omega', 'current', 'voltage')]),
                           delimiter=',', header='time_s,omega_rad_s,current_A,voltage_V', comments='')
            print(json.dumps(row), flush=True)
    return records


def validate_comparison(row):
    limits = {'max_speed_error_python': 1e-3, 'max_current_error_python': 1e-4,
              'max_speed_error_matlab': 1e-3, 'max_current_error_matlab': 1e-4,
              'max_voltage_error': 1e-2, 'settling_difference_s': .002}
    for name, limit in limits.items():
        value = float(row[name])
        if not np.isfinite(value) or value < 0 or value > limit + 1e-12:
            raise AssertionError(f'FMU numerical acceptance failed: {name}={value}, limit={limit}')


def run_study():
    import csv
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    coarse = compare_fmus(.001)
    fine = compare_fmus(.0005)
    for row in coarse + fine:
        validate_comparison(row)
    with (PROJECT_ROOT / 'results/csv/fmu_comparison.csv').open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(fine[0]))
        writer.writeheader(); writer.writerows(fine)
    nominal = np.genfromtxt(PROJECT_ROOT / 'results/csv/fmu_pid_nominal.csv', delimiter=',', names=True)
    reference = np.genfromtxt(PROJECT_ROOT / 'results/csv/pid_optimized.csv', delimiter=',', names=True)
    fig, axes = plt.subplots(2, 1, figsize=(10, 7), constrained_layout=True)
    for ax, column, label in [(axes[0], 'omega_rad_s', 'Швидкість, рад/с'), (axes[1], 'voltage_V', 'Напруга, В')]:
        ax.plot(nominal['time_s'], nominal[column], label='Python/FMPy: FMU MATLAB')
        ax.plot(reference['time_s'], reference[column], '--', label='MATLAB: рівняння')
        ax.set(xlabel='Час, с', ylabel=label); ax.grid(True); ax.legend()
    fig.savefig(PROJECT_ROOT / 'results/figures/fmu_comparison.png', dpi=180); plt.close(fig)
    record = {'passed': True, 'route': 'tool_coupling', 'standalone': False,
              'runtimeRequired': 'Licensed local MATLAB/Simulink R2026a',
              'coarseCommunicationStep': .001, 'acceptedCommunicationStep': .0005,
              'localSolverStep': .00001, 'coarse': coarse, 'fine': fine,
              'sourceSHA256': SOURCE_SHA256,
              'configSHA256': hashlib.sha256((PROJECT_ROOT / 'config/parameters.json').read_bytes()).hexdigest()}
    (PROJECT_ROOT / 'results/json/fmu_comparison.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8', newline='\n')
    return record


def validate_fmu_evidence(root=PROJECT_ROOT):
    import csv
    root = Path(root)
    record = json.loads((root / 'results/json/fmu_comparison.json').read_text(encoding='utf-8-sig'))
    exports = json.loads((root / 'results/json/fmu_export.json').read_text(encoding='utf-8-sig'))
    if not record.get('passed') or record.get('route') != 'tool_coupling' or record.get('standalone') is not False:
        raise ValueError('FMU evidence must identify actual licensed tool-coupling execution')
    if (record.get('sourceSHA256') != hashlib.sha256((root / 'python/dc_motor/run_fmu.py').read_bytes()).hexdigest()
            or record.get('configSHA256') != hashlib.sha256((root / 'config/parameters.json').read_bytes()).hexdigest()):
        raise ValueError('Stale FMU source/config evidence')
    if not exports.get('exportPassed') or exports.get('standalone') is not False:
        raise ValueError('Actual MATLAB FMU exports not confirmed')
    for file in exports['files']:
        path = root / file['path']
        if hashlib.sha256(path.read_bytes()).hexdigest() != file['sha256']:
            raise ValueError('FMU differs from MATLAB export proof')
        inspect_fmu(path, 'pid' if path.stem.endswith('pid') else 'plant')
    expected = {'zero_input','open_loop_12V','plant_load_step','pid_nominal','pid_required_load'}
    for group in ('coarse','fine'):
        if {row['scenario'] for row in record[group]} != expected or len(record[group]) != 5:
            raise ValueError('Incomplete FMU comparison scenarios')
        for row in record[group]:
            validate_comparison(row)
    with (root / 'results/csv/fmu_comparison.csv').open(encoding='utf-8-sig') as stream:
        rows = list(csv.DictReader(stream))
    if {row['scenario'] for row in rows} != expected or len(rows) != 5:
        raise ValueError('Incomplete FMU comparison CSV')
    for row in rows:
        validate_comparison(row)
    return record


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--step', type=float, default=.001)
    parser.add_argument('--study', action='store_true')
    args = parser.parse_args()
    print(json.dumps(run_study() if args.study else compare_fmus(args.step), indent=2))
