function model = build_dz3_6dof_model()
%BUILD_DZ3_6DOF_MODEL Build custom-NED versus Aerospace 6DOF comparison.
% The two branches accept the same total body-axis forces and moments.

rootDir = fileparts(fileparts(mfilename('fullpath')));
modelsDir = fullfile(rootDir, 'models');
if ~isfolder(modelsDir)
    mkdir(modelsDir);
end
addpath(modelsDir);
addpath(fullfile(matlabroot, 'toolbox', 'aeroblks', 'aeroblks'));
load_system('aerolib6dof');

model = 'dz3_6dof_ned_compare';
modelFile = fullfile(modelsDir, [model '.slx']);
if bdIsLoaded(model)
    close_system(model, 0);
end
new_system(model);
set_param(model, 'Solver', 'ode4', 'FixedStep', '0.001', 'StopTime', '4');
initCallback = [ ...
    "dz3ProjectRoot = fileparts(fileparts(get_param(bdroot,'FileName'))); " ...
    "addpath(fullfile(dz3ProjectRoot,'scripts')); " ...
    "dz3_init_default_inputs(bdroot);"];
set_param(model, 'InitFcn', char(initCallback));

add_block('simulink/Sources/From Workspace', [model '/Forces body'], ...
    'VariableName', 'forces_ts', 'Position', [30 95 125 125]);
add_block('simulink/Sources/From Workspace', [model '/Moments body'], ...
    'VariableName', 'moments_ts', 'Position', [30 205 125 235]);

add_custom_branch(model);
add_block('aerolib6dof/6DoF (Euler Angles)', [model '/Aerospace 6DOF'], ...
    'Position', [420 380 590 560], ...
    'xme_0', '[0;0;-10]', 'Vm_0', '[0;0;0]', ...
    'eul_0', '[0;0;0]', 'pm_0', '[0;0;0]', ...
    'Mass', '1.3211359852721711', 'Inertia', 'diag([0.0093 0.0092 0.0151])');

add_line(model, 'Forces body/1', 'Custom 6DOF NED/1', 'autorouting', 'on');
add_line(model, 'Moments body/1', 'Custom 6DOF NED/2', 'autorouting', 'on');
add_line(model, 'Forces body/1', 'Aerospace 6DOF/1', 'autorouting', 'on');
add_line(model, 'Moments body/1', 'Aerospace 6DOF/2', 'autorouting', 'on');

names = {'Ve','Xe','Euler','DCM','Vb','pqr','pqr_dot'};
for k = 1:numel(names)
    add_logger(model, ['custom_' names{k}], [740 40+55*(k-1) 845 65+55*(k-1)]);
    add_logger(model, ['aero_' names{k}], [740 450+55*(k-1) 845 475+55*(k-1)]);
    add_line(model, ['Custom 6DOF NED/' num2str(k)], ['custom_' names{k} '/1'], 'autorouting', 'on');
    add_line(model, ['Aerospace 6DOF/' num2str(k)], ['aero_' names{k} '/1'], 'autorouting', 'on');
end
add_logger(model, 'custom_Ab', [740 430 845 455]);
add_line(model, 'Custom 6DOF NED/8', 'custom_Ab/1', 'autorouting', 'on');

save_system(model, modelFile);
end

function add_custom_branch(model)
path = [model '/Custom 6DOF NED'];
add_block('simulink/Ports & Subsystems/Subsystem', path, ...
    'Position', [380 75 600 300]);
delete_block([path '/In1']);
delete_block([path '/Out1']);

add_block('simulink/Sources/In1', [path '/Forces'], 'Position', [25 55 55 75]);
add_block('simulink/Sources/In1', [path '/Moments'], 'Position', [25 105 55 125]);
add_block('simulink/User-Defined Functions/MATLAB Function', [path '/Rigid body NED equations'], ...
    'Position', [235 45 405 210]);
add_block('simulink/Continuous/Integrator', [path '/Integrate Vb'], ...
    'InitialCondition', '[0;0;0]', 'Position', [95 245 125 275]);
add_block('simulink/Continuous/Integrator', [path '/Integrate pqr'], ...
    'InitialCondition', '[0;0;0]', 'Position', [145 245 175 275]);
add_block('simulink/Continuous/Integrator', [path '/Integrate Euler'], ...
    'InitialCondition', '[0;0;0]', 'Position', [195 245 225 275]);
add_block('simulink/Continuous/Integrator', [path '/Integrate Xe'], ...
    'InitialCondition', '[0;0;-10]', 'Position', [245 245 275 275]);

outputNames = {'Ve','Xe','Euler','DCM','Vb','pqr','pqr_dot','Ab'};
for k = 1:numel(outputNames)
    add_block('simulink/Sinks/Out1', [path '/' outputNames{k}], ...
        'Position', [490 35+33*(k-1) 520 55+33*(k-1)]);
end

set_function_script(path);
add_line(path, 'Forces/1', 'Rigid body NED equations/1');
add_line(path, 'Moments/1', 'Rigid body NED equations/2');
add_line(path, 'Integrate Vb/1', 'Rigid body NED equations/3');
add_line(path, 'Integrate pqr/1', 'Rigid body NED equations/4');
add_line(path, 'Integrate Euler/1', 'Rigid body NED equations/5');
add_line(path, 'Rigid body NED equations/1', 'Integrate Vb/1');
add_line(path, 'Rigid body NED equations/2', 'Integrate pqr/1');
add_line(path, 'Rigid body NED equations/3', 'Integrate Euler/1');
add_line(path, 'Rigid body NED equations/4', 'Integrate Xe/1');
add_line(path, 'Rigid body NED equations/5', 'Ve/1');
add_line(path, 'Integrate Xe/1', 'Xe/1');
add_line(path, 'Integrate Euler/1', 'Euler/1');
add_line(path, 'Rigid body NED equations/6', 'DCM/1');
add_line(path, 'Integrate Vb/1', 'Vb/1');
add_line(path, 'Integrate pqr/1', 'pqr/1');
add_line(path, 'Rigid body NED equations/2', 'pqr_dot/1');
add_line(path, 'Rigid body NED equations/7', 'Ab/1');
end

function set_function_script(subsystemPath)
root = sfroot;
chart = root.find('-isa', 'Stateflow.EMChart', ...
    'Path', [subsystemPath '/Rigid body NED equations']);
chart.Script = sprintf([ ...
    'function [Vb_dot,pqr_dot,Euler_dot,Xe_dot,Ve,DCMbe,Ab] = fcn(Forces,Moments,Vb,pqr,Euler)\n' ...
    '%% 6DOF rigid-body equations, body axes + NED navigation frame.\n' ...
    'Forces = Forces(:); Moments = Moments(:); Vb = Vb(:); pqr = pqr(:); Euler = Euler(:);\n' ...
    'mass = 1.3211359852721711;\n' ...
    'I = diag([0.0093 0.0092 0.0151]);\n' ...
    'phi = Euler(1); theta = Euler(2); psi = Euler(3);\n' ...
    'cphi = cos(phi); sphi = sin(phi); ctheta = cos(theta); stheta = sin(theta);\n' ...
    'cpsi = cos(psi); spsi = sin(psi);\n' ...
    'DCMbe = [ctheta*cpsi, ctheta*spsi, -stheta; sphi*stheta*cpsi-cphi*spsi, sphi*stheta*spsi+cphi*cpsi, sphi*ctheta; cphi*stheta*cpsi+sphi*spsi, cphi*stheta*spsi-sphi*cpsi, cphi*ctheta];\n' ...
    'Ab = Forces/mass - cross(pqr,Vb);\n' ...
    'pqr_dot = I \\ (Moments - cross(pqr,I*pqr));\n' ...
    'Euler_dot = [1, sphi*tan(theta), cphi*tan(theta); 0, cphi, -sphi; 0, sphi/ctheta, cphi/ctheta]*pqr;\n' ...
    'Ve = DCMbe.''*Vb;\n' ...
    'Xe_dot = Ve;\n' ...
    'Vb_dot = Ab;\n' ...
    'end\n']);
end

function add_logger(model, variableName, position)
add_block('simulink/Sinks/To Workspace', [model '/' variableName], ...
    'VariableName', variableName, 'SaveFormat', 'Timeseries', 'Position', position);
end
