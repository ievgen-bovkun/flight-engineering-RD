function response = pendulum_analytic_solution(time, force, initialState)
%PENDULUM_ANALYTIC_SOLUTION Exact state-space solution with ZOH input.
%
% X(t) = exp(A*t)*X(0) + integral(exp(A*(t-tau))*B*F(tau) d tau).
% For each time interval this function evaluates the integral exactly for a
% zero-order-held force value.

if nargin < 3
    initialState = zeros(4, 1);
end

time = time(:);
force = force(:);

if isscalar(force)
    force = repmat(force, numel(time), 1);
end
if numel(force) ~= numel(time)
    error('Force must be a scalar or have one value for each time sample.');
end

[~, P] = pendulum_state_space();
state = zeros(numel(time), 4);
state(1, :) = initialState(:).';

for k = 1:numel(time) - 1
    dt = time(k + 1) - time(k);
    augmented = [P.A, P.B; zeros(1, 5)];
    transition = expm(augmented * dt);
    phi = transition(1:4, 1:4);
    gamma = transition(1:4, 5);
    state(k + 1, :) = (phi * state(k, :).'+ gamma * force(k)).';
end

response.time = time;
response.force = force;
response.state = state;
response.output = state * P.C.' + force * P.D.';
end
