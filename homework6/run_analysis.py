"""Generate reproducible Homework 6 numerical artefacts."""

from __future__ import annotations

import json
from pathlib import Path

from homework6.src.inverted_pendulum import run_experiments
from homework6.src.transfer_function import analyze_transfer_function, save_transfer_plots


PROJECT = Path(__file__).resolve().parent
RESULTS = PROJECT / "results"


def main() -> None:
    RESULTS.mkdir(exist_ok=True)
    transfer = analyze_transfer_function([10], [1, 3, 10], time_end=5.0, samples=5001)
    save_transfer_plots(transfer, RESULTS / "part1_transfer_function.png")
    pendulum_metrics = run_experiments(RESULTS / "part2_inverted_pendulum.png")
    summary = {
        "transfer_function": {
            "numerator": [10],
            "denominator": [1, 3, 10],
            "steady_state": transfer.y_final,
            "peak": transfer.y_peak,
            "peak_time_s": transfer.t_peak,
            "settling_time_2pct_s": transfer.t_settle_2pct,
            "poles": [[pole.real, pole.imag] for pole in transfer.poles],
            "stable": transfer.is_asymptotically_stable,
        },
        "pendulum": pendulum_metrics,
    }
    with (RESULTS / "summary.json").open("w", encoding="utf-8") as stream:
        json.dump(summary, stream, ensure_ascii=False, indent=2)
    print("Transfer function:", transfer.system)
    print(f"Peak: {transfer.y_peak:.4f} at {transfer.t_peak:.4f} s")
    print(f"2% settling time: {transfer.t_settle_2pct:.4f} s")
    print("Poles:", transfer.poles)
    print("Asymptotically stable:", transfer.is_asymptotically_stable)
    for key, value in pendulum_metrics.items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
