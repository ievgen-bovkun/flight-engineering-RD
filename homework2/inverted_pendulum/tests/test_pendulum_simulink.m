function tests = test_pendulum_simulink
%TEST_PENDULUM_SIMULINK Verify the minimal Simulink implementation.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testBuildCreatesRequiredBlocks(testCase)
modelName = build_pendulum_simulink(true);
cleaner = onCleanup(@() close_system(modelName, 0));

verifyEqual(testCase, modelName, 'inverted_pendulum_linear');
verifyTrue(testCase, bdIsLoaded(modelName));
verifyNotEmpty(testCase, find_system(modelName, 'Name', 'Unit force step'));
verifyNotEmpty(testCase, find_system(modelName, 'Name', 'Linearized pendulum'));
verifyNotEmpty(testCase, find_system(modelName, 'Name', 'Response scope'));
verifyNotEmpty(testCase, find_system(modelName, 'Name', 'Simulation output'));
end

function testStarterLoadsParametersBeforeSimulation(testCase)
modelName = build_pendulum_simulink(true);
close_system(modelName, 0);
evalin('base', 'clear P');

run_pendulum_simulink();
cleaner = onCleanup(@() close_system(modelName, 0));
output = evalin('base', 'pendulum_simulink_output');

verifyGreaterThan(testCase, numel(output.time), 10);
end
