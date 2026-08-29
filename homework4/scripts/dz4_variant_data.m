function cfg = dz4_variant_data(variant_id)
%DZ4_VARIANT_DATA Return one fully converted DZ4 input-data set.
%   Aerodynamic derivatives in the methodical table are per degree and
%   are converted here to per radian. Angles and the input step are radians.

if ~(isnumeric(variant_id) && isscalar(variant_id) && isfinite(variant_id) && ...
        variant_id == fix(variant_id) && ismember(variant_id, 1:6))
    error('DZ4:VariantOutOfRange', 'variant_id must be an integer from 1 to 6.');
end

data.aircraft_type = ["normal" "normal" "normal" "normal" "canard" "canard"];
data.m_kg = [44 33.5 41.4 38 15.9 17];
data.Iz_kg_m2 = [13.46 12 7.872 7.45 0.968 1.114];
data.S_m2 = [0.022 0.022 0.0133 0.0133 0.011 0.011];
data.L_m = [1.88 1.88 1.6 1.6 0.789 0.953];
data.V_mps = [476 306 680 476 170 197.2];
data.theta_deg = [-9 -10 10.2 15 -34 5];
data.alpha_deg = [0.6 1.1 0.8 2.1 2.9 2];
data.P_N = [8000 0 3500 0 0 1100];
data.cy_alpha_per_deg = [0.273 0.368 0.2696 0.2896 0.191 0.218];
data.cy_delta_per_deg = [0.0821 0.1261 0.0476 0.0591 0.028 0.033];
data.mz_alpha_per_deg = [-0.03628 -0.00697 -0.0591 -0.0715 -0.037 -0.046];
data.mz_delta_per_deg = [-0.042474 -0.00697 -0.02195 -0.0282 -0.009 0.01];
data.mz_omega = [-4.3 -2.29 -5.1 -5.3 -1.3 -1.48];
data.rho_kg_m3 = [1.13 1.22 1.04 0.891 0.98 1.065];
data.delta_command_deg = [4 5 10 12 20 15];
data.step_time_s = [1 3 1 2 2 3];

i = variant_id;
cfg.variant_id = i;
cfg.g_mps2 = 9.81;
cfg.aircraft_type = data.aircraft_type(i);
cfg.control_sign = 1;
if cfg.aircraft_type == "normal"
    cfg.control_sign = -1;
end

cfg.m = data.m_kg(i);
cfg.Iz = data.Iz_kg_m2(i);
cfg.S = data.S_m2(i);
cfg.L = data.L_m(i);
cfg.V = data.V_mps(i);
cfg.P = data.P_N(i);
cfg.rho = data.rho_kg_m3(i);
cfg.theta_deg = data.theta_deg(i);
cfg.alpha_deg = data.alpha_deg(i);
cfg.theta_rad = cfg.theta_deg*pi/180;
cfg.alpha_rad = cfg.alpha_deg*pi/180;

cfg.cy_alpha_per_deg = data.cy_alpha_per_deg(i);
cfg.cy_delta_per_deg = data.cy_delta_per_deg(i);
cfg.mz_alpha_per_deg = data.mz_alpha_per_deg(i);
cfg.mz_delta_per_deg = data.mz_delta_per_deg(i);
cfg.cy_alpha = cfg.cy_alpha_per_deg*180/pi;
cfg.cy_delta = cfg.cy_delta_per_deg*180/pi;
cfg.mz_alpha = cfg.mz_alpha_per_deg*180/pi;
cfg.mz_delta = cfg.mz_delta_per_deg*180/pi;
cfg.mz_omega = data.mz_omega(i);

cfg.delta_command_deg = data.delta_command_deg(i);
cfg.delta_step_rad = cfg.control_sign*cfg.delta_command_deg*pi/180;
cfg.step_time_s = data.step_time_s(i);
cfg.stop_time_s = cfg.step_time_s + 8;
end
