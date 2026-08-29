function result = dz4_run(variantId)
%DZ4_RUN Simulate variant 1 in MATLAB and Simulink and save evidence.

if nargin < 1
    variantId = 1;
end

cfg = dz4_variant_data(variantId);
[modelData, q] = dz4_build_state_space(cfg);
modelName = dz4_build_simulink_model(cfg, modelData);

rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

timeStep = 1e-3;
t = (0:timeStep:cfg.stop_time_s).';
u = zeros(size(t));
u(t >= cfg.step_time_s) = cfg.delta_step_rad;

linearModel = ss(modelData.A, modelData.B, modelData.C, modelData.D);
matlabStates = lsim(linearModel, u, t);

load_system(modelName);
simOutput = sim(modelName, ...
    'StartTime', '0', ...
    'StopTime', num2str(cfg.stop_time_s, '%.12g'), ...
    'ReturnWorkspaceOutputs', 'on');
savedStates = simOutput.get('states');
simulinkTime = savedStates.time(:);
simulinkValues = savedStates.signals.values;
simulinkStates = interp1(simulinkTime, simulinkValues, t, 'linear');

comparisonError = matlabStates - simulinkStates;
maxAbsError = max(abs(comparisonError), [], 'all');
rmsErrorPerState = sqrt(mean(comparisonError.^2, 1));
rmsErrorGlobal = sqrt(mean(comparisonError.^2, 'all'));

dynamicEigenvalues = eig(modelData.A(1:4, 1:4));
fullEigenvalues = eig(modelData.A);
oscillatory = dynamicEigenvalues(imag(dynamicEigenvalues) > 1e-8);
[~, order] = sort(abs(imag(oscillatory)), 'descend');
shortLambda = oscillatory(order(1));
realModes = dynamicEigenvalues(abs(imag(dynamicEigenvalues)) <= 1e-8);
stableRealModes = realModes(real(realModes) < -1e-8);
[~, slowIndex] = min(abs(real(stableRealModes)));
slowRealLambda = stableRealModes(slowIndex);
[~, neutralIndex] = min(abs(real(realModes)));
neutralLambda = realModes(neutralIndex);

shortSubsystemA = [q.Q2_alpha q.Q2_omega; q.Q4_alpha q.Q4_omega];
shortSubsystemB = [q.Q2_delta; q.Q4_delta];
quasiSteady = -shortSubsystemA \ (shortSubsystemB*cfg.delta_step_rad);

altitudeWindow = t >= cfg.step_time_s & t <= min(cfg.stop_time_s, cfg.step_time_s + 2);
altitudeTimes = t(altitudeWindow);
altitudeValues = matlabStates(altitudeWindow, 5);
[altitudeDip, altitudeIndex] = min(altitudeValues);

result.cfg = cfg;
result.q = q;
result.model_data = modelData;
result.model_name = modelName;
result.time = t;
result.input = u;
result.input_step_rad = cfg.delta_step_rad;
result.matlab_states = matlabStates;
result.simulink_states = simulinkStates;
result.simulink_native_time = simulinkTime;
result.simulink_native_states = simulinkValues;
result.max_abs_error = maxAbsError;
result.rms_error_per_state = rmsErrorPerState;
result.rms_error_global = rmsErrorGlobal;
result.comparison_error = comparisonError;
result.full_eigenvalues = fullEigenvalues;
result.short_period = dz4_mode_metrics(shortLambda);
result.slow_real_mode = dz4_real_mode_metrics(slowRealLambda);
result.neutral_mode_eigenvalue = neutralLambda;
result.quasi_steady_alpha_rad = quasiSteady(1);
result.quasi_steady_omega_z_rad_s = quasiSteady(2);
result.quasi_steady_alpha_deg = quasiSteady(1)*180/pi;
result.quasi_steady_omega_z_deg_s = quasiSteady(2)*180/pi;
result.altitude_dip_m = altitudeDip;
result.altitude_dip_time_s = altitudeTimes(altitudeIndex);
result.results_mat_path = fullfile(resultsDir, 'dz4_variant_1_results.mat');
result.summary_csv_path = fullfile(resultsDir, 'dz4_variant_1_numeric_summary.csv');

savedResult = result; %#ok<NASGU>
save(result.results_mat_path, 'savedResult');

names = ["Q1_theta"; "Q1_alpha"; "Q1_delta"; "Q4_alpha"; ...
    "Q4_omega"; "Q4_delta"; "max_abs_error"; "rms_error_global"; ...
    "rms_theta"; "rms_alpha"; "rms_vartheta"; "rms_omega_z"; "rms_H"; ...
    "altitude_dip_m"; ...
    "altitude_dip_time_s"; "short_period_wn_rad_s"; ...
    "short_period_zeta"; "slow_real_eigenvalue_1_s"; ...
    "slow_real_time_constant_s"; "neutral_mode_eigenvalue_1_s"; ...
    "quasi_steady_alpha_deg"; "quasi_steady_omega_z_deg_s"];
values = [q.Q1_theta; q.Q1_alpha; q.Q1_delta; q.Q4_alpha; ...
    q.Q4_omega; q.Q4_delta; maxAbsError; rmsErrorGlobal; ...
    rmsErrorPerState.'; altitudeDip; ...
    result.altitude_dip_time_s; result.short_period.natural_frequency_rad_s; ...
    result.short_period.damping_ratio; result.slow_real_mode.eigenvalue; ...
    result.slow_real_mode.time_constant_s; result.neutral_mode_eigenvalue; ...
    result.quasi_steady_alpha_deg; result.quasi_steady_omega_z_deg_s];
units = ["1/s"; "1/s"; "1/s"; "1/s^2"; "1/s"; "1/s^2"; ...
    "state units"; "state units"; "rad"; "rad"; "rad"; "rad/s"; "m"; ...
    "m"; "s"; "rad/s"; "1"; "1/s"; "s"; "1/s"; "deg"; "deg/s"];
writetable(table(names, values, units), result.summary_csv_path);
end

function metrics = dz4_mode_metrics(lambda)
metrics.eigenvalue = lambda;
metrics.natural_frequency_rad_s = abs(lambda);
metrics.damping_ratio = -real(lambda)/abs(lambda);
end

function metrics = dz4_real_mode_metrics(lambda)
metrics.eigenvalue = lambda;
metrics.time_constant_s = -1/real(lambda);
end
