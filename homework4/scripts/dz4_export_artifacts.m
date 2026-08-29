function result = dz4_export_artifacts(result)
%DZ4_EXPORT_ARTIFACTS Export report-ready figures from a DZ4 simulation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

result.responses_png_path = fullfile(resultsDir, 'dz4_variant_1_state_responses.png');
result.altitude_dip_png_path = fullfile(resultsDir, 'dz4_variant_1_altitude_dip.png');
result.simulink_scheme_png_path = fullfile(resultsDir, 'dz4_variant_1_simulink_scheme.png');

stateScale = [180/pi 180/pi 180/pi 180/pi 1];
stateUnits = {'deg', 'deg', 'deg', 'deg/s', 'm'};
stateTitles = {'Delta theta', 'Delta alpha', 'Delta vartheta', ...
    'Delta omega_z', 'Delta H'};

responsesFigure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1400 850]);
layout = tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(layout, sprintf('DZ4, variant %d: response to delta_1 = %.1f deg at t = %.1f s', ...
    result.cfg.variant_id, result.cfg.delta_command_deg * result.cfg.control_sign, ...
    result.cfg.step_time_s));
for i = 1:5
    nexttile;
    plot(result.time, result.matlab_states(:, i)*stateScale(i), ...
        'LineWidth', 1.5);
    hold on;
    plot(result.time, result.simulink_states(:, i)*stateScale(i), '--', ...
        'LineWidth', 1.0);
    grid on;
    xline(result.cfg.step_time_s, ':k', 'Step');
    xlabel('t, s');
    ylabel([stateTitles{i} ', ' stateUnits{i}]);
    title(stateTitles{i});
    if i == 1
        legend({'MATLAB lsim', 'Simulink'}, 'Location', 'best');
    end
end
nexttile;
axis off;
text(0, 0.82, sprintf('Max |MATLAB - Simulink| = %.3e', result.max_abs_error), ...
    'FontSize', 12);
text(0, 0.60, sprintf('Altitude dip = %.3f m at t = %.3f s', ...
    result.altitude_dip_m, result.altitude_dip_time_s), 'FontSize', 12);
text(0, 0.38, sprintf('Short period: wn = %.3f rad/s, zeta = %.3f', ...
    result.short_period.natural_frequency_rad_s, result.short_period.damping_ratio), ...
    'FontSize', 12);
text(0, 0.16, sprintf('Slow real mode: tau = %.1f s; neutral mode = %.2e 1/s', ...
    result.slow_real_mode.time_constant_s, result.neutral_mode_eigenvalue), ...
    'FontSize', 12);
exportgraphics(responsesFigure, result.responses_png_path, 'Resolution', 200);
close(responsesFigure);

dipFigure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 500]);
plot(result.time, result.matlab_states(:, 5), 'LineWidth', 1.5);
hold on;
plot(result.time, result.simulink_states(:, 5), '--', 'LineWidth', 1.0);
plot(result.altitude_dip_time_s, result.altitude_dip_m, 'ro', ...
    'MarkerFaceColor', 'r');
xline(result.cfg.step_time_s, ':k', 'Step');
grid on;
dipWindow = result.time >= result.cfg.step_time_s - 0.01 & ...
    result.time <= result.cfg.step_time_s + 0.08;
dipValues = result.matlab_states(dipWindow, 5);
xlim([result.cfg.step_time_s - 0.01, result.cfg.step_time_s + 0.08]);
ylim([min(dipValues) - 0.002, max(dipValues) + 0.005]);
xlabel('t, s');
ylabel('Delta H, m');
title('Initial altitude dip after the control step');
legend({'MATLAB lsim', 'Simulink', 'Minimum'}, 'Location', 'best');
exportgraphics(dipFigure, result.altitude_dip_png_path, 'Resolution', 200);
close(dipFigure);

load_system(result.model_name);
open_system(result.model_name);
set_param(result.model_name, 'ZoomFactor', 'FitSystem');
print(['-s' result.model_name], '-dpng', ...
    result.simulink_scheme_png_path, '-r200');
close_system(result.model_name, 0);
end
