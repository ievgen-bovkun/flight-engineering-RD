"""Reproduce Full computations from a fresh copy, then build/verify PDF and ZIP."""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from zipfile import ZipFile
from xml.etree import ElementTree

from package_submission import eligible_files, source_records, package, verify_archive

ROOT=Path(__file__).resolve().parents[1]


def load_report(root):
    spec=importlib.util.spec_from_file_location('verified_report',root/'report/build_report.py')
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    return module


def finish(matlab_exe):
    source=source_records(ROOT)
    log_path=ROOT/'results/logs/clean-reproduction.log'
    with tempfile.TemporaryDirectory(prefix='dc_motor_clean_') as scratch:
        clean=Path(scratch)/'repository/coursework/dc_motor'
        for path in eligible_files(ROOT):
            relative=path.relative_to(ROOT)
            if relative.as_posix()=='results/json/clean_copy.json':
                continue
            destination=clean/relative; destination.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,destination)
        command=['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(clean/'scripts/run_all.ps1'),
                 '-Mode','Full','-ComputeOnly','-MatlabExe',str(matlab_exe),'-PythonExe',sys.executable]
        print('Clean-copy Full CLI reproduction starting',flush=True)
        with log_path.open('w',encoding='utf-8') as log:
            result=subprocess.run(command,cwd=clean.parents[1],stdout=log,stderr=subprocess.STDOUT)
        if result.returncode:
            raise RuntimeError(f'Clean-copy Full reproduction failed: {log_path}')
        if source_records(clean)!=source or source_records(ROOT)!=source:
            raise ValueError('Sources changed during clean-copy reproduction')
        run=json.loads((clean/'results/json/matlab_run.json').read_text(encoding='utf-8-sig'))
        tests=ElementTree.parse(clean/'results/logs/python-tests.xml').getroot()
        suite=tests if tests.tag=='testsuite' else tests.find('testsuite')
        if run['tests']['failed'] or run['tests']['incomplete'] or int(suite.attrib.get('failures',0))+int(suite.attrib.get('errors',0))+int(suite.attrib.get('skipped',0)):
            raise ValueError('Clean-copy checks did not all pass')
        proof={'passed':True,'exitCode':0,'timestampUTC':datetime.now(timezone.utc).isoformat(),
               'route':'tool_coupling','sources':source,'matlabTests':run['tests'],
               'pythonTests':int(suite.attrib['tests']),
               'method':'Fresh allowlisted source/evidence copy; no local venv or ignored MAT caches; Full CLI with explicit external pinned Python runtime'}
        (ROOT/'results/json/clean_copy.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8',newline='\n')
    builder=load_report(ROOT)
    builder.create_manifest(ROOT)
    pdf=builder.build_report(ROOT,draft=False)
    archive=package(ROOT)
    with tempfile.TemporaryDirectory(prefix='dc_motor_archive_check_') as scratch:
        verify_archive(archive)
        with ZipFile(archive) as zipped:
            zipped.extractall(scratch)
        extracted=Path(scratch)/'dc_motor'
        checked=load_report(extracted)
        checked.validate_manifest(extracted,draft=False)
        checked.build_report(extracted,draft=False,output=Path(scratch)/'regenerated.pdf')
    print('FINAL DELIVERY VERIFIED:',pdf,archive,flush=True)
    return archive


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--matlab-exe',type=Path,default=Path(r'C:\Program Files\MATLAB\R2026a\bin\matlab.exe'))
    args=parser.parse_args(); finish(args.matlab_exe)
