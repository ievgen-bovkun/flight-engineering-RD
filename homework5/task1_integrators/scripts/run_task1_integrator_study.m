function summary = run_task1_integrator_study()
%RUN_TASK1_INTEGRATOR_STUDY Generate required RK4/RKF45 numerical evidence.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
resultsDir = fullfile(root,'results');
if ~isfolder(resultsDir), mkdir(resultsDir); end

frequencies = [10 100 1000 10000];
samplesPerPeriod = [10 20 40 80];
tolerances = [1e-4 1e-7];
method = strings(0,1); frequency_hz = zeros(0,1); h = zeros(0,1);
tolerance = zeros(0,1); max_abs_error = zeros(0,1); rms_error = zeros(0,1);
accepted_steps = zeros(0,1); rejected_steps = zeros(0,1);
rkfHistories = struct('frequency_hz',{},'tolerance',{},'stats',{});
overlay = struct();

for frequency = frequencies
    period = 1/frequency;
    finalTime = 10*period;
    rhs = @(t,~) 2*pi*frequency*cos(2*pi*frequency*t);
    for spp = samplesPerPeriod
        step = period/spp;
        [T,Y] = rk4_integrate(rhs,[0 finalTime],0,step);
        errorVector = Y(:,1)-sin(2*pi*frequency*T);
        method(end+1,1) = "RK4"; %#ok<AGROW>
        frequency_hz(end+1,1) = frequency; h(end+1,1) = step;
        tolerance(end+1,1) = NaN; max_abs_error(end+1,1) = max(abs(errorVector));
        rms_error(end+1,1) = sqrt(mean(errorVector.^2));
        accepted_steps(end+1,1) = numel(T)-1; rejected_steps(end+1,1) = 0;
        if frequency == 10000 && spp == 80
            overlay.rk4T = T; overlay.rk4Y = Y(:,1);
        end
    end
    for tol = tolerances
        opts = struct('h0',period/4,'tolerance',tol, ...
            'hMin',period/1e6,'hMax',period/2);
        [T,Y,stats] = rkf45_integrate(rhs,[0 finalTime],0,opts);
        errorVector = Y(:,1)-sin(2*pi*frequency*T);
        method(end+1,1) = "RKF45"; %#ok<AGROW>
        frequency_hz(end+1,1) = frequency;
        acceptedH = stats.trialStepSizes(stats.trialAccepted);
        h(end+1,1) = mean(acceptedH); tolerance(end+1,1) = tol;
        max_abs_error(end+1,1) = max(abs(errorVector));
        rms_error(end+1,1) = sqrt(mean(errorVector.^2));
        accepted_steps(end+1,1) = stats.acceptedSteps;
        rejected_steps(end+1,1) = stats.rejectedSteps;
        rkfHistories(end+1) = struct('frequency_hz',frequency, ...
            'tolerance',tol,'stats',stats); %#ok<AGROW>
        if frequency == 10000 && tol == 1e-7
            overlay.rkfT = T; overlay.rkfY = Y(:,1); overlay.rkfStats = stats;
        end
    end
end

summary = table(method,frequency_hz,h,tolerance,max_abs_error,rms_error, ...
    accepted_steps,rejected_steps);
writetable(summary,fullfile(resultsDir,'task1_metrics.csv'));
save(fullfile(resultsDir,'task1_results.mat'),'summary','rkfHistories');

fig = figure('Visible','off','Color','w');
ax = gca;
ax.XScale = 'log';
ax.YScale = 'log';
hold on;
for frequency = frequencies
    rows = summary.method=="RK4" & summary.frequency_hz==frequency;
    loglog(summary.h(rows),summary.max_abs_error(rows),'-o', ...
        'DisplayName',sprintf('%g Hz',frequency));
end
grid on; xlabel('h, s'); ylabel('max |error|');
title('RK4: dependence of error on fixed step'); legend('Location','best');
exportgraphics(fig,fullfile(resultsDir,'rk4_error_vs_step.png'),'Resolution',180); close(fig);

fig = figure('Visible','off','Color','w');
stats = overlay.rkfStats;
accepted = stats.trialAccepted;
stairs(stats.trialTimes(accepted),stats.trialStepSizes(accepted),'b.-','DisplayName','accepted'); hold on;
if any(~accepted)
    plot(stats.trialTimes(~accepted),stats.trialStepSizes(~accepted),'rx','DisplayName','rejected');
end
grid on; xlabel('t, s'); ylabel('trial h, s');
title('RKF45 step history: 10000 Hz, tolerance 10^{-7}'); legend('Location','best');
exportgraphics(fig,fullfile(resultsDir,'rkf45_step_history.png'),'Resolution',180); close(fig);

rkfRows = summary.method == "RKF45";
tolLevels = unique(summary.tolerance(rkfRows));
meanError = zeros(size(tolLevels)); meanAccepted = zeros(size(tolLevels));
meanRejected = zeros(size(tolLevels));
for i = 1:numel(tolLevels)
    rows = rkfRows & summary.tolerance == tolLevels(i);
    meanError(i) = mean(summary.max_abs_error(rows));
    meanAccepted(i) = mean(summary.accepted_steps(rows));
    meanRejected(i) = mean(summary.rejected_steps(rows));
end
fig = figure('Visible','off','Color','w'); tiledlayout(1,2,'TileSpacing','compact');
nexttile; loglog(tolLevels,meanError,'o-','LineWidth',1.2); grid on;
xlabel('tolerance'); ylabel('mean max |error|'); title('RKF45 achieved accuracy');
nexttile; labels = categorical(compose('%.0e',tolLevels));
bar(labels,[meanAccepted meanRejected]); grid on;
xlabel('tolerance'); ylabel('mean number of trials');
legend('accepted','rejected','Location','best'); title('RKF45 computational effort');
exportgraphics(fig,fullfile(resultsDir,'rkf45_accuracy_effort.png'),'Resolution',180); close(fig);

period = 1/10000; visibleTime = 2*period;
fig = figure('Visible','off','Color','w');
tExact = linspace(0,visibleTime,1000).';
plot(tExact,sin(2*pi*10000*tExact),'k-','LineWidth',1.2,'DisplayName','exact'); hold on;
rows = overlay.rk4T <= visibleTime+eps;
plot(overlay.rk4T(rows),overlay.rk4Y(rows),'bo','DisplayName','RK4, 80 samples/period');
rows = overlay.rkfT <= visibleTime+eps;
plot(overlay.rkfT(rows),overlay.rkfY(rows),'r.','DisplayName','RKF45, tolerance 10^{-7}');
grid on; xlabel('t, s'); ylabel('y'); title('Methods against exact 10000 Hz sine'); legend('Location','best');
exportgraphics(fig,fullfile(resultsDir,'method_overlay_10000hz.png'),'Resolution',180); close(fig);
end
