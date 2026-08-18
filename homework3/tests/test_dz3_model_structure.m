function tests = test_dz3_model_structure
% Structural acceptance test: both independently implemented branches exist.
tests = functiontests(localfunctions);
end

function testModelHasIndependentCustomAndAerospaceBranches(testCase)
model = build_dz3_6dof_model();
load_system(model);
cleanup = onCleanup(@() close_system(model, 0)); %#ok<NASGU>

verifyTrue(testCase, isfile(which([model '.slx'])));
verifyNotEmpty(testCase, find_system(model, 'SearchDepth', 1, 'Name', 'Custom 6DOF NED'));
verifyEqual(testCase, get_param([model '/Aerospace 6DOF'], 'ReferenceBlock'), ...
    'aerolibprivatev1p5/6DoF (Euler Angles)');
verifyNotEmpty(testCase, find_system([model '/Custom 6DOF NED'], ...
    'SearchDepth', 1, 'BlockType', 'Integrator'));
end

function testModelCreatesSafeInputsForDirectRun(testCase)
model = build_dz3_6dof_model();
load_system(model);
cleanupModel = onCleanup(@() close_system(model, 0)); %#ok<NASGU>
cleanupWorkspace = onCleanup(@() evalin('base', 'clear forces_ts moments_ts')); %#ok<NASGU>

evalin('base', 'clear forces_ts moments_ts');
sim(model, 'StopTime', '0.01', 'ReturnWorkspaceOutputs', 'on');

verifyEqual(testCase, evalin('base', "exist('forces_ts','var')"), 1);
verifyEqual(testCase, evalin('base', "exist('moments_ts','var')"), 1);
verifyEqual(testCase, size(evalin('base', 'forces_ts.Data'), 2), 3);
verifyEqual(testCase, size(evalin('base', 'moments_ts.Data'), 2), 3);
end
