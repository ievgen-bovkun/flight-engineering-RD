function modelName = build_quadrotor_simulink(openModel, forceRebuild)
%BUILD_QUADROTOR_SIMULINK Generate the nonlinear Linkquad Simulink model.

if nargin < 1
    openModel = true;
end
if nargin < 2
    forceRebuild = false;
end

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
modelName = 'quadrotor_nonlinear';
modelFile = fullfile(rootDir, modelName + ".slx");

if bdIsLoaded(modelName) && ~forceRebuild
    % Avoid reloading a root model that Simulink already has open.
    if openModel
        open_system(modelName);
    end
    return;
end

if isfile(modelFile) && ~forceRebuild
    load_system(modelFile);
    if openModel
        open_system(modelName);
    end
    return;
end

if bdIsLoaded(modelName)
    % Discard a partial, unsaved build left by an earlier failed attempt.
    close_system(modelName, 0);
end
if isfile(modelFile) && forceRebuild
    delete(modelFile);
end

P = quadrotor_params();
x0 = quadrotor_initial_state(P);
new_system(modelName);
load_system(modelName);
modelWorkspace = get_param(modelName, 'ModelWorkspace');
assignin(modelWorkspace, 'x0', x0);

set_param(modelName, ...
    'Solver', 'ode45', ...
    'StopTime', num2str(P.stop_time), ...
    'MaxStep', num2str(P.max_step), ...
    'ReturnWorkspaceOutputs', 'on');

for k = 1:4
    block = modelName + "/Step " + k;
    add_block('simulink/Sources/Step', block, ...
        'Time', num2str(P.step_time), ...
        'Before', '0', ...
        'After', '1', ...
        'Position', [40, 70 + 70*(k-1), 70, 100 + 70*(k-1)]);
end

add_block('simulink/Signal Routing/Mux', modelName + "/Motor input vector", ...
    'Inputs', '4', 'Position', [120, 135, 125, 305]);
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    modelName + "/Nonlinear plant", 'Position', [290, 150, 440, 240]);
add_block('simulink/Continuous/Integrator', modelName + "/State integrator", ...
    'InitialCondition', 'x0', 'Position', [500, 165, 530, 195]);
add_block('simulink/Signal Routing/Demux', modelName + "/State groups", ...
    'Outputs', '[3 3 3 3 4]', 'Position', [610, 130, 615, 350]);

chart = find(sfroot, '-isa', 'Stateflow.EMChart', ...
    'Path', char(modelName + "/Nonlinear plant"));
chart.Script = plant_script(P);
set_data_size(chart, 'U', '[4 1]');
set_data_size(chart, 'x', '[16 1]');
set_data_size(chart, 'dx', '[16 1]');

scopeNames = ["Position scope", "Velocity scope", "Angles scope", ...
              "Angular-rates scope", "Rotor-speed scope"];
logNames = ["position", "velocity", "angles", "angularRates", "rotorSpeed"];
for k = 1:5
    y = 50 + 110*(k-1);
    add_block('simulink/Sinks/Scope', modelName + "/" + scopeNames(k), ...
        'Position', [710, y, 740, y+35]);
    add_block('simulink/Sinks/To Workspace', modelName + "/Log " + logNames(k), ...
        'VariableName', logNames(k), ...
        'SaveFormat', 'Timeseries', ...
        'Position', [790, y, 880, y+35]);
end

function set_data_size(chart, dataName, sizeText)
data = find(chart, '-isa', 'Stateflow.Data', 'Name', dataName);
data.Props.Array.Size = sizeText;
end

function script = plant_script(P)
% The MATLAB Function block needs self-contained code for Simulink analysis.
constants = [ ...
    "g = " + num2str(P.g, 17) + ";";
    "Ix = " + num2str(P.Ix, 17) + ";";
    "Iy = " + num2str(P.Iy, 17) + ";";
    "Iz = " + num2str(P.Iz, 17) + ";";
    "Ip = " + num2str(P.Ip, 17) + ";";
    "b = " + num2str(P.b, 17) + ";";
    "d = " + num2str(P.d, 17) + ";";
    "l = " + num2str(P.l, 17) + ";";
    "m = " + num2str(P.m, 17) + ";";
    "tau = " + num2str(P.tau, 17) + ";";
    "Kdc = " + num2str(P.Kdc, 17) + ";";
    "u_hover = " + num2str(P.u_hover, 17) + ";";
    "Omega_min = " + num2str(P.Omega_min, 17) + ";";
    "Omega_max = " + num2str(P.Omega_max, 17) + ";"];

lines = [ ...
    "function dx = fcn(U, x)"
    "%#codegen"
    constants
    "u = x(4); v = x(5); w = x(6);"
    "phi = x(7); th = x(8); ps = x(9);"
    "p = x(10); q = x(11); r = x(12);"
    "Om = x(13:16);"
    "D = [cos(th)*cos(ps), cos(th)*sin(ps), -sin(th); sin(phi)*sin(th)*cos(ps)-cos(phi)*sin(ps), sin(phi)*sin(th)*sin(ps)+cos(phi)*cos(ps), sin(phi)*cos(th); cos(phi)*sin(th)*cos(ps)+sin(phi)*sin(ps), cos(phi)*sin(th)*sin(ps)-sin(phi)*cos(ps), cos(phi)*cos(th)];"
    "pos_dot = D.' * [u; v; w];"
    "Einv = [1, sin(phi)*tan(th), cos(phi)*tan(th); 0, cos(phi), -sin(phi); 0, sin(phi)/cos(th), cos(phi)/cos(th)];"
    "ang_dot = Einv * [p; q; r];"
    "T = b * sum(Om.^2);"
    "Mx = l*b * (Om(2)^2 - Om(4)^2);"
    "My = l*b * (Om(1)^2 - Om(3)^2);"
    "Mz = d * (Om(2)^2 + Om(4)^2 - Om(1)^2 - Om(3)^2);"
    "Hz = Ip * (Om(1) - Om(2) + Om(3) - Om(4));"
    "u_dot = r*v - q*w - g*sin(th);"
    "v_dot = p*w - r*u + g*cos(th)*sin(phi);"
    "w_dot = q*u - p*v + g*cos(phi)*cos(th) - T/m;"
    "p_dot = Mx/Ix - q*r*(Iz-Iy)/Ix - Hz*q/Ix;"
    "q_dot = My/Iy - p*r*(Ix-Iz)/Iy + Hz*p/Iy;"
    "r_dot = Mz/Iz;"
    "omega_cmd = Kdc * (u_hover + U(:));"
    "omega_cmd = min(max(omega_cmd, Omega_min), Omega_max);"
    "Om_dot = (omega_cmd - Om) / tau;"
    "dx = [pos_dot; u_dot; v_dot; w_dot; ang_dot; p_dot; q_dot; r_dot; Om_dot];"
    "end"];
script = char(join(lines, newline));
end

for k = 1:4
    add_line(modelName, "Step " + k + "/1", "Motor input vector/" + k, ...
        'autorouting', 'on');
end
add_line(modelName, 'Motor input vector/1', 'Nonlinear plant/1', 'autorouting', 'on');
add_line(modelName, 'Nonlinear plant/1', 'State integrator/1', 'autorouting', 'on');
add_line(modelName, 'State integrator/1', 'Nonlinear plant/2', 'autorouting', 'on');
add_line(modelName, 'State integrator/1', 'State groups/1', 'autorouting', 'on');
for k = 1:5
    add_line(modelName, "State groups/" + k, scopeNames(k) + "/1", 'autorouting', 'on');
    add_line(modelName, "State groups/" + k, "Log " + logNames(k) + "/1", 'autorouting', 'on');
end

save_system(modelName, modelFile);
if openModel
    open_system(modelName);
end
end
