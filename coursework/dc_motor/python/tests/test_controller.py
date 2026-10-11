import numpy as np
import pytest

from dc_motor.model import load_config
from dc_motor.controller import settings, control_signal, simulate
from dc_motor.metrics import performance_metrics


def test_filter_and_applied_limits_are_explicit():
    config = load_config()
    gains = [11.0456, 21.89, 1.3288]
    ctl = settings(config, gains)
    assert ctl["Tf"] == pytest.approx(1.3288 / (20 * 11.0456))
    error, voltage, raw, derivative_input = control_signal(np.zeros(4), gains, ctl)
    assert error == 100 and voltage == 48 and raw > 48 and derivative_input == 0
    with pytest.raises(ValueError):
        settings(config, [float("nan"), 1, 1])


def test_audited_nominal_response():
    out = simulate(load_config(), {"tEnd": 5, "outputStep": 0.001}, [11.0456, 21.89, 1.3288])
    metrics = performance_metrics(out)
    assert metrics["ts"] == pytest.approx(1.717, abs=0.002)
    assert metrics["os"] == pytest.approx(0.137, abs=0.01)
    assert np.min(out["voltage"]) >= -48 and np.max(out["voltage"]) <= 48
