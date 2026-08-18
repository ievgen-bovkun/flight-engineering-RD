function out = reference_6dof_rhs(x, input, cfg)
%REFERENCE_6DOF_RHS Continuous rigid-body 6DOF equations in NED axes.
% State order: [u v w p q r phi theta psi xN yE zD].'
% Input order: [Fx Fy Fz L M N].' in body axes.
% Gravity and any other environmental loads must be included in [Fx;Fy;Fz].

Vb = x(1:3);
pqr = x(4:6);
phi = x(7);
theta = x(8);
psi = x(9);
forces = input(1:3);
moments = input(4:6);

cphi = cos(phi);  sphi = sin(phi);
ctheta = cos(theta);  stheta = sin(theta);
cpsi = cos(psi);  spsi = sin(psi);

% Direction cosine matrix: NED (earth) vector -> body vector.
DCMbe = [ctheta*cpsi, ctheta*spsi, -stheta; ...
    sphi*stheta*cpsi-cphi*spsi, sphi*stheta*spsi+cphi*cpsi, sphi*ctheta; ...
    cphi*stheta*cpsi+sphi*spsi, cphi*stheta*spsi-sphi*cpsi, cphi*ctheta];

Ab = forces/cfg.mass - cross(pqr, Vb);
pqr_dot = cfg.inertia \ (moments - cross(pqr, cfg.inertia*pqr));
euler_dot = [1, sphi*tan(theta), cphi*tan(theta); ...
    0, cphi, -sphi; ...
    0, sphi/ctheta, cphi/ctheta]*pqr;
Ve = DCMbe.'*Vb;

out = struct( ...
    'xdot', [Ab; pqr_dot; euler_dot; Ve], ...
    'Ab', Ab, ...
    'pqr_dot', pqr_dot, ...
    'euler_dot', euler_dot, ...
    'DCMbe', DCMbe, ...
    'Ve', Ve);
end
