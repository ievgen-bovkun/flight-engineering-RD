function tests = test_simulink_model
%TEST_SIMULINK_MODEL End-to-end checks for the generated Simulink model.
tests = functiontests(localfunctions);
end

function testVerticalChannelRisesWithoutRotation(testCase)
out = run_simulink_channel('vertical', false);
position = out.position;
angles = out.angles;

verifyLessThan(testCase, position.Data(end,3), -10);
verifyLessThan(testCase, max(abs(position.Data(:,1))), 1e-10);
verifyLessThan(testCase, max(abs(position.Data(:,2))), 1e-10);
verifyLessThan(testCase, max(abs(angles.Data), [], 'all'), 1e-8);
verifyEqual(testCase, position.Time(end), 4, 'AbsTol', 1e-12);
end

function testRollChannelChangesRollAngle(testCase)
out = run_simulink_channel('roll', false);
angles = out.angles.Data;

verifyGreaterThan(testCase, max(abs(angles(:,1))), 1e-3);
end

function testPitchChannelChangesPitchAngle(testCase)
out = run_simulink_channel('pitch', false);
angles = out.angles.Data;

verifyGreaterThan(testCase, max(abs(angles(:,2))), 1e-3);
end

function testYawChannelChangesYawAngle(testCase)
out = run_simulink_channel('yaw', false);
angles = out.angles.Data;

verifyGreaterThan(testCase, max(abs(angles(:,3))), 1e-4);
end
