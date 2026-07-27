function result = run_pendulum_comparison(showFigure)
%RUN_PENDULUM_COMPARISON Compare exact, lsim, and Simulink responses.

if nargin < 1
    showFigure = true;
end

P = pendulum_params();
config.duration = 1.5;
config.stepTime = 0.5;
config.stepAmplitude = 0.01;
config.sampleTime = 0.002;
config.initialState = zeros(4, 1);

time = (0:config.sampleTime:config.duration).';
force = config.stepAmplitude * double(time >= config.stepTime);
analytic = pendulum_analytic_solution(time, force, config.initialState);
matlabResponse = pendulum_rk4_solution(time, force, config.initialState);
matlabOutput = matlabResponse.output;

assignin('base', 'P', P);
modelName = build_pendulum_simulink(false);
originalStopTime = get_param(modelName, 'StopTime');
originalStepTime = get_param([modelName '/Unit force step'], 'Time');
originalStepBefore = get_param([modelName '/Unit force step'], 'Before');
originalStepAfter = get_param([modelName '/Unit force step'], 'After');
set_param(modelName, 'StopTime', num2str(config.duration, 16));
set_param([modelName '/Unit force step'], ...
    'Time', num2str(config.stepTime, 16), ...
    'Before', '0', 'After', num2str(config.stepAmplitude, 16));

simulationResult = sim(modelName, 'ReturnWorkspaceOutputs', 'on');
simulinkOutput = simulationResult.get('pendulum_simulink_output');
set_param(modelName, 'StopTime', originalStopTime);
set_param([modelName '/Unit force step'], ...
    'Time', originalStepTime, 'Before', originalStepBefore, 'After', originalStepAfter);
set_param(modelName, 'Dirty', 'off');
simulinkTime = simulinkOutput.time;
simulinkValues = simulinkOutput.signals.values;

analyticAtSimulink = pendulum_analytic_solution( ...
    simulinkTime, config.stepAmplitude * double(simulinkTime >= config.stepTime), ...
    config.initialState);
matlabAtSimulink = interp1(time, matlabOutput, simulinkTime, 'linear');

result.config = config;
result.time = time;
result.force = force;
result.analytic = analytic;
result.matlabOutput = matlabOutput;
result.simulink.time = simulinkTime;
result.simulink.output = simulinkValues;
result.maxError.analyticVsRk4 = max(abs(analytic.output - matlabOutput), [], 'all');
result.maxError.analyticVsSimulink = max(abs(analyticAtSimulink.output - simulinkValues), [], 'all');
result.maxError.rk4VsSimulink = max(abs(matlabAtSimulink - simulinkValues), [], 'all');

if showFigure
    plot_pendulum_comparison(result);
end
end
