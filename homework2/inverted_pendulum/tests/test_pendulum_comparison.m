function tests = test_pendulum_comparison
%TEST_PENDULUM_COMPARISON Verify agreement among all Task 1 methods.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testAnalyticalMatlabAndSimulinkAgree(testCase)
result = run_pendulum_comparison(false);

verifyLessThan(testCase, result.maxError.analyticVsLsim, 1e-3);
verifyLessThan(testCase, result.maxError.analyticVsSimulink, 1e-3);
verifyEqual(testCase, size(result.analytic.output, 2), 2);
end
