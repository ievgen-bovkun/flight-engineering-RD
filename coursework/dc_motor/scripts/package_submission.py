"""Allowlisted, deterministic coursework ZIP with strict payload checksums."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath
import sys
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT=Path(__file__).resolve().parents[1]


def eligible_files(root):
    root=Path(root).resolve()
    patterns=['README.md','requirements.txt','.gitignore',
              'config/*.json','matlab/**/*.m','matlab/models/*.slx',
              'python/**/*.py','reference/**/*.m','reference/**/*.json','reference/**/*.md',
              'report/*.py','report/*.md','report/DC_Motor_Coursework_UA.pdf',
              'results/csv/*.csv','results/json/*.json','results/figures/*.png',
              'results/run_manifest.json','scripts/*.ps1','scripts/*.py','fmu/*.fmu']
    return sorted({p for pattern in patterns for p in root.glob(pattern) if p.is_file()})


def source_records(root):
    root=Path(root).resolve()
    return [{'path':p.relative_to(root).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in eligible_files(root)
            if p.suffix in ('.m','.py','.ps1','.md') or p.parent.name=='config' or p.name=='requirements.txt']


def validate_delivery(root=ROOT):
    root=Path(root).resolve()
    path=root/'report/build_report.py'
    spec=importlib.util.spec_from_file_location('delivery_report',path)
    module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    module.validate_manifest(root,draft=False)
    if not (root/'report/DC_Motor_Coursework_UA.pdf').is_file():
        raise ValueError('Missing final Ukrainian PDF')
    proof=json.loads((root/'results/json/clean_copy.json').read_text(encoding='utf-8-sig'))
    if proof.get('sources') != source_records(root):
        raise ValueError('Clean-copy source checksum inventory differs from delivered source')
    return module


def package(root=ROOT,output=None,require_complete=True):
    root=Path(root).resolve()
    if require_complete:
        validate_delivery(root)
    output=Path(output or root/'delivery/DC_Motor_Coursework.zip')
    output.parent.mkdir(parents=True,exist_ok=True)
    files=eligible_files(root)
    checksums={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    payload={('dc_motor/'+name):(root/name).read_bytes() for name in checksums}
    payload['dc_motor/SHA256SUMS.json']=(json.dumps(checksums,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode('utf-8')
    with ZipFile(output,'w',compression=ZIP_DEFLATED,compresslevel=9) as archive:
        for name in sorted(payload):
            info=ZipInfo(name,date_time=(2026,1,1,0,0,0)); info.compress_type=ZIP_DEFLATED
            info.external_attr=0o100644 << 16
            archive.writestr(info,payload[name])
    verify_archive(output)
    checksum=hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(checksum+'  '+output.name+'\n',encoding='ascii',newline='\n')
    return output


def verify_archive(path):
    with ZipFile(path) as archive:
        names=archive.namelist()
        if len(names)!=len(set(names)) or archive.testzip() is not None:
            raise ValueError('ZIP duplicate entries or CRC failure')
        for name in names:
            pure=PurePosixPath(name)
            if pure.is_absolute() or '..' in pure.parts or '\\' in name or ':' in name or not name.startswith('dc_motor/'):
                raise ValueError('Unsafe ZIP path')
        checksums=json.loads(archive.read('dc_motor/SHA256SUMS.json'))
        expected={'dc_motor/'+name for name in checksums}|{'dc_motor/SHA256SUMS.json'}
        if set(names)!=expected:
            raise ValueError('ZIP checksum inventory differs from payload')
        for name,digest in checksums.items():
            if hashlib.sha256(archive.read('dc_motor/'+name)).hexdigest()!=digest:
                raise ValueError('ZIP payload checksum failed: '+name)
    return len(names)-1


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify',type=Path)
    args=parser.parse_args()
    print(verify_archive(args.verify) if args.verify else package())
