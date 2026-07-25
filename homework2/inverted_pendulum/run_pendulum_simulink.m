function modelName = run_pendulum_simulink
%RUN_PENDULUM_SIMULINK Build, open, and simulate the introductory model.

projectDir = fileparts(mfilename('fullpath'));
addpath(projectDir);
assignin('base', 'P', pendulum_params());
modelName = build_pendulum_simulink(false);
open_system(modelName);
simulationResult = sim(modelName, 'ReturnWorkspaceOutputs', 'on');
output = simulationResult.get('pendulum_simulink_output');
assignin('base', 'pendulum_simulink_output', output);
plot_pendulum_response(output);
open_system([modelName '/Response scope']);
end
