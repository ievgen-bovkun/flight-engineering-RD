function model = derive_pendulum_model()
%DERIVE_PENDULUM_MODEL Symbolically derive the CTMS cart-pendulum model.

syms M m b I l g F real
syms x xDot phi phiDot xDDot phiDDot real

% CTMS nonlinear equations (upright angle phi measured from vertical).
cartEquation = (M + m) * xDDot + b * xDot - ...
    m * l * phiDDot * cos(phi) + m * l * phiDot^2 * sin(phi) - F;
pendulumEquation = (I + m * l^2) * phiDDot - ...
    m * l * xDDot * cos(phi) - m * g * l * sin(phi);

[nonlinearXDDot, nonlinearPhiDDot] = solve( ...
    [cartEquation == 0, pendulumEquation == 0], [xDDot, phiDDot]);

% sin(phi) ~= phi and cos(phi) ~= 1 around the upright equilibrium.
linearCartEquation = (M + m) * xDDot + b * xDot - m * l * phiDDot - F;
linearPendulumEquation = (I + m * l^2) * phiDDot + ...
    -m * l * xDDot - m * g * l * phi;
[linearXDDot, linearPhiDDot] = solve( ...
    [linearCartEquation == 0, linearPendulumEquation == 0], [xDDot, phiDDot]);

state = [x; xDot; phi; phiDot];
stateDerivative = [xDot; linearXDDot; phiDot; linearPhiDDot];

model.symbols = struct('M', M, 'm', m, 'b', b, 'I', I, 'l', l, 'g', g, ...
    'F', F, 'x', x, 'xDot', xDot, 'phi', phi, 'phiDot', phiDot);
model.nonlinear.cartEquation = cartEquation == 0;
model.nonlinear.pendulumEquation = pendulumEquation == 0;
model.nonlinear.xDDot = simplify(nonlinearXDDot);
model.nonlinear.phiDDot = simplify(nonlinearPhiDDot);
model.linear.cartEquation = linearCartEquation == 0;
model.linear.pendulumEquation = linearPendulumEquation == 0;
model.linear.xDDot = simplify(linearXDDot);
model.linear.phiDDot = simplify(linearPhiDDot);
model.state = state;
model.stateDerivative = simplify(stateDerivative);
model.A = simplify(jacobian(stateDerivative, state));
model.B = simplify(diff(stateDerivative, F));
model.C = [1, 0, 0, 0; 0, 0, 1, 0];
model.D = zeros(2, 1);
end
