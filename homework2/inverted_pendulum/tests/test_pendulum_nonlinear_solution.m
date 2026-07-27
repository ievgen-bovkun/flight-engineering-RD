function tests = test_pendulum_nonlinear_solution
%TEST_PENDULUM_NONLINEAR_SOLUTION Verify the full nonlinear CTMS equations.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testInitialStateAndDimensions(testCase)
P = pendulum_params();
time = (0:0.01:0.2).';
initialState = [0; 0; 0.05; 0];
response = pendulum_nonlinear_solution(P, time, initialState);

verifySize(testCase, response.state, [numel(time), 4]);
verifyEqual(testCase, response.state(1, :).', initialState, 'AbsTol', 1e-12);
end

function testSmallAngleAgreesWithLinearModelInitially(testCase)
P = pendulum_params();
time = (0:0.002:0.2).';
initialState = [0; 0; 0.01; 0];
nonlinear = pendulum_nonlinear_solution(P, time, initialState);
linear = pendulum_analytic_solution(time, zeros(size(time)), initialState);

verifyLessThan(testCase, max(abs(nonlinear.state - linear.state), [], 'all'), 1e-4);
end
