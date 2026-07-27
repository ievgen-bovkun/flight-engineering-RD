function tests = test_pendulum_analytic_solution
%TEST_PENDULUM_ANALYTIC_SOLUTION Verify the exact state-transition solution.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testZeroInputPreservesZeroEquilibrium(testCase)
time = (0:0.1:1).';
response = pendulum_analytic_solution(time, zeros(size(time)), zeros(4, 1));

verifyEqual(testCase, response.state, zeros(numel(time), 4), 'AbsTol', 1e-12);
verifyEqual(testCase, response.output, zeros(numel(time), 2), 'AbsTol', 1e-12);
end

function testInitialStateMatchesHomogeneousSolution(testCase)
P = pendulum_params();
time = [0; 0.2];
initialState = [0.1; -0.2; 0.01; 0.3];
response = pendulum_analytic_solution(time, [0; 0], initialState);

verifyEqual(testCase, response.state(2, :).', expm(P.A * 0.2) * initialState, ...
    'AbsTol', 1e-12);
end
