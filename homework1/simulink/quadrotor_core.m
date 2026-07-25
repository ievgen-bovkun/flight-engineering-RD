function dx = quadrotor_core(U, x, P)
%QUADROTOR_CORE Nonlinear 16-state Linkquad dynamics for MATLAB/Simulink.
% U is a four-element motor-command perturbation around the hover command.

u = x(4); v = x(5); w = x(6);
phi = x(7); th = x(8); ps = x(9);
p = x(10); q = x(11); r = x(12);
Om = x(13:16);

D = [cos(th)*cos(ps), cos(th)*sin(ps), -sin(th);
     sin(phi)*sin(th)*cos(ps)-cos(phi)*sin(ps), sin(phi)*sin(th)*sin(ps)+cos(phi)*cos(ps), sin(phi)*cos(th);
     cos(phi)*sin(th)*cos(ps)+sin(phi)*sin(ps), cos(phi)*sin(th)*sin(ps)-sin(phi)*cos(ps), cos(phi)*cos(th)];
pos_dot = D.' * [u; v; w];

Einv = [1, sin(phi)*tan(th), cos(phi)*tan(th);
        0, cos(phi), -sin(phi);
        0, sin(phi)/cos(th), cos(phi)/cos(th)];
ang_dot = Einv * [p; q; r];

T = P.b * sum(Om.^2);
Mx = P.l * P.b * (Om(2)^2 - Om(4)^2);
My = P.l * P.b * (Om(1)^2 - Om(3)^2);
Mz = P.d * (Om(2)^2 + Om(4)^2 - Om(1)^2 - Om(3)^2);
Hz = P.Ip * (Om(1) - Om(2) + Om(3) - Om(4));

u_dot = r*v - q*w - P.g*sin(th);
v_dot = p*w - r*u + P.g*cos(th)*sin(phi);
w_dot = q*u - p*v + P.g*cos(phi)*cos(th) - T/P.m;

p_dot = Mx/P.Ix - q*r*(P.Iz-P.Iy)/P.Ix - Hz*q/P.Ix;
q_dot = My/P.Iy - p*r*(P.Ix-P.Iz)/P.Iy + Hz*p/P.Iy;
r_dot = Mz/P.Iz;

omega_cmd = P.Kdc * (P.u_hover + U(:));
omega_cmd = min(max(omega_cmd, P.Omega_min), P.Omega_max);
Om_dot = (omega_cmd - Om) / P.tau;

dx = [pos_dot; u_dot; v_dot; w_dot; ang_dot; p_dot; q_dot; r_dot; Om_dot];
end
