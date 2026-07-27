function fig = plot_pendulum_comparison(result)
%PLOT_PENDULUM_COMPARISON Plot the three Task 1 methods on common axes.

fig = figure('Name', 'Task 1: method comparison', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile;
plot(result.time, result.analytic.output(:, 1), 'k-', 'LineWidth', 2); hold on;
plot(result.time, result.matlabOutput(:, 1), 'r--', 'LineWidth', 1.2);
plot(result.simulink.time, result.simulink.output(:, 1), 'bo', 'MarkerSize', 3);
grid on;
xlabel('Time [s]'); ylabel('Cart position x [m]');
title('Cart coordinate: analytical solution, MATLAB RK4, Simulink');
legend('Analytical expm', 'MATLAB RK4', 'Simulink', 'Location', 'northwest');

nexttile;
plot(result.time, rad2deg(result.analytic.output(:, 2)), 'k-', 'LineWidth', 2); hold on;
plot(result.time, rad2deg(result.matlabOutput(:, 2)), 'r--', 'LineWidth', 1.2);
plot(result.simulink.time, rad2deg(result.simulink.output(:, 2)), 'bo', 'MarkerSize', 3);
grid on;
xlabel('Time [s]'); ylabel('Pendulum angle phi [deg]');
title('Pendulum coordinate: analytical solution, MATLAB RK4, Simulink');
legend('Analytical expm', 'MATLAB RK4', 'Simulink', 'Location', 'northwest');
end
