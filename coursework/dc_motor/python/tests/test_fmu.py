"""Real MATLAB FMUs must have the correct tool-coupling interface and provenance."""
from pathlib import Path
import pytest

PROJECT = Path(__file__).resolve().parents[2]


def test_real_matlab_export_interfaces():
    from dc_motor.run_fmu import inspect_fmu
    plant = inspect_fmu(PROJECT / 'fmu/dc_motor_plant.fmu', 'plant')
    pid = inspect_fmu(PROJECT / 'fmu/dc_motor_pid.fmu', 'pid')
    assert plant['inputs'] == ['Vin', 'TL']
    assert pid['outputs'] == ['omega', 'i', 'Vin']
    assert plant['route'] == pid['route'] == 'tool_coupling'
    assert 'R2026a' in plant['generationTool']


def test_missing_fmu_fails_clearly(tmp_path):
    from dc_motor.run_fmu import inspect_fmu
    with pytest.raises(FileNotFoundError):
        inspect_fmu(tmp_path / 'absent.fmu', 'plant')


def test_no_local_matlab_fails_clearly(tmp_path):
    from dc_motor.run_fmu import MatlabSession
    with pytest.raises(FileNotFoundError, match='MATLAB'):
        with MatlabSession(tmp_path / 'no-matlab'):
            pass

def test_fmu_runtime_releases_extracted_project():
    from dc_motor.run_fmu import MatlabSession, run_fmu
    scenario = {'id': 'cleanup', 'kind': 'plant', 'voltage': 0,
                'loadTorque': 0, 'x0': [0, 0], 'tEnd': .002}
    with MatlabSession() as session:
        result = run_fmu(PROJECT / 'fmu/dc_motor_plant.fmu', scenario, session=session)
        scratch = Path(session.scratch.name)
        assert abs(result['omega'][-1]) < 1e-12

    assert not scratch.exists()

def test_numerical_acceptance_rejects_voltage_error():
    from dc_motor.run_fmu import validate_comparison
    row = {'max_speed_error_python': 0, 'max_current_error_python': 0,
           'max_speed_error_matlab': 0, 'max_current_error_matlab': 0,
           'max_voltage_error': .1, 'settling_difference_s': 0}
    with pytest.raises(AssertionError, match='voltage'):
        validate_comparison(row)


def test_numerical_acceptance_rejects_nonfinite():
    from dc_motor.run_fmu import validate_comparison
    row = {'max_speed_error_python': float('nan'), 'max_current_error_python': 0,
           'max_speed_error_matlab': 0, 'max_current_error_matlab': 0,
           'max_voltage_error': 0, 'settling_difference_s': 0}
    with pytest.raises(AssertionError):
        validate_comparison(row)

def test_closed_loop_fmu_supports_metric_reference():
    from dc_motor.run_fmu import run_fmu
    from dc_motor.metrics import performance_metrics
    scenario = {'id': 'metric_reference', 'kind': 'closed_loop', 'reference': 100,
                'loadTorque': 0, 'x0': [0, 0], 'tEnd': .002}
    result = run_fmu(PROJECT / 'fmu/dc_motor_pid.fmu', scenario)
    assert performance_metrics(result)['iae'] > 0

def test_fmu_rejects_incorrect_speed_unit(tmp_path):
    from zipfile import ZipFile
    from xml.etree import ElementTree
    from dc_motor.run_fmu import inspect_fmu
    corrupted = tmp_path / 'wrong_unit.fmu'
    with ZipFile(PROJECT / 'fmu/dc_motor_pid.fmu') as original, ZipFile(corrupted, 'w') as modified:
        for name in original.namelist():
            data = original.read(name)
            if name == 'modelDescription.xml':
                xml = ElementTree.fromstring(data)
                xml.find("./ModelVariables/ScalarVariable[@name='omega']/Real").set('unit', 'V')
                data = ElementTree.tostring(xml)
            modified.writestr(name, data)
    with pytest.raises(ValueError, match='unit'):
        inspect_fmu(corrupted, 'pid')
