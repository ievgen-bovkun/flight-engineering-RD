function P = quadrotor_params()
%QUADROTOR_PARAMS Parameters for the nonlinear Linkquad model.
% Values come from Jiřinec's thesis unless a note marks an assumption.

P.g = 9.81;
P.Ix = 0.0093;
P.Iy = 0.0092;
P.Iz = 0.0151;
P.Ip = 4.439e-5;

P.b = 1.5108e-5;
P.d = 4.406e-7;
P.l = 0.24; % Assumption: arm length was not confirmed in the thesis.

P.Omega0 = 463.1;
P.m = 4 * P.b * P.Omega0^2 / P.g;

P.tau = 0.1;
P.Kdc = 0.7;
P.Omega_min = 0;
P.Omega_max = 150 * 2 * pi;
P.u_hover = P.Omega0 / P.Kdc;

P.step_time = 1;
% Four seconds keeps the uncontrolled attitude tests below Euler singularities.
P.stop_time = 4;
P.max_step = 0.01;
end
