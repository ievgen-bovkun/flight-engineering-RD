from dc_motor.run_comparison import compare_all


def test_actual_matlab_and_independent_python_match():
    results = compare_all(write_outputs=False)
    assert len(results) >= 6
    for row in results:
        assert row["max_speed_error"] <= 1e-3, row
        assert row["max_current_error"] <= 1e-4, row
        assert row["max_voltage_error"] <= 1e-2, row
        assert row["settling_difference_s"] <= 0.002, row
