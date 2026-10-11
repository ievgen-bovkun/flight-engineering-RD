"""Motor physics implemented directly with SciPy, independent of MATLAB traces."""
import json
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp

PROJECT_ROOT = Path(__file__).resolve().parents[2]


def load_config(path=None):
    return json.loads(Path(path or PROJECT_ROOT / "config/parameters.json").read_text(encoding="utf-8-sig"))


def validate_parameters(p):
    positive = [p[k] for k in ("Ra", "La", "Kt", "Ke", "Jm", "JL")]
    if not np.isfinite(positive + [p["Bm"]]).all() or min(positive) <= 0 or p["Bm"] < 0:
        raise ValueError("Positive electrical/inertia constants and nonnegative damping are required")


def transfer_coefficients(p):
    validate_parameters(p)
    inertia = p["Jm"] + p["JL"]
    return [p["Kt"]], [p["La"] * inertia, p["La"] * p["Bm"] + p["Ra"] * inertia,
                        p["Ra"] * p["Bm"] + p["Kt"] * p["Ke"]]


def plant_rhs(state, voltage, torque, p):
    validate_parameters(p)
    current, speed = state
    return np.array([(voltage - p["Ra"] * current - p["Ke"] * speed) / p["La"],
                     (p["Kt"] * current - p["Bm"] * speed - torque) / (p["Jm"] + p["JL"])])


def integrate_segments(config, scenario, initial, rhs, max_step):
    horizon, step = scenario["tEnd"], scenario.get("outputStep", config["numerics"]["outputStep"])
    if not np.isfinite([horizon, step]).all() or horizon <= 0 or step <= 0:
        raise ValueError("Finite positive time settings required")
    time = np.arange(int(np.floor(horizon / step + 1e-10)) + 1) * step
    if abs(time[-1] - horizon) > 1e-12:
        time = np.append(time, horizon)
    load_time = scenario.get("loadTime")
    events = sorted(set([0.0, horizon] + ([load_time] if load_time is not None and 0 < load_time < horizon else [])))
    states = np.empty((len(time), len(initial)))
    state = np.asarray(initial, dtype=float)
    for start, end in zip(events[:-1], events[1:]):
        torque = scenario.get("loadTorque", 0) if load_time is None or start >= load_time else 0.0
        solution = solve_ivp(lambda t, x: rhs(t, x, torque), (start, end), state,
                             method="DOP853", rtol=config["numerics"]["relativeTolerance"],
                             atol=config["numerics"]["absoluteTolerance"], max_step=max_step,
                             dense_output=True)
        if not solution.success:
            raise RuntimeError(solution.message)
        mask = (time >= start - 1e-12) & (time <= end + 1e-12)
        states[mask] = solution.sol(np.clip(time[mask], start, end)).T
        state = solution.y[:, -1]
    if not np.isfinite(states).all():
        raise RuntimeError("Nonfinite simulated trajectory")
    return time, states


def simulate_plant(config, scenario):
    p = config["physical"]
    time, states = integrate_segments(config, scenario, scenario.get("x0", [0, 0]),
        lambda _, x, torque: plant_rhs(x, scenario["voltage"], torque, p), 0.01)
    return {"time": time, "current": states[:, 0], "omega": states[:, 1],
            "voltage": np.full(len(time), scenario["voltage"])}
