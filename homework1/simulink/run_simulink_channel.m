function out = run_simulink_channel(channel, showFigure)
%RUN_SIMULINK_CHANNEL Run one unit-step test and optionally show its plots.

if nargin < 2
    showFigure = true;
end

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
modelName = build_quadrotor_simulink(false);
P = quadrotor_params();
mix = quadrotor_test_mix(channel);

for k = 1:4
    set_param(modelName + "/Step " + k, 'After', num2str(mix(k)));
end
set_param(modelName, 'StopTime', num2str(P.stop_time));

simulation = sim(modelName, 'ReturnWorkspaceOutputs', 'on');
out = struct( ...
    'channel', string(channel), ...
    'position', normalise_log(simulation.position), ...
    'velocity', normalise_log(simulation.velocity), ...
    'angles', normalise_log(simulation.angles), ...
    'angularRates', normalise_log(simulation.angularRates), ...
    'rotorSpeed', normalise_log(simulation.rotorSpeed));

if showFigure
    plot_simulink_results(out);
end

function log = normalise_log(timeseriesLog)
% Simulink stores vector logs as 1-by-width-by-N, where N is time samples.
rawData = timeseriesLog.Data;
sampleCount = numel(timeseriesLog.Time);
timeDimension = find(size(rawData) == sampleCount, 1, 'last');
dimensionOrder = [timeDimension, setdiff(1:ndims(rawData), timeDimension, 'stable')];
orderedData = permute(rawData, dimensionOrder);
log = struct( ...
    'Time', timeseriesLog.Time, ...
    'Data', reshape(orderedData, sampleCount, []));
end
end
