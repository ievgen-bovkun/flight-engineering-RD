"""Independent definitions of reference-based settling, overshoot and effort."""
import numpy as np


def performance_metrics(out, band=0.02):
    time, speed, voltage = (np.asarray(out[k], dtype=float) for k in ("time", "omega", "voltage"))
    reference = out["reference"]
    if len(time) < 2 or len(speed) != len(time) or len(voltage) != len(time) or (np.diff(time) <= 0).any():
        raise ValueError("Equal-length samples on a strictly increasing time grid required")
    if not np.isfinite(np.r_[time, speed, voltage, reference]).all():
        raise ValueError("Nonfinite trajectory")
    error = reference - speed
    outside = np.abs(error) > band * max(abs(reference), 1)
    bad, good = np.flatnonzero(outside), np.flatnonzero(~outside)
    settling = 0.0 if not len(bad) else (np.inf if bad[-1] == len(time) - 1 else time[bad[-1] + 1] - time[0])
    first = np.inf if not len(good) else time[good[0]] - time[0]
    overshoot = 0.0 if reference == 0 else max(0.0, 100 * (np.max(np.sign(reference) * speed) - abs(reference)) / abs(reference))
    tail = time >= time[-1] - min(0.5, 0.1 * (time[-1] - time[0]))
    return {"ts": float(settling), "t_first": float(first), "os": float(overshoot),
            "ess": float(abs(reference - np.mean(speed[tail]))),
            "ess_validated": bool(np.ptp(speed[tail]) <= 1e-3 * max(abs(reference), 1)),
            "iae": float(np.trapezoid(np.abs(error), time)),
            "effort": float(np.trapezoid(np.abs(voltage), time)),
            "effort2": float(np.trapezoid(voltage**2, time))}
