function tests = test_symbolic_pendulum
%TEST_SYMBOLIC_PENDULUM Verify the Task 3 symbolic derivation output.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testSymbolicAndCtmsMatricesAgree(testCase)
assumeTrue(testCase, exist('syms', 'file') == 2, ...
    'Symbolic Math Toolbox is not installed in this MATLAB environment.');
result = run_symbolic_pendulum(false);

verifyLessThan(testCase, result.maxDifferenceA, 1e-12);
verifyLessThan(testCase, result.maxDifferenceB, 1e-12);
verifySize(testCase, result.numericA, [4 4]);
verifySize(testCase, result.numericB, [4 1]);
end
