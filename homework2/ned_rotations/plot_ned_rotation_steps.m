function fig = plot_ned_rotation_steps(phi, theta, psi)
%PLOT_NED_ROTATION_STEPS Show yaw, pitch, and roll in separate panels.

if nargin < 1
    phi = deg2rad(30);
end
if nargin < 2
    theta = deg2rad(20);
end
if nargin < 3
    psi = deg2rad(45);
end

rotations = ned_rotation_matrices(phi, theta, psi);
colors.initial = [0.25, 0.25, 0.25];
colors.yaw = [0.00, 0.45, 0.74];
colors.pitch = [0.18, 0.55, 0.20];
colors.body = [0.85, 0.18, 0.16];

fig = figure('Name', 'NED yaw-pitch-roll steps', 'Color', 'w');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
draw_step(rotations.initial, colors.initial, 1, rotations.yaw, colors.yaw, ...
    sprintf('1. Yaw \\psi = %.0f deg about z_D', rad2deg(psi)));

nexttile;
draw_step(rotations.yaw, colors.yaw, 0.3, rotations.yawPitch, colors.pitch, ...
    sprintf('2. Pitch \\theta = %.0f deg about y_1', rad2deg(theta)));

nexttile;
draw_step(rotations.yawPitch, colors.pitch, 0.3, rotations.full, colors.body, ...
    sprintf('3. Roll \\phi = %.0f deg about x_2', rad2deg(phi)));
end

function draw_step(before, beforeColor, beforeAlpha, after, afterColor, titleText)
hold on;
draw_frame(before, beforeColor, beforeAlpha);
draw_frame(after, afterColor, 1);
plot3(nan, nan, nan, '-', 'Color', beforeAlpha * beforeColor + ...
    (1 - beforeAlpha) * [1, 1, 1], 'LineWidth', 2.1, 'DisplayName', 'before');
plot3(nan, nan, nan, '-', 'Color', afterColor, 'LineWidth', 2.1, ...
    'DisplayName', 'after');
legend('Location', 'southwest');
grid on;
axis equal;
xlim([-0.3, 1.25]);
ylim([-0.3, 1.25]);
zlim([-0.3, 1.25]);
xlabel('North N');
ylabel('East E');
zlabel('Down D');
title(titleText);
view(38, 24);
end

function draw_frame(R, color, opacity)
for axisIndex = 1:3
    vector = R(:, axisIndex);
    arrowColor = opacity * color + (1 - opacity) * [1, 1, 1];
    quiver3(0, 0, 0, vector(1), vector(2), vector(3), 0, ...
        'Color', arrowColor, 'LineWidth', 2.1, 'MaxHeadSize', 0.18, ...
        'HandleVisibility', 'off');
end
end
