import json
import pytest

from dc_motor.model import PROJECT_ROOT
from dc_motor.run_comparison import validated_gains


def test_missing_and_stale_gains_are_rejected(tmp_path):
    with pytest.raises(FileNotFoundError):
        validated_gains(tmp_path / "absent.json")
    record = json.loads((PROJECT_ROOT / "results/json/optimization.json").read_text())
    record["provenance"]["parametersSHA256"] = "stale"
    candidate = tmp_path / "stale.json"
    candidate.write_text(json.dumps(record))
    with pytest.raises(ValueError, match="configuration"):
        validated_gains(candidate)


def test_real_result_has_valid_provenance():
    assert len(validated_gains()) == 3
