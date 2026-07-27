function response = pendulum_rk4_solution(time, force, initialState)
%PENDULUM_RK4_SOLUTION Integrate the linear CTMS model without toolboxes.

if nargin < 3
    initialState = zeros(4, 1);
end

time = time(:);
force = force(:);
if isscalar(force)
    force = repmat(force, numel(time), 1);
end

P = pendulum_params();
state = zeros(numel(time), 4);
state(1, :) = initialState(:).';

for k = 1:numel(time) - 1
    dt = time(k + 1) - time(k);
    f = @(x) P.A * x + P.B * force(k);
    x = state(k, :).';
    k1 = f(x);
    k2 = f(x + 0.5 * dt * k1);
    k3 = f(x + 0.5 * dt * k2);
    k4 = f(x + dt * k3);
    state(k + 1, :) = (x + dt * (k1 + 2*k2 + 2*k3 + k4) / 6).';
end

response.time = time;
response.force = force;
response.state = state;
response.output = state * P.C.' + force * P.D.';
end
