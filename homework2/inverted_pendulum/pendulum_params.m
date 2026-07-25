function P = pendulum_params()
%PENDULUM_PARAMS CTMS parameters and linear model matrices for the upright cart-pendulum.

P.M = 0.5;    % Cart mass [kg]
P.m = 0.2;    % Pendulum mass [kg]
P.b = 0.1;    % Cart viscous friction [N s/m]
P.I = 0.006;  % Pendulum inertia [kg m^2]
P.l = 0.3;    % Pivot-to-center-of-mass distance [m]
P.g = 9.8;    % Gravity [m/s^2]

P.p = P.I * (P.M + P.m) + P.M * P.m * P.l^2;
P.A = [0, 1, 0, 0; ...
       0, -(P.I + P.m * P.l^2) * P.b / P.p, -(P.m^2 * P.g * P.l^2) / P.p, 0; ...
       0, 0, 0, 1; ...
       0, -(P.m * P.l * P.b) / P.p, P.m * P.g * P.l * (P.M + P.m) / P.p, 0];
P.B = [0; (P.I + P.m * P.l^2) / P.p; 0; P.m * P.l / P.p];
P.C = [1, 0, 0, 0; ...
       0, 0, 1, 0];
P.D = zeros(2, 1);
end
