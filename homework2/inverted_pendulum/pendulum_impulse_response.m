function response = pendulum_impulse_response(P, duration, sampleTime)
%PENDULUM_IMPULSE_RESPONSE Compare Control Toolbox impulse with expm(A*t)B.

if nargin < 2
    duration = 1;
end
if nargin < 3
    sampleTime = 0.01;
end

time = (0:sampleTime:duration).';
system = ss(P.A, P.B, P.C, P.D);
[output, responseTime] = impulse(system, time);

analyticState = zeros(numel(responseTime), 4);
for index = 1:numel(responseTime)
    analyticState(index, :) = (expm(P.A * responseTime(index)) * P.B).';
end
analyticOutput = analyticState * P.C.';

response.time = responseTime;
response.output = output;
response.analyticOutput = analyticOutput;
response.maxErrorVsAnalytic = max(abs(output - analyticOutput), [], 'all');
end
