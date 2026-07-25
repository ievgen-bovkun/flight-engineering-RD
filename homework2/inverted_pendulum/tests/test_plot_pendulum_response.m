function tests = test_plot_pendulum_response
%TEST_PLOT_PENDULUM_RESPONSE Verify the learner-facing response figure.
addpath(fileparts(fileparts(mfilename('fullpath'))));
tests = functiontests(localfunctions);
end

function testCreatesCartAndAnglePlots(testCase)
output.time = (0:0.1:1).';
output.signals.values = [output.time, 0.2 * output.time];

fig = plot_pendulum_response(output, false);
cleaner = onCleanup(@() close(fig));
axesHandles = findall(fig, 'Type', 'axes');

verifyEqual(testCase, numel(axesHandles), 2);
end
