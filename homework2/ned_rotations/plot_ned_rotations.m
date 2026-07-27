function fig = plot_ned_rotations(phi, theta, psi)
%PLOT_NED_ROTATIONS Show the aerospace Z-Y-X rotation sequence in one view.

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
colors.initial = [0.10, 0.10, 0.10];
colors.yaw = [0.00, 0.45, 0.74];
colors.pitch = [0.18, 0.55, 0.20];
colors.body = [0.85, 0.18, 0.16];

fig = figure('Name', 'NED yaw-pitch-roll sequence', 'Color', 'w');
axes('Parent', fig);
hold on;
draw_frame(rotations.initial, colors.initial, {'x_N', 'y_E', 'z_D'});
draw_frame(rotations.yaw, colors.yaw, {'x_1', 'y_1', 'z_1'});
draw_frame(rotations.yawPitch, colors.pitch, {'x_2', 'y_2', 'z_2'});
draw_frame(rotations.full, colors.body, {'x_b', 'y_b', 'z_b'});

% Curves are drawn in the respective intermediate planes, exposing the
% active yaw-pitch-roll sequence rather than only its final matrix product.
draw_angle_arc([1; 0; 0], [0; 1; 0], psi, colors.yaw, '\psi');
draw_angle_arc(rotations.yaw(:, 1), -rotations.yaw(:, 3), theta, colors.pitch, '\theta');
draw_angle_arc(rotations.yawPitch(:, 2), rotations.yawPitch(:, 3), phi, colors.body, '\phi');

plot3(nan, nan, nan, '-', 'Color', colors.initial, 'LineWidth', 2.5, 'DisplayName', 'NED');
plot3(nan, nan, nan, '-', 'Color', colors.yaw, 'LineWidth', 2.5, 'DisplayName', 'after yaw \psi');
plot3(nan, nan, nan, '-', 'Color', colors.pitch, 'LineWidth', 2.5, 'DisplayName', 'after pitch \theta');
plot3(nan, nan, nan, '-', 'Color', colors.body, 'LineWidth', 2.5, 'DisplayName', 'body after roll \phi');
legend('Location', 'northwest');
grid on;
axis equal;
xlim([-0.3, 1.25]);
ylim([-0.3, 1.25]);
zlim([-0.3, 1.25]);
xlabel('North N');
ylabel('East E');
zlabel('Down D');
title(sprintf('NED to body: Z-Y-X sequence (yaw %.0f deg, pitch %.0f deg, roll %.0f deg)', ...
    rad2deg(psi), rad2deg(theta), rad2deg(phi)));
view(38, 24);
end

function draw_frame(R, color, labels)
for axisIndex = 1:3
    vector = R(:, axisIndex);
    quiver3(0, 0, 0, vector(1), vector(2), vector(3), 0, ...
        'Color', color, 'LineWidth', 2.2, 'MaxHeadSize', 0.17, ...
        'HandleVisibility', 'off');
    text(1.08 * vector(1), 1.08 * vector(2), 1.08 * vector(3), labels{axisIndex}, ...
        'Color', color, 'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center');
end
end

function draw_angle_arc(firstAxis, secondAxis, angle, color, labelText)
radius = 0.42;
samples = linspace(0, angle, 50);
arc = radius * (firstAxis * cos(samples) + secondAxis * sin(samples));
plot3(arc(1, :), arc(2, :), arc(3, :), 'Color', color, 'LineWidth', 1.8, ...
    'HandleVisibility', 'off');
labelPoint = arc(:, ceil(end / 2));
text(1.12 * labelPoint(1), 1.12 * labelPoint(2), 1.12 * labelPoint(3), labelText, ...
    'Color', color, 'FontSize', 15, 'FontWeight', 'bold');
end
