function tests = test_dz4_coefficients
tests = functiontests(localfunctions);
end

function testVariantOneConvertsUnitsAndUsesNormalControlSign(testCase)
cfg = dz4_variant_data(1);

verifyEqual(testCase, cfg.variant_id, 1);
verifyEqual(testCase, cfg.aircraft_type, "normal");
verifyEqual(testCase, cfg.m, 44, 'AbsTol', 1e-12);
verifyEqual(testCase, cfg.theta_rad, -9*pi/180, 'AbsTol', 1e-12);
verifyEqual(testCase, cfg.cy_alpha, 0.273*180/pi, 'RelTol', 1e-12);
verifyEqual(testCase, cfg.delta_step_rad, -4*pi/180, 'AbsTol', 1e-12);
end

function testCanardUsesPositiveControlSign(testCase)
cfg = dz4_variant_data(5);

verifyEqual(testCase, cfg.aircraft_type, "canard");
verifyEqual(testCase, cfg.delta_step_rad, 20*pi/180, 'AbsTol', 1e-12);
end

function testVariantOutsideTableIsRejected(testCase)
verifyError(testCase, @() dz4_variant_data(7), 'DZ4:VariantOutOfRange');
end

function testStateSpaceMatchesMethodicalMatrixLayout(testCase)
cfg = dz4_variant_data(1);
[sys, q] = dz4_build_state_space(cfg);

expectedA = [q.Q1_theta q.Q1_alpha 0 0 0;
             q.Q2_theta q.Q2_alpha 0 q.Q2_omega 0;
             0 0 0 q.Q3_omega 0;
             0 q.Q4_alpha 0 q.Q4_omega 0;
             q.Q5_theta 0 0 0 0];
expectedB = [q.Q1_delta; q.Q2_delta; 0; q.Q4_delta; 0];

verifyEqual(testCase, q.Q2_theta, -q.Q1_theta, 'AbsTol', 1e-12);
verifyEqual(testCase, q.Q2_alpha, -q.Q1_alpha, 'AbsTol', 1e-12);
verifyEqual(testCase, q.Q2_delta, -q.Q1_delta, 'AbsTol', 1e-12);
verifyEqual(testCase, q.Q2_omega, 1, 'AbsTol', 0);
verifyEqual(testCase, q.Q3_omega, 1, 'AbsTol', 0);
verifyEqual(testCase, sys.A, expectedA, 'AbsTol', 1e-12);
verifyEqual(testCase, sys.B, expectedB, 'AbsTol', 1e-12);
verifyEqual(testCase, sys.C, eye(5), 'AbsTol', 0);
verifyEqual(testCase, sys.D, zeros(5,1), 'AbsTol', 0);
end
