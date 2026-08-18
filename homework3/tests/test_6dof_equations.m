function tests = test_6dof_equations
%TEST_6DOF_EQUATIONS Independent checks for the NED rigid-body equations.
tests = functiontests(localfunctions);
end

function testTranslationalDynamicsSubtractsTransportTerm(testCase)
cfg = fixtureConfig();
x = [3; 4; 5; 0.2; -0.3; 0.4; 0; 0; 0; 0; 0; 0];
input = [6; 8; 10; 1; 2; 3];

out = reference_6dof_rhs(x, input, cfg);

verifyEqual(testCase, out.Ab, [6.1; 3.8; 3.3], 'AbsTol', 1e-12);
end

function testRotationalDynamicsUsesEulerEquationForDiagonalInertia(testCase)
cfg = fixtureConfig();
x = [0; 0; 0; 0.2; -0.3; 0.4; 0; 0; 0; 0; 0; 0];
input = [0; 0; 0; 1; 2; 3];

out = reference_6dof_rhs(x, input, cfg);

verifyEqual(testCase, out.pqr_dot, [0.62; 0.7466666666666667; 0.612], 'AbsTol', 1e-12);
end

function testIdentityAttitudePreservesBodyVelocityInNED(testCase)
cfg = fixtureConfig();
x = [1; -2; 3; 0; 0; 0; 0; 0; 0; 0; 0; 0];
input = zeros(6, 1);

out = reference_6dof_rhs(x, input, cfg);

verifyEqual(testCase, out.DCMbe, eye(3), 'AbsTol', 1e-12);
verifyEqual(testCase, out.Ve, [1; -2; 3], 'AbsTol', 1e-12);
end

function testYawNinetyDegreesMapsBodyForwardToEast(testCase)
cfg = fixtureConfig();
x = [1; 0; 0; 0; 0; 0; 0; 0; pi/2; 0; 0; 0];
input = zeros(6, 1);

out = reference_6dof_rhs(x, input, cfg);

verifyEqual(testCase, out.Ve, [0; 1; 0], 'AbsTol', 1e-12);
verifyEqual(testCase, det(out.DCMbe), 1, 'AbsTol', 1e-12);
verifyEqual(testCase, out.DCMbe * out.DCMbe.', eye(3), 'AbsTol', 1e-12);
end

function testEulerRatesEqualBodyRatesAtZeroAttitude(testCase)
cfg = fixtureConfig();
x = [0; 0; 0; 0.2; -0.3; 0.4; 0; 0; 0; 0; 0; 0];
input = zeros(6, 1);

out = reference_6dof_rhs(x, input, cfg);

verifyEqual(testCase, out.euler_dot, [0.2; -0.3; 0.4], 'AbsTol', 1e-12);
end

function cfg = fixtureConfig()
cfg = struct('mass', 2, 'inertia', diag([2, 3, 5]));
end
