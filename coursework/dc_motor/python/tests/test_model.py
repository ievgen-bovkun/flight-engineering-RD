import numpy as np
import pytest

from dc_motor.model import load_config, plant_rhs, transfer_coefficients, simulate_plant


def test_independent_equations_and_transfer_coefficients():
    config = load_config()
    p = config["physical"]
    num, den = transfer_coefficients(p)
    np.testing.assert_allclose(num, [0.1], atol=1e-14)
    np.testing.assert_allclose(den, [0.015, 0.0605, 0.012], atol=1e-14)
    np.testing.assert_allclose(plant_rhs([1, 100], 12, 0, p), [0, 0], atol=1e-12)
    np.testing.assert_allclose(plant_rhs([1.5, 100], 13, 0.05, p), [0, 0], atol=1e-12)
    assert plant_rhs([0, 0], 0, 0.05, p)[1] < 0


def test_zero_input_and_nonzero_initial_state():
    s = {"voltage": 0, "loadTorque": 0, "x0": [0, 0], "tEnd": 1, "outputStep": 0.001}
    out = simulate_plant(load_config(), s)
    np.testing.assert_array_equal(out["omega"], np.zeros(1001))
    s["x0"] = [1, 10]
    out = simulate_plant(load_config(), s)
    assert out["current"][0] == 1 and out["omega"][0] == 10
    assert np.isfinite(out["omega"]).all()


def test_invalid_parameters_rejected():
    p = load_config()["physical"]
    p["La"] = 0
    with pytest.raises(ValueError):
        plant_rhs([0, 0], 12, 0, p)
