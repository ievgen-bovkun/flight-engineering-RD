function [model, q] = dz4_build_state_space(cfg)
%DZ4_BUILD_STATE_SPACE Compute Qij and the methodical 5-state model.
%   The matrix layout is equation (34) in the supplied methodical note.

q.Q1_theta = cfg.g_mps2*sin(cfg.theta_rad)/cfg.V;
q.Q1_alpha = cfg.cy_alpha*cfg.rho*cfg.S*cfg.V/(2*cfg.m) + ...
    cfg.P*cos(cfg.alpha_rad)/(cfg.m*cfg.V);
q.Q1_delta = cfg.cy_delta*cfg.rho*cfg.S*cfg.V/(2*cfg.m);

q.Q2_theta = -q.Q1_theta;
q.Q2_alpha = -q.Q1_alpha;
q.Q2_omega = 1;
q.Q2_delta = -q.Q1_delta;

q.Q3_omega = 1;

q.Q4_alpha = cfg.mz_alpha*cfg.rho*cfg.V^2*cfg.S*cfg.L/(2*cfg.Iz);
q.Q4_omega = cfg.mz_omega*cfg.rho*cfg.V*cfg.S*cfg.L^2/(2*cfg.Iz);
q.Q4_delta = cfg.mz_delta*cfg.rho*cfg.V^2*cfg.S*cfg.L/(2*cfg.Iz);

q.Q5_theta = cfg.V*cos(cfg.theta_rad);

model.A = [q.Q1_theta q.Q1_alpha 0 0 0;
           q.Q2_theta q.Q2_alpha 0 q.Q2_omega 0;
           0 0 0 q.Q3_omega 0;
           0 q.Q4_alpha 0 q.Q4_omega 0;
           q.Q5_theta 0 0 0 0];
model.B = [q.Q1_delta; q.Q2_delta; 0; q.Q4_delta; 0];
model.C = eye(5);
model.D = zeros(5,1);
model.state_names = ["delta_theta" "delta_alpha" "delta_vartheta" ...
    "delta_omega_z" "delta_H"];
model.state_units = ["rad" "rad" "rad" "rad/s" "m"];
model.input_name = "delta_1";
model.input_unit = "rad";
end
