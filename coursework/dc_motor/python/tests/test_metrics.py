import numpy as np
import pytest

from dc_motor.metrics import performance_metrics


def fixture(omega, reference=100):
    return {"time": np.arange(len(omega), dtype=float), "omega": np.asarray(omega, dtype=float),
            "current": np.ones(len(omega)), "voltage": np.full(len(omega), 12.0), "reference": reference}


def test_last_exit_and_required_integrals():
    m = performance_metrics(fixture([0, 99, 103, 100, 100, 100, 100]))
    assert m["t_first"] == 1 and m["ts"] == 3 and m["os"] == 3
    assert m["effort"] == 72 and m["effort2"] == 864


def test_no_recovery_negative_and_zero_reference():
    assert np.isinf(performance_metrics(fixture([0, 100, 103]))["ts"])
    m = performance_metrics(fixture([0, -100, -103, -100, -100], -100))
    assert m["ts"] == 3 and m["os"] == 3
    assert performance_metrics(fixture([0, 0.01, 0, 0], 0))["ts"] == 0


def test_nonfinite_rejected():
    with pytest.raises(ValueError):
        performance_metrics(fixture([0, float("nan"), 100]))
