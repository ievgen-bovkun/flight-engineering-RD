function tests = test_task2_artifacts
tests = functiontests(localfunctions);
end

function testStudyProducesMethodAndClockEvidence(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'), fullfile(root, 'scripts'));
result = run_task2_discretization_study();
verifyEqual(testCase, unique(result.nominal.frequency_hz), [10;100;1000]);
verifyEqual(testCase, unique(result.nominal.method), ["custom_zoh";"foh";"tustin";"zoh"]);
verifyEqual(testCase, height(result.clock), 9);
verifyLessThan(testCase, max(result.nominal.zoh_match_error(result.nominal.method=="custom_zoh")), 1e-11);
required = {'task2_nominal_metrics.csv','task2_clock_deviation_metrics.csv', ...
    'task2_results.mat','method_comparison.png','clock_deviation.png'};
verifyTrue(testCase, all(isfile(fullfile(root, 'results', required))));
end
