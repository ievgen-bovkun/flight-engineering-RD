"""Submission integrity and clean-copy evidence are required delivery gates."""
import importlib.util
from pathlib import Path
from zipfile import ZipFile
import pytest

PROJECT=Path(__file__).resolve().parents[2]


def delivery():
    path=PROJECT/'scripts/package_submission.py'
    assert path.is_file(), 'Submission packager is not implemented'
    spec=importlib.util.spec_from_file_location('coursework_delivery',path)
    result=importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


def fixture_project(tmp_path):
    (tmp_path/'README.md').write_text('Instructions',encoding='utf-8')
    for name in ('config/parameters.json','matlab/source.m','python/main.py','fmu/plant.fmu','results/csv/measured.csv','report/DC_Motor_Coursework_UA.pdf'):
        file=tmp_path/name; file.parent.mkdir(parents=True,exist_ok=True); file.write_bytes(b'fixture')
    for name in ('.venv/secret.txt','results/logs/private.txt','fmu/build/cache.txt','report/qa/image.png','delivery/old.zip'):
        file=tmp_path/name; file.parent.mkdir(parents=True,exist_ok=True); file.write_bytes(b'exclude')


def test_package_is_deterministic_and_excludes_scratch(tmp_path):
    fixture_project(tmp_path); tool=delivery()
    first=tool.package(tmp_path,tmp_path/'delivery/one.zip',require_complete=False)
    second=tool.package(tmp_path,tmp_path/'delivery/two.zip',require_complete=False)
    assert first.read_bytes()==second.read_bytes()
    with ZipFile(first) as archive:
        names=archive.namelist()
        assert archive.testzip() is None
        assert 'dc_motor/report/DC_Motor_Coursework_UA.pdf' in names
        assert not any('secret' in name or '/logs/' in name or '/build/' in name or '/qa/' in name or '/delivery/' in name for name in names)
    tool.verify_archive(first)


def test_archive_detects_changed_payload(tmp_path):
    fixture_project(tmp_path); tool=delivery()
    source=tool.package(tmp_path,tmp_path/'one.zip',require_complete=False)
    bad=tmp_path/'bad.zip'
    with ZipFile(source) as original, ZipFile(bad,'w') as modified:
        for name in original.namelist():
            modified.writestr(name,b'changed' if name.endswith('README.md') else original.read(name))
    with pytest.raises(ValueError,match='checksum'):
        tool.verify_archive(bad)


def test_package_rejects_incomplete_submission(tmp_path):
    fixture_project(tmp_path)
    with pytest.raises((ValueError,FileNotFoundError)):
        delivery().package(tmp_path,tmp_path/'delivery/incomplete.zip')
