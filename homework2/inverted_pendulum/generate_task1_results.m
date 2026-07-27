function result = generate_task1_results()
%GENERATE_TASK1_RESULTS Create the comparison plot used in the Task 1 report.

projectDir = fileparts(mfilename('fullpath'));
assetDir = fullfile(projectDir, 'assets');
if ~isfolder(assetDir)
    mkdir(assetDir);
end

result = run_pendulum_comparison(true);
exportgraphics(gcf, fullfile(assetDir, 'task1_method_comparison.png'), ...
    'Resolution', 180);

comparisonTime = (0:0.002:1.2).';
comparisonInitialState = [0; 0; deg2rad(3); 0];
linearFreeResponse = pendulum_analytic_solution( ...
    comparisonTime, zeros(size(comparisonTime)), comparisonInitialState);
nonlinearFreeResponse = pendulum_nonlinear_solution( ...
    pendulum_params(), comparisonTime, comparisonInitialState);

figure('Name', 'Linear and nonlinear pendulum comparison', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(comparisonTime, rad2deg(linearFreeResponse.state(:, 3)), 'LineWidth', 1.7);
hold on;
plot(comparisonTime, rad2deg(nonlinearFreeResponse.state(:, 3)), '--', 'LineWidth', 1.7);
grid on;
yline(12, ':k', '12 deg');
yline(-12, ':k', 'HandleVisibility', 'off');
ylabel('phi [deg]');
legend('Linear model', 'Nonlinear model', 'Location', 'northwest');
title('Free response from a small initial deviation');
nexttile;
plot(comparisonTime, linearFreeResponse.state(:, 1), 'LineWidth', 1.7);
hold on;
plot(comparisonTime, nonlinearFreeResponse.state(:, 1), '--', 'LineWidth', 1.7);
grid on;
xlabel('Time [s]');
ylabel('Cart position x [m]');
legend('Linear model', 'Nonlinear model', 'Location', 'northwest');
exportgraphics(gcf, fullfile(assetDir, 'task1_linear_vs_nonlinear.png'), ...
    'Resolution', 180);

P = pendulum_params();
impulseResponse = pendulum_impulse_response(P, 1, 0.005);
figure('Name', 'Control Toolbox impulse validation', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
plot(impulseResponse.time, impulseResponse.output(:, 1), 'LineWidth', 1.7);
hold on;
plot(impulseResponse.time, impulseResponse.analyticOutput(:, 1), '--', 'LineWidth', 1.4);
grid on;
ylabel('Cart position x [m]');
legend('impulse(ss)', 'Analytical expm(A t) B', 'Location', 'northwest');
title('Unit impulse response: Control System Toolbox validation');
nexttile;
plot(impulseResponse.time, rad2deg(impulseResponse.output(:, 2)), 'LineWidth', 1.7);
hold on;
plot(impulseResponse.time, rad2deg(impulseResponse.analyticOutput(:, 2)), '--', 'LineWidth', 1.4);
grid on;
xlabel('Time [s]');
ylabel('Pendulum angle phi [deg]');
legend('impulse(ss)', 'Analytical expm(A t) B', 'Location', 'northwest');
exportgraphics(gcf, fullfile(assetDir, 'task1_impulse_validation.png'), ...
    'Resolution', 180);

fprintf('Maximum error, analytical vs MATLAB RK4: %.3e\n', ...
    result.maxError.analyticVsRk4);
fprintf('Maximum error, analytical vs Simulink: %.3e\n', ...
    result.maxError.analyticVsSimulink);
fprintf('Maximum error, MATLAB RK4 vs Simulink: %.3e\n', ...
    result.maxError.rk4VsSimulink);
fprintf('Maximum error, impulse(ss) vs analytical: %.3e\n', ...
    impulseResponse.maxErrorVsAnalytic);
end
