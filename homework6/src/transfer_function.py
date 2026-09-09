"""Transfer-function analysis required in Homework 6."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import control as ct
import matplotlib.pyplot as plt
import numpy as np


@dataclass(frozen=True)
class TransferFunctionAnalysis:
    system: ct.TransferFunction
    time: np.ndarray
    response: np.ndarray
    y_final: float
    y_peak: float
    t_peak: float
    t_settle_2pct: float | None
    poles: np.ndarray
    zeros: np.ndarray
    is_asymptotically_stable: bool


def _settling_time(time: np.ndarray, response: np.ndarray, final_value: float, tolerance: float) -> float | None:
    """Return the first sample after the final 2%-band excursion.

    ``None`` means that the selected simulation horizon is too short to
    demonstrate settling; this avoids the misleading value 0 s.
    """
    if not np.isfinite(final_value):
        return None
    band = tolerance * max(abs(final_value), np.finfo(float).eps)
    outside = np.flatnonzero(np.abs(response - final_value) > band)
    if outside.size == 0:
        return float(time[0])
    final_outside_index = int(outside[-1])
    if final_outside_index == len(time) - 1:
        return None
    return float(time[final_outside_index + 1])


def analyze_transfer_function(
    numerator: list[float],
    denominator: list[float],
    *,
    time_end: float = 5.0,
    samples: int = 5001,
    settling_tolerance: float = 0.02,
) -> TransferFunctionAnalysis:
    """Create and analyse a continuous-time SISO transfer function."""
    if time_end <= 0 or samples < 2:
        raise ValueError("time_end must be positive and samples must be at least 2")
    system = ct.tf(numerator, denominator)
    time = np.linspace(0.0, time_end, samples)
    response_data = ct.step_response(system, time)
    response = np.asarray(response_data.outputs, dtype=float).reshape(-1)
    final_value = float(ct.dcgain(system))
    peak_index = int(np.argmax(response))
    poles = np.asarray(ct.poles(system), dtype=complex)
    zeros = np.asarray(ct.zeros(system), dtype=complex)
    return TransferFunctionAnalysis(
        system=system,
        time=time,
        response=response,
        y_final=final_value,
        y_peak=float(response[peak_index]),
        t_peak=float(time[peak_index]),
        t_settle_2pct=_settling_time(time, response, final_value, settling_tolerance),
        poles=poles,
        zeros=zeros,
        is_asymptotically_stable=bool(np.all(poles.real < 0.0)),
    )


def save_transfer_plots(analysis: TransferFunctionAnalysis, output_path: Path) -> None:
    """Save the step response and pole map as one report-ready figure."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig, (ax_response, ax_poles) = plt.subplots(1, 2, figsize=(13, 5))
    tol = 0.02
    ax_response.plot(analysis.time, analysis.response, lw=2.2, label="step response")
    ax_response.axhline(analysis.y_final, color="0.35", ls="--", label=f"steady state = {analysis.y_final:.3f}")
    ax_response.axhspan(analysis.y_final * (1 - tol), analysis.y_final * (1 + tol), color="0.4", alpha=0.13, label="2% band")
    ax_response.plot(analysis.t_peak, analysis.y_peak, "o", color="#d62728", label=f"peak = {analysis.y_peak:.3f}")
    if analysis.t_settle_2pct is not None:
        ax_response.axvline(analysis.t_settle_2pct, color="#2ca02c", ls=":", lw=2, label=f"settling = {analysis.t_settle_2pct:.2f} s")
    ax_response.set(title="Step response", xlabel="time, s", ylabel="output y(t)")
    ax_response.grid(alpha=0.3)
    ax_response.legend(fontsize=8)

    lim = max(1.0, *(np.abs(analysis.poles.real) + 0.5), *(np.abs(analysis.poles.imag) + 0.5))
    ax_poles.axhline(0, color="0.2", lw=0.8)
    ax_poles.axvline(0, color="0.2", lw=0.8)
    ax_poles.axvspan(-lim, 0, color="#2ca02c", alpha=0.08)
    ax_poles.axvspan(0, lim, color="#d62728", alpha=0.08)
    ax_poles.scatter(analysis.poles.real, analysis.poles.imag, marker="x", s=160, linewidths=3, color="#d62728", label="poles")
    if analysis.zeros.size:
        ax_poles.scatter(analysis.zeros.real, analysis.zeros.imag, facecolors="none", edgecolors="#1f77b4", s=100, linewidths=2, label="zeros")
    ax_poles.set(xlim=(-lim, lim), ylim=(-lim, lim), title="Pole map", xlabel="Re(s), 1/s", ylabel="Im(s), rad/s")
    ax_poles.grid(alpha=0.3)
    ax_poles.legend()
    fig.tight_layout()
    fig.savefig(output_path, dpi=180, bbox_inches="tight")
    plt.close(fig)
