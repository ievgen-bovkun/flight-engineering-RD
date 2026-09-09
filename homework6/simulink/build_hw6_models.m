function build_hw6_models()
%BUILD_HW6_MODELS Create report-ready Simulink models for Homework 6.
% The model uses a fixed 5 ms solver step: each PID update is held for
% exactly one integration step.  It is intentionally rebuilt from source.

root = fileparts(fileparts(mfilename('fullpath')));
models = fullfile(root, 'simulink');
linearName = 'hw6_linear_pendulum';
nonlinearName = 'hw6_nonlinear_pendulum';

M = 0.5; m = 0.2; b = 0.1; l = 0.3; I = 0.006; g = 9.81;
p = I*(M + m) + M*m*l^2;
A = [0 1 0 0; 0 -(I+m*l^2)*b/p -(m^2)*g*l^2/p 0; ...
     0 0 0 1; 0 m*l*b/p (M+m)*m*g*l/p 0];
B = [0; (I+m*l^2)/p; 0; -m*l/p];
C = [1 0 0 0; 0 0 1 0];
D = zeros(2,1);

createLinearModel(linearName, models, A, B, C, D);
createNonlinearModel(nonlinearName, models, M, m, b, l, I, g);
end

function createLinearModel(name, folder, A, B, C, D)
resetModel(name, folder);
new_system(name); open_system(name);
set_param(name, 'Solver', 'ode4', 'FixedStep', '0.005', 'StopTime', '5');
workspace = get_param(name, 'ModelWorkspace');
assignin(workspace, 'A', A); assignin(workspace, 'B', B);
assignin(workspace, 'C', C); assignin(workspace, 'D', D);
add_block('simulink/Sources/Constant', [name '/Force u'], 'Value', '0', 'Position', [30 100 70 130]);
add_block('simulink/Continuous/State-Space', [name '/Linear state-space'], ...
    'A', 'A', 'B', 'B', 'C', 'C', 'D', 'D', 'X0', '[0;0;10*pi/180;0]', 'Position', [145 70 310 160]);
add_block('simulink/Signal Routing/Demux', [name '/Demux x theta'], 'Outputs', '2', 'Position', [365 80 370 145]);
add_block('simulink/Math Operations/Gain', [name '/rad to deg'], 'Gain', '180/pi', 'Position', [445 112 520 142]);
add_block('simulink/Sinks/Scope', [name '/Theta scope'], 'Position', [600 105 640 145]);
add_block('simulink/Sinks/To Workspace', [name '/States'], 'VariableName', 'linear_states', 'SaveFormat', 'Structure With Time', 'Position', [420 45 520 75]);
add_line(name, 'Force u/1', 'Linear state-space/1');
add_line(name, 'Linear state-space/1', 'Demux x theta/1');
add_line(name, 'Linear state-space/1', 'States/1');
add_line(name, 'Demux x theta/2', 'rad to deg/1');
add_line(name, 'rad to deg/1', 'Theta scope/1');
save_system(name, fullfile(folder, [name '.slx']));
print(['-s' name], '-dpng', fullfile(folder, 'hw6_linear_pendulum_scheme.png'), '-r180');
close_system(name, 0);
end

function createNonlinearModel(name, folder, M, m, b, l, I, g)
resetModel(name, folder);
new_system(name); open_system(name);
set_param(name, 'Solver', 'ode4', 'FixedStep', '0.005', 'StopTime', '5');
workspace = get_param(name, 'ModelWorkspace');
assignin(workspace, 'M', M); assignin(workspace, 'm', m); assignin(workspace, 'b', b);
assignin(workspace, 'l', l); assignin(workspace, 'I', I); assignin(workspace, 'g', g);

add_block('simulink/Continuous/Integrator', [name '/Int x'], 'InitialCondition', '0', 'Position', [585 55 615 85]);
add_block('simulink/Continuous/Integrator', [name '/Int dx'], 'InitialCondition', '0', 'Position', [455 55 485 85]);
add_block('simulink/Continuous/Integrator', [name '/Int theta'], 'InitialCondition', '10*pi/180', 'Position', [585 185 615 215]);
add_block('simulink/Continuous/Integrator', [name '/Int dtheta'], 'InitialCondition', '0', 'Position', [455 185 485 215]);
add_block('simulink/User-Defined Functions/MATLAB Function', [name '/Nonlinear accelerations'], 'Position', [285 85 395 205]);
script = sprintf(['function [xdd,thdd] = fcn(dx,th,dth,u)\n' ...
    '%%#codegen\n' ...
    'M = %.12g; m = %.12g; b = %.12g; l = %.12g; I = %.12g; g = %.12g;\n' ...
    'c = cos(th); s = sin(th);\n' ...
    'detA = (M+m)*(I+m*l^2) - (m*l*c)^2;\n' ...
    'rhs1 = u - b*dx + m*l*dth^2*s; rhs2 = m*g*l*s;\n' ...
    'xdd = ((I+m*l^2)*rhs1 - m*l*c*rhs2)/detA;\n' ...
    'thdd = (-(m*l*c)*rhs1 + (M+m)*rhs2)/detA;\n' ...
    'end'], M, m, b, l, I, g);
root = sfroot;
chart = root.find('-isa', 'Stateflow.EMChart', ...
    'Path', [name '/Nonlinear accelerations']);
chart.Script = script;
add_block('simulink/Math Operations/Sum', [name '/theta minus reference'], 'Inputs', '+-', 'Position', [85 190 110 220]);
add_block('simulink/Sources/Constant', [name '/Theta reference'], 'Value', '0', 'Position', [35 230 65 260]);
add_block('simulink/Discrete/Discrete PID Controller', [name '/PID'], 'P', '40', 'I', '50', 'D', '5', 'SampleTime', '0.005', 'Position', [140 180 230 225]);
add_block('simulink/Discontinuities/Saturation', [name '/Force saturation'], 'UpperLimit', '20', 'LowerLimit', '-20', 'Position', [245 180 270 220]);
add_block('simulink/Signal Routing/Mux', [name '/State mux'], 'Inputs', '4', 'Position', [680 65 685 210]);
add_block('simulink/Sinks/To Workspace', [name '/States'], 'VariableName', 'nonlinear_states', 'SaveFormat', 'Structure With Time', 'Position', [735 75 840 105]);
add_block('simulink/Sinks/Scope', [name '/Theta scope'], 'Position', [735 180 775 220]);
add_line(name, 'Int dx/1', 'Int x/1'); add_line(name, 'Int x/1', 'State mux/1');
add_line(name, 'Nonlinear accelerations/1', 'Int dx/1'); add_line(name, 'Int dx/1', 'Nonlinear accelerations/1'); add_line(name, 'Int dx/1', 'State mux/2');
add_line(name, 'Int dtheta/1', 'Int theta/1'); add_line(name, 'Int theta/1', 'theta minus reference/1'); add_line(name, 'Int theta/1', 'Nonlinear accelerations/2'); add_line(name, 'Int theta/1', 'State mux/3'); add_line(name, 'Int theta/1', 'Theta scope/1');
add_line(name, 'Int dtheta/1', 'Nonlinear accelerations/3'); add_line(name, 'Int dtheta/1', 'State mux/4');
add_line(name, 'Theta reference/1', 'theta minus reference/2'); add_line(name, 'theta minus reference/1', 'PID/1'); add_line(name, 'PID/1', 'Force saturation/1'); add_line(name, 'Force saturation/1', 'Nonlinear accelerations/4');
add_line(name, 'State mux/1', 'States/1');
save_system(name, fullfile(folder, [name '.slx']));
print(['-s' name], '-dpng', fullfile(folder, 'hw6_nonlinear_pendulum_scheme.png'), '-r180');
close_system(name, 0);
end

function resetModel(name, folder)
if bdIsLoaded(name), close_system(name, 0); end
path = fullfile(folder, [name '.slx']);
if isfile(path), delete(path); end
end
