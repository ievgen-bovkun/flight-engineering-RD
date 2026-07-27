function tests = test_pendulum_impulse_response
%TEST_PENDULUM_IMPULSE_RESPONSE Verify the Control Toolbox impulse response.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testImpulseMatchesAnalyticalStateTransition(testCase)
P = pendulum_params();
response = pendulum_impulse_response(P, 1, 0.01);

verifySize(testCase, response.output, [numel(response.time), 2]);
verifyLessThan(testCase, response.maxErrorVsAnalytic, 1e-8);
end
