function tests = test_quadrotor_core
%TEST_QUADROTOR_CORE Behaviour checks for the Simulink model core.
tests = functiontests(localfunctions);
end

function testHoverIsAnEquilibrium(testCase)
P = quadrotor_params();
x0 = quadrotor_initial_state(P);
dx = quadrotor_core(zeros(4,1), x0, P);

verifyLessThan(testCase, max(abs(dx)), 1e-9);
end

function testChannelMixers(testCase)
verifyEqual(testCase, quadrotor_test_mix('vertical'), [1; 1; 1; 1]);
verifyEqual(testCase, quadrotor_test_mix('roll'),     [0; 1; 0; -1]);
verifyEqual(testCase, quadrotor_test_mix('pitch'),    [1; 0; -1; 0]);
verifyEqual(testCase, quadrotor_test_mix('yaw'),      [-1; 1; -1; 1]);
end

function testVerticalStepChangesOnlyMotorAccelerationInitially(testCase)
P = quadrotor_params();
x0 = quadrotor_initial_state(P);
dx = quadrotor_core(quadrotor_test_mix('vertical'), x0, P);

verifyGreaterThan(testCase, min(dx(13:16)), 0);
verifyEqual(testCase, dx(10:12), zeros(3,1), 'AbsTol', 1e-12);
end
