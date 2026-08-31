function tests = test_task1_artifacts
tests = functiontests(localfunctions);
end

function testStudyProducesRequiredEvidence(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'), fullfile(root, 'scripts'));
summary = run_task1_integrator_study();
verifyEqual(testCase, unique(summary.frequency_hz), [10;100;1000;10000]);
verifyTrue(testCase, all(summary.max_abs_error >= 0));
required = {'task1_metrics.csv','task1_results.mat','rk4_error_vs_step.png', ...
    'rkf45_step_history.png','method_overlay_10000hz.png'};
verifyTrue(testCase, all(isfile(fullfile(root, 'results', required))));
end
