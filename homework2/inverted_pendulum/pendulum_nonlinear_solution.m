function response = pendulum_nonlinear_solution(P, time, initialState, force)
%PENDULUM_NONLINEAR_SOLUTION Integrate the full upright cart-pendulum model.
%
% State order is [x; xDot; phi; phiDot]. The angle phi is measured from
% the upright equilibrium with the same sign convention as the CTMS A/B model.

if nargin < 3
    initialState = zeros(4, 1);
end

time = time(:);
if nargin < 4
    force = zeros(size(time));
else
    force = force(:);
end

if numel(force) == 1
    force = repmat(force, numel(time), 1);
end
if numel(force) ~= numel(time)
    error('Force must be a scalar or have one value for each time sample.');
end

forceAtTime = @(t) interp1(time, force, t, 'previous', 'extrap');
ode = @(t, state) nonlinear_derivative(t, state, P, forceAtTime);
options = odeset('RelTol', 1e-9, 'AbsTol', 1e-11);
[solutionTime, state] = ode45(ode, time, initialState(:), options);

response.time = solutionTime;
response.force = force;
response.state = state;
response.output = state * P.C.';
end

function derivative = nonlinear_derivative(time, state, P, forceAtTime)
xDot = state(2);
phi = state(3);
phiDot = state(4);

% The mass matrix retains the sin(phi), cos(phi), and centripetal terms
% discarded by the linearization about phi = 0.
massMatrix = [P.M + P.m, -P.m * P.l * cos(phi); ...
              -P.m * P.l * cos(phi), P.I + P.m * P.l^2];
rightHandSide = [forceAtTime(time) - P.b * xDot - P.m * P.l * phiDot^2 * sin(phi); ...
                 P.m * P.g * P.l * sin(phi)];
acceleration = massMatrix \ rightHandSide;

derivative = [xDot; acceleration(1); phiDot; acceleration(2)];
end
