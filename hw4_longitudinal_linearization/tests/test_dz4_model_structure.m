function tests = test_dz4_model_structure
tests = functiontests(localfunctions);
end

function testBuilderCreatesNamedStateSpaceModel(testCase)
cfg = dz4_variant_data(1);
[modelData, ~] = dz4_build_state_space(cfg);
modelName = dz4_build_simulink_model(cfg, modelData);

rootDir = fileparts(fileparts(mfilename('fullpath')));
modelPath = fullfile(rootDir, 'models', [modelName '.slx']);
verifyEqual(testCase, modelName, 'dz4_longitudinal_ss');
verifyTrue(testCase, isfile(modelPath));

load_system(modelPath);
cleanup = onCleanup(@() close_system(modelName, 0)); %#ok<NASGU>
verifyNotEmpty(testCase, find_system(modelName, 'SearchDepth', 1, ...
    'Name', 'Step delta_1'));
verifyNotEmpty(testCase, find_system(modelName, 'SearchDepth', 1, ...
    'BlockType', 'StateSpace'));
verifyNotEmpty(testCase, find_system(modelName, 'SearchDepth', 1, ...
    'Name', 'States'));
end
