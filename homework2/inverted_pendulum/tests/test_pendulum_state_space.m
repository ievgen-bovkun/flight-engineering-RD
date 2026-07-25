function tests = test_pendulum_state_space
%TEST_PENDULUM_STATE_SPACE Verify the CTMS linear pendulum reference model.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testZeroInputKeepsUprightEquilibrium(testCase)
[sys, P] = pendulum_state_space();
t = linspace(0, 1, 11).';
y = lsim(sys, zeros(size(t)), t, zeros(4, 1));

verifyEqual(testCase, y, zeros(numel(t), 2), 'AbsTol', 1e-12);
verifySize(testCase, P.A, [4 4]);
verifySize(testCase, P.B, [4 1]);
verifySize(testCase, P.C, [2 4]);
end

function testCtmsMatrixCoefficients(testCase)
[~, P] = pendulum_state_space();

verifyEqual(testCase, P.M, 0.5, 'AbsTol', 1e-12);
verifyEqual(testCase, P.m, 0.2, 'AbsTol', 1e-12);
verifyEqual(testCase, P.A(2, 3), -(P.m^2 * P.g * P.l^2) / P.p, 'AbsTol', 1e-12);
verifyEqual(testCase, P.A(4, 3), P.m * P.g * P.l * (P.M + P.m) / P.p, 'AbsTol', 1e-12);
end
