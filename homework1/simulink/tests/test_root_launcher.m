function tests = test_root_launcher
%TEST_ROOT_LAUNCHER Checks the beginner-friendly root entry point.
tests = functiontests(localfunctions);
end

function testRootLauncherRunsVerticalTest(testCase)
rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);

out = run_simulink_demo(false);

verifyLessThan(testCase, out.position.Data(end,3), -10);
end

function testBuilderReusesAnAlreadyLoadedRootModel(testCase)
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);

modelName = build_quadrotor_simulink(false, true);
verifyTrue(testCase, bdIsLoaded(modelName));

modelFile = fullfile(rootDir, modelName + ".slx");
backupFile = [tempname, '.slx'];
cleanup = onCleanup(@() cleanup_files(modelName, backupFile));
copyfile(modelFile, backupFile);
copyfile(backupFile, modelFile, 'f');

verifyWarningFree(testCase, @() build_quadrotor_simulink(false));
end

function cleanup_files(modelName, backupFile)
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if isfile(backupFile)
    delete(backupFile);
end
end
