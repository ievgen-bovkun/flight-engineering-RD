function figureHandle = plot_simulink_results(out)
%PLOT_SIMULINK_RESULTS Create report-ready plots from one Simulink run.

figureHandle = figure('Name', "Simulink response: " + out.channel, 'Color', 'w');

subplot(2,2,1);
plot(out.position.Time, out.position.Data, 'LineWidth', 1.2); grid on;
xlabel('Time [s]'); ylabel('Position [m]');
legend('x', 'y', 'z (NED)', 'Location', 'best'); title('Position');

subplot(2,2,2);
plot(out.velocity.Time, out.velocity.Data, 'LineWidth', 1.2); grid on;
xlabel('Time [s]'); ylabel('Velocity [m/s]');
legend('u', 'v', 'w', 'Location', 'best'); title('Body velocity');

subplot(2,2,3);
plot(out.angles.Time, rad2deg(out.angles.Data), 'LineWidth', 1.2); grid on;
xlabel('Time [s]'); ylabel('Angle [deg]');
legend('\phi roll', '\theta pitch', '\psi yaw', 'Location', 'best'); title('Euler angles');

subplot(2,2,4);
plot(out.angularRates.Time, rad2deg(out.angularRates.Data), 'LineWidth', 1.2); grid on;
xlabel('Time [s]'); ylabel('Angular rate [deg/s]');
legend('p', 'q', 'r', 'Location', 'best'); title('Angular rates');

sgtitle("Unit motor-command step, channel: " + out.channel);
end
