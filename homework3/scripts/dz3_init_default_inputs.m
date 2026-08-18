function dz3_init_default_inputs(model)
%DZ3_INIT_DEFAULT_INPUTS Provide safe zero loads for a direct model run.
% Existing scenario inputs are intentionally preserved.

if nargin < 1 || isempty(model)
    model = bdroot;
end
fixedStep = str2double(get_param(model, 'FixedStep'));
if ~isfinite(fixedStep) || fixedStep <= 0
    fixedStep = 0.001;
end
stopTime = str2double(get_param(model, 'StopTime'));
if ~isfinite(stopTime) || stopTime <= 0
    stopTime = 4;
end
time = (0:fixedStep:stopTime).';

create_zero_input_if_missing('forces_ts', time);
create_zero_input_if_missing('moments_ts', time);
end

function create_zero_input_if_missing(variableName, time)
existsInBase = evalin('base', sprintf("exist('%s','var')", variableName));
if existsInBase == 0
    assignin('base', variableName, timeseries(zeros(numel(time), 3), time));
end
end
