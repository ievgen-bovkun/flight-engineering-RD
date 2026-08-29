function tests = test_dz4_simulation
tests = functiontests(localfunctions);
end

function testSimulinkMatchesLsimForVariantOne(testCase)
result = dz4_run(1);

verifyEqual(testCase, result.cfg.variant_id, 1);
verifyEqual(testCase, result.time(1), 0, 'AbsTol', 0);
verifyEqual(testCase, result.time(end), result.cfg.stop_time_s, 'AbsTol', 1e-12);
verifySize(testCase, result.matlab_states, [numel(result.time) 5]);
verifySize(testCase, result.simulink_states, [numel(result.time) 5]);
verifyLessThan(testCase, result.max_abs_error, 1e-5);
verifyLessThan(testCase, result.rms_error_global, 1e-6);
verifySize(testCase, result.rms_error_per_state, [1 5]);
verifyLessThan(testCase, result.input_step_rad, 0);
verifyTrue(testCase, isfile(result.results_mat_path));
verifyTrue(testCase, isfile(result.summary_csv_path));
end

function testNormalAircraftHasAVisibleAltitudeDip(testCase)
result = dz4_run(1);

verifyLessThan(testCase, result.altitude_dip_m, 0);
verifyGreaterThan(testCase, result.altitude_dip_time_s, result.cfg.step_time_s);
verifyGreaterThan(testCase, result.short_period.natural_frequency_rad_s, 0);
verifyGreaterThan(testCase, result.slow_real_mode.time_constant_s, 100);
verifyLessThan(testCase, abs(result.neutral_mode_eigenvalue), 1e-10);
verifyEqual(testCase, numel(result.full_eigenvalues), 5);
end
