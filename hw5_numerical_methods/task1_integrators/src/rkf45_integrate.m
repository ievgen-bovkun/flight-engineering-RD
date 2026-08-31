function [T,Y,stats] = rkf45_integrate(rhs, tspan, y0, opts)
%RKF45_INTEGRATE Integrate with Fehlberg error control and bounded steps.
validateattributes(tspan, {'numeric'}, {'vector','numel',2,'real','finite'});
required = {'h0','tolerance','hMin','hMax'};
assert(isstruct(opts) && all(isfield(opts,required)), 'RKF45:MissingOption');
assert(opts.tolerance > 0 && opts.hMin > 0 && opts.hMin <= opts.h0 && ...
    opts.h0 <= opts.hMax, 'RKF45:InvalidOptions');
t0 = tspan(1); tf = tspan(2);
assert(tf > t0, 'RKF45:InvalidTimeSpan');
t = t0; y = y0(:); h = opts.h0;
T = t; Y = y.';
trialTimes = zeros(0,1); trialH = zeros(0,1); trialErrors = zeros(0,1);
trialAccepted = false(0,1); accepted = 0; rejected = 0;
while t < tf
    hTrial = min(h, tf-t);
    [~,y5,errorVector] = rkf45_step(rhs, t, y, hTrial);
    errorNorm = max(abs(errorVector));
    isAccepted = errorNorm <= opts.tolerance;
    trialTimes(end+1,1) = t; %#ok<AGROW>
    trialH(end+1,1) = hTrial; %#ok<AGROW>
    trialErrors(end+1,1) = errorNorm; %#ok<AGROW>
    trialAccepted(end+1,1) = isAccepted; %#ok<AGROW>
    if isAccepted
        t = t + hTrial;
        if abs(tf-t) <= 10*eps(max(1,abs(tf)))
            t = tf;
        end
        y = y5;
        accepted = accepted + 1;
        T(end+1,1) = t; %#ok<AGROW>
        Y(end+1,:) = y.'; %#ok<AGROW>
    else
        rejected = rejected + 1;
        if hTrial <= opts.hMin*(1+10*eps)
            error('RKF45:MinimumStepReached', 'Tolerance cannot be met at hMin.');
        end
    end
    if errorNorm == 0
        factor = 5;
    else
        factor = min(5, max(0.2, 0.9*(opts.tolerance/errorNorm)^(1/5)));
    end
    h = min(opts.hMax, max(opts.hMin, hTrial*factor));
end
stats = struct('acceptedSteps',accepted,'rejectedSteps',rejected, ...
    'trialTimes',trialTimes,'trialStepSizes',trialH, ...
    'trialErrors',trialErrors,'trialAccepted',trialAccepted);
end
