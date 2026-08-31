function result = run_task2_discretization_study()
%RUN_TASK2_DISCRETIZATION_STUDY Compare c2d methods, own ZOH and clock drift.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
resultsDir = fullfile(root,'results');
if ~isfolder(resultsDir), mkdir(resultsDir); end
model = tff_continuous_model();
frequencies = [10 100 1000]; duration = 5;
methods = ["zoh" "foh" "tustin" "custom_zoh"];
method = strings(0,1); frequency_hz = zeros(0,1); sample_time_s = zeros(0,1);
max_abs_error = zeros(0,1); rms_error = zeros(0,1); zoh_match_error = zeros(0,1);
plotData = struct('frequency',{},'time',{},'continuous',{},'responses',{});

for frequency = frequencies
    Ts = 1/frequency; time = (0:Ts:duration).'; input = ones(size(time));
    continuous = lsim(model.sys,input,time);
    responseSet = struct();
    zohReference = [];
    for methodName = methods
        if methodName == "custom_zoh"
            [Ad,Bd,Cd,Dd] = exact_zoh_discretize(model.A,model.B,model.C,model.D,Ts);
            response = simulate_discrete_ss(Ad,Bd,Cd,Dd,input,zeros(size(model.B)));
            zohMatch = max(abs(response-zohReference));
        else
            discrete = c2d(model.sys,Ts,char(methodName));
            response = lsim(discrete,input,time);
            if methodName == "zoh", zohReference = response; end
            zohMatch = 0;
        end
        errorVector = response-continuous;
        method(end+1,1) = methodName; %#ok<AGROW>
        frequency_hz(end+1,1) = frequency; sample_time_s(end+1,1) = Ts;
        max_abs_error(end+1,1) = max(abs(errorVector));
        rms_error(end+1,1) = sqrt(mean(errorVector.^2));
        zoh_match_error(end+1,1) = zohMatch;
        responseSet.(matlab.lang.makeValidName(char(methodName))) = response;
    end
    plotData(end+1) = struct('frequency',frequency,'time',time, ...
        'continuous',continuous,'responses',responseSet); %#ok<AGROW>
end
nominal = table(method,frequency_hz,sample_time_s,max_abs_error,rms_error,zoh_match_error);
writetable(nominal,fullfile(resultsDir,'task2_nominal_metrics.csv'));

nominal_frequency_hz = zeros(0,1); deviation = zeros(0,1); actual_frequency_hz = zeros(0,1);
clock_max_abs_error = zeros(0,1); clock_rms_error = zeros(0,1);
for frequency = frequencies
    TsNominal = 1/frequency;
    [Ad,Bd,Cd,Dd] = exact_zoh_discretize(model.A,model.B,model.C,model.D,TsNominal);
    for delta = [-0.1 0 0.1]
        actualFrequency = frequency*(1+delta);
        time = (0:1/actualFrequency:duration).'; input = ones(size(time));
        response = simulate_discrete_ss(Ad,Bd,Cd,Dd,input,zeros(size(model.B)));
        continuous = lsim(model.sys,input,time);
        errorVector = response-continuous;
        nominal_frequency_hz(end+1,1) = frequency; deviation(end+1,1) = delta;
        actual_frequency_hz(end+1,1) = actualFrequency;
        clock_max_abs_error(end+1,1) = max(abs(errorVector));
        clock_rms_error(end+1,1) = sqrt(mean(errorVector.^2));
    end
end
clock = table(nominal_frequency_hz,deviation,actual_frequency_hz, ...
    clock_max_abs_error,clock_rms_error);
writetable(clock,fullfile(resultsDir,'task2_clock_deviation_metrics.csv'));
save(fullfile(resultsDir,'task2_results.mat'),'model','nominal','clock','plotData');

fig = figure('Visible','off','Color','w'); tiledlayout(numel(frequencies),1,'TileSpacing','compact');
for i = 1:numel(plotData)
    nexttile; data = plotData(i);
    plot(data.time,data.continuous,'k-','LineWidth',1.2,'DisplayName','continuous'); hold on;
    plot(data.time,data.responses.zoh,'DisplayName','zoh');
    plot(data.time,data.responses.foh,'DisplayName','foh');
    plot(data.time,data.responses.tustin,'DisplayName','tustin');
    plot(data.time,data.responses.custom_zoh,'--','DisplayName','custom zoh');
    grid on; ylabel('y'); title(sprintf('Fs = %g Hz',data.frequency));
    if i == 1, legend('Location','best'); end
end
xlabel('t, s');
exportgraphics(fig,fullfile(resultsDir,'method_comparison.png'),'Resolution',180); close(fig);

fig = figure('Visible','off','Color','w');
tiledlayout(1,numel(frequencies),'TileSpacing','compact');
for frequency = frequencies
    nexttile; hold on;
    rows = clock.nominal_frequency_hz==frequency;
    plot(clock.deviation(rows)*100,clock.clock_max_abs_error(rows),'-o');
    grid on; xlabel('deviation, %'); ylabel('max |error|');
    title(sprintf('nominal %g Hz',frequency));
end
sgtitle('Fixed nominal ZOH coefficients under clock-frequency deviation');
exportgraphics(fig,fullfile(resultsDir,'clock_deviation.png'),'Resolution',180); close(fig);

fig = figure('Visible','off','Color','w');
ax = gca; ax.XScale = 'log'; ax.YScale = 'log'; hold on;
for methodName = ["foh" "tustin"]
    rows = nominal.method == methodName;
    loglog(nominal.frequency_hz(rows),nominal.max_abs_error(rows),'-o', ...
        'DisplayName',char(methodName));
end
grid on; xlabel('sampling frequency Fs, Hz'); ylabel('max |error|');
title('Discretization error versus sampling frequency'); legend('Location','best');
exportgraphics(fig,fullfile(resultsDir,'discretization_error_vs_fs.png'),'Resolution',180); close(fig);

fig = figure('Visible','off','Color','w'); tiledlayout(numel(frequencies),2,'TileSpacing','compact');
for i = 1:numel(frequencies)
    frequency = frequencies(i); Ts = 1/frequency;
    w = logspace(-1,log10(0.9*pi/Ts),500);
    continuousResponse = squeeze(freqresp(model.sys,w));
    nexttile; semilogx(w,20*log10(abs(continuousResponse)),'k-','LineWidth',1.1, ...
        'DisplayName','continuous'); hold on;
    nexttileIndex = 2*i;
    for methodName = ["zoh" "foh" "tustin"]
        discrete = c2d(model.sys,Ts,char(methodName));
        response = squeeze(freqresp(discrete,w));
        nexttile(2*i-1); semilogx(w,20*log10(abs(response)),'DisplayName',char(methodName));
        nexttile(nexttileIndex); semilogx(w,unwrap(angle(response))*180/pi,'DisplayName',char(methodName)); hold on;
    end
    nexttile(2*i-1); grid on; ylabel(sprintf('|T(jw)|, dB\nFs=%g Hz',frequency),'Interpreter','none');
    title('Magnitude'); if i == 1, legend('Location','best'); end
    nexttile(nexttileIndex); semilogx(w,unwrap(angle(continuousResponse))*180/pi,'k-','LineWidth',1.1, ...
        'DisplayName','continuous'); grid on; ylabel('phase, deg'); title('Phase');
    if i == 1, legend('Location','best'); end
end
xlabel('angular frequency w, rad/s');
exportgraphics(fig,fullfile(resultsDir,'frequency_response_comparison.png'),'Resolution',180); close(fig);

result = struct('nominal',nominal,'clock',clock);
end
