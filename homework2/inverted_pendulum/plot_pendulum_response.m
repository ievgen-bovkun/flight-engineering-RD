function fig = plot_pendulum_response(output, makeVisible)
%PLOT_PENDULUM_RESPONSE Show the cart and upright-pendulum response clearly.

if nargin < 2
    makeVisible = true;
end

visibility = 'off';
if makeVisible
    visibility = 'on';
end

time = output.time;
values = output.signals.values;

fig = figure('Name', 'Inverted pendulum response', ...
    'Color', 'w', 'Visible', visibility);
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile;
plot(time, values(:, 1), 'LineWidth', 1.6);
grid on;
xlabel('Time [s]');
ylabel('Cart position x [m]');
title('Cart response to a unit force step');

nexttile;
plot(time, rad2deg(values(:, 2)), 'LineWidth', 1.6);
grid on;
xlabel('Time [s]');
ylabel('Pendulum angle phi [deg]');
title('Inverted pendulum angle response');
end
