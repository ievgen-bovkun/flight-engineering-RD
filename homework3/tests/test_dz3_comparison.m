function tests = test_dz3_comparison
tests = functiontests(localfunctions);
end

function testCustomBranchMatchesAerospaceForAllCanonicalDOFTests(testCase)
result = run_dz3_comparison();
verifyLessThanOrEqual(testCase, max(result.summary.max_state_error), 1e-6);
end

function testConstantForceAgreesWithLaplaceDoubleIntegrator(testCase)
result = run_dz3_comparison();
verifyLessThanOrEqual(testCase, result.laplace.max_position_error_m, 1e-6);
end

function testHomeworkOneOverlayFiguresAreGenerated(testCase)
run_dz3_comparison();
rootDir = fileparts(fileparts(mfilename('fullpath')));
expectedFiles = fullfile(rootDir, 'results', { ...
    'vertical_overlay.png', 'roll_overlay.png', ...
    'pitch_overlay.png', 'yaw_overlay.png'});
verifyTrue(testCase, all(isfile(expectedFiles)), ...
    'Expected vertical, roll, pitch and yaw overlay figures.');
end
