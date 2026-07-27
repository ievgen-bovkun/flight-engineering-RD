function tests = test_pendulum_symbolic_model
%TEST_PENDULUM_SYMBOLIC_MODEL Verify the CTMS equations produce A and B.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testLinearizationMatchesNumericModel(testCase)
assumeTrue(testCase, exist('syms', 'file') == 2, ...
    'Symbolic Math Toolbox is not installed in this MATLAB environment.');
model = derive_pendulum_model();
P = pendulum_params();

values = [P.M, P.m, P.b, P.I, P.l, P.g];
variables = [model.symbols.M, model.symbols.m, model.symbols.b, ...
    model.symbols.I, model.symbols.l, model.symbols.g];

verifyEqual(testCase, double(subs(model.A, variables, values)), P.A, 'AbsTol', 1e-12);
verifyEqual(testCase, double(subs(model.B, variables, values)), P.B, 'AbsTol', 1e-12);
end
