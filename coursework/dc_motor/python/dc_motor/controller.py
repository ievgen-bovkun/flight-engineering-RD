"""Filtered derivative-on-measurement PID, saturation and back-calculation."""
import numpy as np

from .model import integrate_segments, plant_rhs


def settings(config, gains, scenario=None):
    gains = np.asarray(gains, dtype=float)
    if gains.shape != (3,) or not np.isfinite(gains).all() or (gains < 0).any() or gains[0] <= 0:
        raise ValueError("Expected finite nonnegative Kp, Ki, Kd with Kp positive")
    p = config["control"]
    result = dict(p)
    result["Tf"] = max(gains[2] / (p["derivativeRatio"] * gains[0]), p["minimumFilterTime"])
    if gains[1] > 0:
        result["Tt"] = np.sqrt(gains[2] / gains[1]) if gains[2] > 0 else gains[0] / gains[1]
    else:
        result["Tt"] = np.inf
    result.update({"sat": True, "aw": True})
    if scenario:
        for key in ("reference", "sat", "aw", "Vmin", "Vmax", "beta", "gamma"):
            if key in scenario:
                result[key] = scenario[key]
    return result


def control_signal(state, gains, ctl):
    speed = state[1]
    error = ctl["reference"] - speed
    proportional_error = ctl["beta"] * ctl["reference"] - speed
    derivative_input = ctl["gamma"] * ctl["reference"] - speed
    raw = gains[0] * proportional_error + state[2] + gains[2] * (derivative_input - state[3]) / ctl["Tf"]
    voltage = float(np.clip(raw, ctl["Vmin"], ctl["Vmax"])) if ctl["sat"] else raw
    return error, voltage, raw, derivative_input


def simulate(config, scenario, gains):
    ctl = settings(config, gains, scenario)
    p = config["physical"]

    def rhs(_, state, torque):
        error, voltage, raw, derivative_input = control_signal(state, gains, ctl)
        integral_rate = gains[1] * error
        if ctl["sat"] and ctl["aw"] and np.isfinite(ctl["Tt"]):
            integral_rate += (voltage - raw) / ctl["Tt"]
        return np.r_[plant_rhs(state[:2], voltage, torque, p),
                     integral_rate, (derivative_input - state[3]) / ctl["Tf"]]

    initial = scenario.get("x0", [0, 0])
    if len(initial) == 2:
        initial = list(initial) + [0, 0]
    time, states = integrate_segments(config, scenario, initial, rhs, 0.001)
    voltage = np.asarray([control_signal(x, gains, ctl)[1] for x in states])
    return {"time": time, "omega": states[:, 1], "current": states[:, 0],
            "voltage": voltage, "reference": ctl["reference"], "states": states}
