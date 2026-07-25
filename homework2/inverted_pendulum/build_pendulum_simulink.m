function modelName = build_pendulum_simulink(forceRebuild)
%BUILD_PENDULUM_SIMULINK Create the linear CTMS cart-pendulum Simulink model.
%
% The model contains a unit force step, a State-Space block, a Scope, and
% a To Workspace block. It is intentionally small so each block is easy to
% inspect while learning Simulink.

if nargin < 1
    forceRebuild = false;
end

modelName = 'inverted_pendulum_linear';
projectDir = fileparts(mfilename('fullpath'));
modelDir = fullfile(projectDir, 'simulink');
modelPath = fullfile(modelDir, [modelName '.slx']);

if ~isfolder(modelDir)
    mkdir(modelDir);
end

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

if forceRebuild && isfile(modelPath)
    delete(modelPath);
end

if isfile(modelPath)
    load_system(modelPath);
    return;
end

P = pendulum_params();
assignin('base', 'P', P);

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime', '5', 'Solver', 'ode45');

add_block('simulink/Sources/Step', [modelName '/Unit force step'], ...
    'Position', [30 90 60 120], ...
    'Time', '0.5', 'Before', '0', 'After', '1');

add_block('simulink/Continuous/State-Space', [modelName '/Linearized pendulum'], ...
    'Position', [135 75 285 135], ...
    'A', 'P.A', 'B', 'P.B', 'C', 'P.C', 'D', 'P.D', 'X0', 'zeros(4,1)');

add_block('simulink/Sinks/Scope', [modelName '/Response scope'], ...
    'Position', [360 65 390 95]);

add_block('simulink/Sinks/To Workspace', [modelName '/Simulation output'], ...
    'Position', [355 130 450 160], ...
    'VariableName', 'pendulum_simulink_output', ...
    'SaveFormat', 'Structure With Time');

add_line(modelName, 'Unit force step/1', 'Linearized pendulum/1');
add_line(modelName, 'Linearized pendulum/1', 'Response scope/1');
add_line(modelName, 'Linearized pendulum/1', 'Simulation output/1');

save_system(modelName, modelPath);
end
