"""Report delivery must never turn incomplete or stale evidence into success."""
import importlib.util
import json
from pathlib import Path

import pytest
from pypdf import PdfReader

PROJECT = Path(__file__).resolve().parents[2]


def module():
    path = PROJECT / "report/build_report.py"
    assert path.exists(), "The report builder is not implemented"
    spec = importlib.util.spec_from_file_location("coursework_report", path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def evidence(tmp_path):
    (tmp_path / "results").mkdir()
    (tmp_path / "config").mkdir()
    (tmp_path / "config/parameters.json").write_text('{"physical": {}}')
    import hashlib
    digest = hashlib.sha256((tmp_path / "config/parameters.json").read_bytes()).hexdigest()
    manifest = {"schemaVersion": 1, "complete": False,
                "sections": {"core": {"status": "passed"}, "simscape": {"status": "blocked"}},
                "files": [{"path": "config/parameters.json", "sha256": digest}]}
    (tmp_path / "results/run_manifest.json").write_text(json.dumps(manifest))
    return manifest


def test_final_report_rejects_incomplete_manifest(tmp_path):
    evidence(tmp_path)
    with pytest.raises(ValueError, match="Incomplete"):
        module().validate_manifest(tmp_path, draft=False)


def test_draft_rejects_changed_evidence(tmp_path):
    evidence(tmp_path)
    (tmp_path / "config/parameters.json").write_text('{"physical": {"Ra": 99}}')
    with pytest.raises(ValueError, match="Stale"):
        module().validate_manifest(tmp_path, draft=True)


def test_draft_rejects_missing_evidence(tmp_path):
    evidence(tmp_path)
    (tmp_path / "config/parameters.json").unlink()
    with pytest.raises(ValueError, match="Missing"):
        module().validate_manifest(tmp_path, draft=True)


def test_manifest_cannot_claim_success_by_flag_only(tmp_path):
    record = evidence(tmp_path)
    record["complete"] = True
    (tmp_path / "results/run_manifest.json").write_text(json.dumps(record))
    with pytest.raises(ValueError, match="Incomplete"):
        module().validate_manifest(tmp_path, draft=False)


def test_ukrainian_draft_uses_measured_values_and_discloses_gaps(tmp_path):
    builder = module()
    manifest = builder.validate_manifest(PROJECT, draft=True)
    output = builder.build_report(PROJECT, draft=True, output=tmp_path / "draft.pdf")
    reader = PdfReader(output)
    text = "\n".join(page.extract_text() for page in reader.pages)
    assert "ПРОМІЖНИЙ ЗВІТ" in text
    assert "Simscape" in text and "FMU" in text
    assert "1.675" in text and "0.163" in text
    assert "109.847" in text
    assert "Джерела" in text
    import re
    expected_pages = 1 + len(re.findall(r"^## ", (PROJECT / "report/report_uk.md").read_text(encoding="utf-8"), re.MULTILINE))
    assert len(reader.pages) == expected_pages
    assert manifest['sections']['modeling']['status'] == 'passed'
