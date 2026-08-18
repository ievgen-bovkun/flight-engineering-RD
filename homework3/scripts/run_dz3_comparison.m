function result = run_dz3_comparison()
%RUN_DZ3_COMPARISON Compare custom NED equations with Aerospace 6DOF EA.
% Input loads are total body-axis force/moment, so gravity must already be
% included when a vehicle-specific test needs it.

rootDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(rootDir, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end
model = build_dz3_6dof_model();
load_system(model);
cleanup = onCleanup(@() close_system(model, 0)); %#ok<NASGU>

dt = 0.001;
stopTime = 4;
t = (0:dt:stopTime).';
stepMask = t >= 1;
scenarios = [ ...
    struct('name', 'surge_force', 'force', [1 0 0], 'moment', [0 0 0]); ...
    struct('name', 'sway_force', 'force', [0 1 0], 'moment', [0 0 0]); ...
    struct('name', 'heave_force', 'force', [0 0 1], 'moment', [0 0 0]); ...
    struct('name', 'roll_moment', 'force', [0 0 0], 'moment', [0.002 0 0]); ...
    struct('name', 'pitch_moment', 'force', [0 0 0], 'moment', [0 0.002 0]); ...
    struct('name', 'yaw_moment', 'force', [0 0 0], 'moment', [0 0 0.002]); ...
    struct('name', 'combined_6dof', 'force', [0.6 -0.3 0.2], 'moment', [0.002 -0.001 0.0008])];
hw1Channels = {'vertical','roll','pitch','yaw'};

summary = table('Size', [numel(scenarios)+numel(hw1Channels) 4], ...
    'VariableTypes', {'string','string','double','double'}, ...
    'VariableNames', {'test_family','scenario','max_state_error','final_position_error_m'});
allScenarios = cell(height(summary), 1);
for k = 1:numel(scenarios)
    forceData = zeros(numel(t), 3);
    momentData = zeros(numel(t), 3);
    forceData(stepMask, :) = repmat(scenarios(k).force, nnz(stepMask), 1);
    momentData(stepMask, :) = repmat(scenarios(k).moment, nnz(stepMask), 1);
    data = simulate_case(model, t, forceData, momentData);
    allScenarios{k} = data;
    summary.test_family(k) = "canonical_force_moment";
    summary.scenario(k) = string(scenarios(k).name);
    summary.max_state_error(k) = max_common_error(data);
    summary.final_position_error_m(k) = norm(final_sample(data.custom.Xe) - final_sample(data.aero.Xe));
end

% Same raw unit-step motor commands as Homework 1. The original HW1 plant
% supplies total body loads (thrust, gravity and rotor gyroscopic torque).
% Those identical load histories are then supplied to both 6DOF branches.
for k = 1:numel(hw1Channels)
    row = numel(scenarios) + k;
    [forceData, momentData] = hw1_motor_load_history(t, hw1Channels{k});
    data = simulate_case(model, t, forceData, momentData);
    allScenarios{row} = data;
    summary.test_family(row) = "HW1_motor_step";
    summary.scenario(row) = string(hw1Channels{k});
    summary.max_state_error(row) = max_common_error(data);
    summary.final_position_error_m(row) = norm(final_sample(data.custom.Xe) - final_sample(data.aero.Xe));
end

% Lecture-based Laplace check: F(s)=F0/s, X(s)=F0/(m*s^3),
% hence x_N(t)=F0*t^2/(2m) for x_N(0)=v_N(0)=0.
laplaceTime = (0:dt:2).';
laplaceData = simulate_case(model, laplaceTime, ...
    repmat([1 0 0], numel(laplaceTime), 1), zeros(numel(laplaceTime), 3));
expectedNorth = laplaceTime.^2/(2*1.3211359852721711);
laplaceCustomXe = as_time_rows(laplaceData.custom.Xe);
laplaceAeroXe = as_time_rows(laplaceData.aero.Xe);
laplace = struct('time_s', laplaceTime, 'expected_north_m', expectedNorth, ...
    'max_position_error_m', max(abs(laplaceCustomXe(:,1) - expectedNorth)), ...
    'aerospace_max_position_error_m', max(abs(laplaceAeroXe(:,1) - expectedNorth)));

writetable(summary, fullfile(resultsDir, 'comparison_summary.csv'));
save(fullfile(resultsDir, 'comparison_results.mat'), 'summary', 'allScenarios', 'laplace');
write_figures(allScenarios, laplaceData, laplace, resultsDir);
result = struct('summary', summary, 'scenarios', {allScenarios}, 'laplace', laplace);
end

function data = simulate_case(model, t, forceData, momentData)
assignin('base', 'forces_ts', timeseries(forceData, t));
assignin('base', 'moments_ts', timeseries(momentData, t));
out = sim(model, 'StopTime', num2str(t(end)), 'ReturnWorkspaceOutputs', 'on');
names = {'Ve','Xe','Euler','DCM','Vb','pqr','pqr_dot'};
data = struct('custom', struct(), 'aero', struct());
for k = 1:numel(names)
    data.custom.(names{k}) = out.get(['custom_' names{k}]);
    data.aero.(names{k}) = out.get(['aero_' names{k}]);
end
data.custom.Ab = out.get('custom_Ab');
end

function [forceData, momentData] = hw1_motor_load_history(t, channel)
homework3Dir = fileparts(fileparts(mfilename('fullpath')));
hw1SimulinkDir = fullfile(fileparts(homework3Dir), 'homework1', 'simulink');
if ~isfolder(hw1SimulinkDir)
    hw1SimulinkDir = 'C:/Users/ievge/MatLabProjects/task1/homework1/simulink';
end
if ~isfolder(hw1SimulinkDir)
    error('DZ3:HW1NotFound', 'Homework 1 Simulink sources were not found.');
end
addpath(hw1SimulinkDir);
P = quadrotor_params();
mixes = struct('vertical', [1;1;1;1], 'roll', [0;1;0;-1], ...
    'pitch', [1;0;-1;0], 'yaw', [-1;1;-1;1]);
mix = mixes.(channel);
x0 = zeros(16, 1);
x0(3) = -10;
x0(13:16) = P.Omega0;
inputAtTime = @(time) double(time >= P.step_time)*mix;
options = odeset('RelTol', 1e-9, 'AbsTol', 1e-11, 'MaxStep', 0.001);
solution = ode45(@(time, state) quadrotor_core(inputAtTime(time), state, P), [t(1) t(end)], x0, options);
state = deval(solution, t).';

forceData = zeros(numel(t), 3);
momentData = zeros(numel(t), 3);
for n = 1:numel(t)
    phi = state(n,7); theta = state(n,8); psi = state(n,9);
    p = state(n,10); q = state(n,11);
    omega = state(n,13:16).';
    DCMbe = dcm_be(phi, theta, psi);
    thrust = P.b*sum(omega.^2);
    mx = P.l*P.b*(omega(2)^2 - omega(4)^2);
    my = P.l*P.b*(omega(1)^2 - omega(3)^2);
    mz = P.d*(omega(2)^2 + omega(4)^2 - omega(1)^2 - omega(3)^2);
    hz = P.Ip*(omega(1) - omega(2) + omega(3) - omega(4));
    forceData(n,:) = (P.m*DCMbe*[0;0;P.g] + [0;0;-thrust]).';
    momentData(n,:) = [mx-hz*q, my+hz*p, mz];
end
end

function DCMbe = dcm_be(phi, theta, psi)
cphi = cos(phi); sphi = sin(phi); ctheta = cos(theta); stheta = sin(theta);
cpsi = cos(psi); spsi = sin(psi);
DCMbe = [ctheta*cpsi, ctheta*spsi, -stheta; ...
    sphi*stheta*cpsi-cphi*spsi, sphi*stheta*spsi+cphi*cpsi, sphi*ctheta; ...
    cphi*stheta*cpsi+sphi*spsi, cphi*stheta*spsi-sphi*cpsi, cphi*ctheta];
end

function value = max_common_error(data)
names = {'Ve','Xe','Euler','DCM','Vb','pqr','pqr_dot'};
value = 0;
for k = 1:numel(names)
    customData = as_time_rows(data.custom.(names{k}));
    aeroData = as_time_rows(data.aero.(names{k}));
    value = max(value, max(abs(customData(:) - aeroData(:))));
end
end

function value = final_sample(signal)
data = as_time_rows(signal);
value = data(end,:).';
end

function data = as_time_rows(signal)
data = signal.Data;
numberOfSamples = numel(signal.Time);
if ismatrix(data) && size(data,1) == numberOfSamples
    return
end
if size(data, ndims(data)) ~= numberOfSamples
    error('DZ3:UnexpectedSignalShape', 'Time dimension was not found in a logged signal.');
end
order = [ndims(data), 1:ndims(data)-1];
data = reshape(permute(data, order), numberOfSamples, []);
end

function write_figures(allScenarios, laplaceData, laplace, resultsDir)
combined = allScenarios{7};
customXe = as_time_rows(combined.custom.Xe);
aeroXe = as_time_rows(combined.aero.Xe);
laplaceCustomXe = as_time_rows(laplaceData.custom.Xe);
laplaceAeroXe = as_time_rows(laplaceData.aero.Xe);

figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 620]);
subplot(2,1,1);
plot(combined.custom.Xe.Time, customXe, 'LineWidth', 1.4); hold on;
plot(combined.aero.Xe.Time, aeroXe, '--', 'LineWidth', 1.0); grid on;
xlabel('Time, s'); ylabel('NED position, m');
title('Combined 6DOF: custom (solid) and Aerospace (dashed)');
legend('N custom','E custom','D custom','N Aerospace','E Aerospace','D Aerospace', ...
    'Location', 'best');

subplot(2,1,2);
plot(laplace.time_s, laplace.expected_north_m, 'k:', 'LineWidth', 2); hold on;
plot(laplaceData.custom.Xe.Time, laplaceCustomXe(:,1), 'b-', 'LineWidth', 1.3);
plot(laplaceData.aero.Xe.Time, laplaceAeroXe(:,1), 'r--', 'LineWidth', 1.1); grid on;
xlabel('Time, s'); ylabel('North position, m');
title('Laplace check: x(t)=F_0t^2/(2m)');
legend('Analytic','Custom NED','Aerospace','Location','northwest');
exportgraphics(figureHandle, fullfile(resultsDir, 'comparison_and_laplace.png'), 'Resolution', 180);
close(figureHandle);

write_hw1_overlay_figures(allScenarios, resultsDir);
end

function write_hw1_overlay_figures(allScenarios, resultsDir)
scenarioNames = {'vertical', 'roll', 'pitch', 'yaw'};
scenarioRows = 8:11;
for k = 1:numel(scenarioNames)
    data = allScenarios{scenarioRows(k)};
    figureHandle = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 620]);
    layout = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    if strcmp(scenarioNames{k}, 'vertical')
        customPosition = as_time_rows(data.custom.Xe);
        aeroPosition = as_time_rows(data.aero.Xe);
        axesHandle = nexttile(layout);
        plot_overlay(axesHandle, data.custom.Xe.Time, customPosition(:,3), ...
            data.aero.Xe.Time, aeroPosition(:,3), 'z_D, m', ...
            'Vertical motor step: Down position');

        customEuler = rad2deg(as_time_rows(data.custom.Euler));
        aeroEuler = rad2deg(as_time_rows(data.aero.Euler));
        axesHandle = nexttile(layout);
        plot_vector_overlay(axesHandle, data.custom.Euler.Time, customEuler, ...
            data.aero.Euler.Time, aeroEuler, 'Euler angles, deg', ...
            'Attitude cross-coupling check');
    else
        component = k - 1;
        angleLabels = {'phi', 'theta', 'psi'};
        rateLabels = {'p', 'q', 'r'};
        customEuler = rad2deg(as_time_rows(data.custom.Euler));
        aeroEuler = rad2deg(as_time_rows(data.aero.Euler));
        customRates = rad2deg(as_time_rows(data.custom.pqr));
        aeroRates = rad2deg(as_time_rows(data.aero.pqr));

        axesHandle = nexttile(layout);
        plot_overlay(axesHandle, data.custom.Euler.Time, customEuler(:,component), ...
            data.aero.Euler.Time, aeroEuler(:,component), ...
            [angleLabels{component} ', deg'], ...
            [upper_first(scenarioNames{k}) ' motor step: Euler angle']);

        axesHandle = nexttile(layout);
        plot_overlay(axesHandle, data.custom.pqr.Time, customRates(:,component), ...
            data.aero.pqr.Time, aeroRates(:,component), ...
            [rateLabels{component} ', deg/s'], 'Body-axis angular rate');
        if strcmp(scenarioNames{k}, 'pitch')
            title(layout, ['Pitch comparison (Euler 3-2-1): near +/-90 deg use DCM ' ...
                'to confirm physical attitude'], 'FontWeight', 'bold');
        end
    end

    exportgraphics(figureHandle, fullfile(resultsDir, ...
        [scenarioNames{k} '_overlay.png']), 'Resolution', 180);
    close(figureHandle);
end
end

function plot_overlay(axesHandle, customTime, customData, aeroTime, aeroData, yLabel, plotTitle)
plot(axesHandle, customTime, customData, 'b-', 'LineWidth', 1.6); hold(axesHandle, 'on');
plot(axesHandle, aeroTime, aeroData, 'r--', 'LineWidth', 1.2);
grid(axesHandle, 'on');
xlabel(axesHandle, 'Time, s'); ylabel(axesHandle, yLabel);
title(axesHandle, plotTitle);
legend(axesHandle, 'Custom NED', 'Aerospace', 'Location', 'best');
end

function plot_vector_overlay(axesHandle, customTime, customData, aeroTime, aeroData, yLabel, plotTitle)
colors = lines(3);
hold(axesHandle, 'on');
for component = 1:3
    plot(axesHandle, customTime, customData(:,component), '-', ...
        'Color', colors(component,:), 'LineWidth', 1.5);
end
for component = 1:3
    plot(axesHandle, aeroTime, aeroData(:,component), '--', ...
        'Color', colors(component,:), 'LineWidth', 1.1);
end
grid(axesHandle, 'on');
xlabel(axesHandle, 'Time, s'); ylabel(axesHandle, yLabel);
title(axesHandle, plotTitle);
legend(axesHandle, 'phi custom', 'theta custom', 'psi custom', ...
    'phi Aerospace', 'theta Aerospace', 'psi Aerospace', 'Location', 'best');
end

function textValue = upper_first(textValue)
textValue(1) = upper(textValue(1));
end
