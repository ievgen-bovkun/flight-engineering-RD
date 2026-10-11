"""Compare computed SciPy trajectories against actual MATLAB CSV evidence."""
import csv
import json
import hashlib
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

from .model import PROJECT_ROOT, load_config, simulate_plant
from .controller import simulate
from .metrics import performance_metrics


def validated_gains(result_path=None):
    path = Path(result_path or PROJECT_ROOT / "results/json/optimization.json")
    record = json.loads(path.read_text(encoding="utf-8-sig"))
    provenance = record.get("provenance", {})
    for filename, key in [("parameters.json", "parametersSHA256"), ("scenarios.json", "scenariosSHA256")]:
        checksum = hashlib.sha256((PROJECT_ROOT / "config" / filename).read_bytes()).hexdigest()
        if provenance.get(key) != checksum:
            raise ValueError("Optimization does not match current configuration")
    sources = provenance.get("sources", [])
    required = {"pid_cost.m", "pid_settings.m", "pid_output.m", "simulate_closed_loop.m",
                "performance_metrics.m", "motor_params.m", "motor_models.m", "optimize_pid.m", "ga_simple.m"}
    if not required.issubset({source["name"] for source in sources}):
        raise ValueError("Required source provenance is missing")
    for source in sources:
        filename = PROJECT_ROOT / "matlab/src" / source["name"]
        if hashlib.sha256(filename.read_bytes()).hexdigest() != source["sha256"]:
            raise ValueError(f"Optimization source changed: {source['name']}")
    if not record.get("feasible"):
        raise ValueError("Selected gains were not validated as feasible")
    return record["K"]


def compare_all(write_outputs=True):
    config = load_config()
    scenarios = json.loads((PROJECT_ROOT / "config/scenarios.json").read_text(encoding="utf-8-sig"))["scenarios"]
    gains = validated_gains()
    results = []
    nominal_pair = None
    for scenario in scenarios:
        identifier = scenario["id"]
        if scenario["kind"] == "plant":
            filename = identifier + ".csv"
            output = simulate_plant(config, scenario)
            speed_column, current_column = "omega_reference", "current_reference"
        elif identifier in ("pid_nominal", "pid_required_load"):
            filename = "pid_optimized.csv" if identifier == "pid_nominal" else "disturbance_1_PID.csv"
            output = simulate(config, scenario, gains)
            speed_column, current_column = "omega_rad_s", "current_A"
        else:
            continue
        reference = np.genfromtxt(PROJECT_ROOT / "results/csv" / filename, delimiter=",", names=True)
        np.testing.assert_allclose(output["time"], reference["time_s"], atol=1e-12)
        speed_error = np.max(np.abs(output["omega"] - reference[speed_column]))
        current_error = np.max(np.abs(output["current"] - reference[current_column]))
        voltage_error, settling_difference = 0.0, 0.0
        if scenario["kind"] == "closed_loop":
            voltage_error = np.max(np.abs(output["voltage"] - reference["voltage_V"]))
            matlab_output = {"time": reference["time_s"], "omega": reference[speed_column],
                             "current": reference[current_column], "voltage": reference["voltage_V"], "reference": 100}
            settling_difference = abs(performance_metrics(output)["ts"] - performance_metrics(matlab_output)["ts"])
            if identifier == "pid_nominal":
                nominal_pair = output, reference
        row = {"scenario": identifier, "max_speed_error": float(speed_error), "max_current_error": float(current_error),
               "max_voltage_error": float(voltage_error), "settling_difference_s": float(settling_difference)}
        if speed_error > 1e-3 or current_error > 1e-4 or voltage_error > 1e-2 or settling_difference > 0.002:
            raise AssertionError(f"Cross-language numerical acceptance failed: {row}")
        results.append(row)
        if write_outputs:
            data = np.column_stack([output[k] for k in ("time", "omega", "current", "voltage")])
            np.savetxt(PROJECT_ROOT / "results/csv" / f"python_{identifier}.csv", data, delimiter=",",
                       header="time_s,omega_rad_s,current_A,voltage_V", comments="")
    if write_outputs:
        with (PROJECT_ROOT / "results/csv/python_matlab_comparison.csv").open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(results[0]))
            writer.writeheader()
            writer.writerows(results)
        (PROJECT_ROOT / "results/json/python_comparison.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
        output, reference = nominal_pair
        fig, axes = plt.subplots(2, 1, figsize=(10, 7), constrained_layout=True)
        for ax, field, column, label in [(axes[0], "omega", "omega_rad_s", "Швидкість, рад/с"),
                                         (axes[1], "voltage", "voltage_V", "Напруга, В")]:
            ax.plot(output["time"], output[field], label="Python: незалежні рівняння", linewidth=1.5)
            ax.plot(reference["time_s"], reference[column], "--", label="MATLAB: прямі рівняння", linewidth=1.5)
            ax.set(xlabel="Час, с", ylabel=label)
            ax.grid(True)
            ax.legend()
        fig.savefig(PROJECT_ROOT / "results/figures/python_matlab_comparison.png", dpi=180)
        plt.close(fig)
    return results


if __name__ == "__main__":
    print(json.dumps(compare_all(), indent=2))
