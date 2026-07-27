function fig = plot_ned_rotations(phi, theta, psi)
%PLOT_NED_ROTATIONS Visualize sequential roll, pitch, and yaw in NED.

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
frames = {rotations.initial, rotations.roll, rotations.rollPitch, rotations.full};
titles = {'Initial NED frame', ...
          sprintf('After roll phi = %.0f deg', rad2deg(phi)), ...
          sprintf('After roll + pitch theta = %.0f deg', rad2deg(theta)), ...
          sprintf('After roll + pitch + yaw psi = %.0f deg', rad2deg(psi))};

fig = figure('Name', 'NED sequential rotations', 'Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for k = 1:numel(frames)
    nexttile;
    plot_ned_frame(frames{k});
    title(titles{k});
end
end

function plot_ned_frame(R)
colors = [0.00, 0.45, 0.74; 0.85, 0.33, 0.10; 0.47, 0.67, 0.19];
labels = {'North / x', 'East / y', 'Down / z'};

hold on;
for axisIndex = 1:3
    vector = R(:, axisIndex);
    quiver3(0, 0, 0, vector(1), vector(2), vector(3), 0, ...
        'Color', colors(axisIndex, :), 'LineWidth', 2, 'MaxHeadSize', 0.25);
    text(1.1 * vector(1), 1.1 * vector(2), 1.1 * vector(3), labels{axisIndex}, ...
        'Color', colors(axisIndex, :), 'FontWeight', 'bold');
end
grid on;
axis equal;
xlim([-1.2, 1.2]);
ylim([-1.2, 1.2]);
zlim([-1.2, 1.2]);
xlabel('North [N]');
ylabel('East [E]');
zlabel('Down [D]');
view(38, 24);
end
