function record=export_physical_artifacts()
%EXPORT_PHYSICAL_ARTIFACTS Measured three-model and physical-controller evidence.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
p=motor_params(); m=motor_models(p); K=load_optimized_gains();
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
ids={'simscape_zero','simscape_step','simscape_load'}; voltages=[0,12,12]; loads=[0,0,.05]; ends=[1,30,30];
errors=zeros(3,6);
for j=1:3
    s=struct('id',ids{j},'voltage',voltages(j),'loadTorque',loads(j),'loadTime',1,'x0',[0;0],'tEnd',ends(j),'outputStep',.001);
    equations=run_plant_comparison(p,s); physical=run_simscape_comparison(p,s);
    errors(j,:)=[equations.maxSpeedError,physical.maxSpeedError,equations.maxCurrentError,physical.maxCurrentError];
    values=[physical.time,physical.reference,equations.traces{1},equations.traces{2},physical.physical];
    writetable(array2table(values,'VariableNames',{'time_s','omega_reference','current_reference', ...
        'omega_diffeq','current_diffeq','omega_statespace','current_statespace','omega_simscape','current_simscape'}), ...
        fullfile(csvDir,[ids{j} '.csv']));
    if j==3, lastPlant=physical; end
end
plant=table(string(ids)',errors(:,1),errors(:,2),errors(:,3),errors(:,4),errors(:,5),errors(:,6), ...
    'VariableNames',{'scenario','max_speed_error_diffeq','max_speed_error_statespace','max_speed_error_simscape', ...
    'max_current_error_diffeq','max_current_error_statespace','max_current_error_simscape'});
writetable(plant,fullfile(csvDir,'simscape_comparison.csv'));
controllers={K,design_compensator(p,m,.01,.7),design_compensator(p,m,20,.7)};
names={'PID','lag','lead'}; runs=cell(3,1); metrics=cell(3,1); closedErrors=zeros(3,3);
for j=1:3
    comparison=run_physical_controller_comparison(p,controllers{j},struct('Tend',12));
    runs{j}=comparison.physical; metrics{j}=comparison.physicalMetrics; closedErrors(j,:)=comparison.maxErrors;
    saveTrace(csvDir,['physical_' names{j}],comparison);
end
get=@(field) cellfun(@(M) M.(field),metrics);
closed=table(string(names)',get('ts'),get('os'),get('ess'),get('essValidated'),get('iae'),get('effort'), ...
    closedErrors(:,1),closedErrors(:,2),closedErrors(:,3), ...
    'VariableNames',{'controller','settling_s','overshoot_pct','tail_error_rad_s','tail_equilibrium_validated','IAE_rad','effort_Vs', ...
    'max_speed_error','max_current_error','max_voltage_error'});
writetable(closed,fullfile(csvDir,'compensator_comparison.csv'));
required=run_physical_controller_comparison(p,K,struct('Tend',6,'TL_step',.05,'TL_time',1));
saveTrace(csvDir,'physical_PID_required_load',required);
% Deliverable PID model is the documented nominal 12-second comparison.
[mdl,~]=build_compensated_model(p,K,struct('Tend',12)); close_system(mdl,0);
f=figure('Visible','off','Position',[100,100,1000,750]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1); nexttile;
plot(lastPlant.time,lastPlant.reference(:,1),'--',lastPlant.time,lastPlant.physical(:,1),'LineWidth',1.4); grid on;
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); legend('Рівняння','Simscape','Location','southeast');
title('Фізичний ДПС: 12 В та протидіючий момент 0,05 Н·м при t = 1 с');
nexttile; plot(lastPlant.time,lastPlant.reference(:,2),'--',lastPlant.time,lastPlant.physical(:,2),'LineWidth',1.4); grid on;
xlabel('Час, с'); ylabel('Струм, А'); legend('Рівняння','Simscape');
exportgraphics(f,fullfile(figDir,'simscape_open_loop_comparison.png'),'Resolution',180); clear cleanup
f=figure('Visible','off','Position',[100,100,1000,750]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1); nexttile; hold on;
for j=1:3, plot(runs{j}.t,runs{j}.w,'LineWidth',1.4); end
yline(100,'--','HandleVisibility','off'); yline(98,':','HandleVisibility','off'); grid on;
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); legend('ПІД','Lag','Lead','Location','southeast');
title('ПІД, lag та lead на фізичній Simscape-моделі');
nexttile; hold on; for j=1:3, plot(runs{j}.t,runs{j}.u,'LineWidth',1.4); end
grid on; xlabel('Час, с'); ylabel('Напруга, В'); legend('ПІД','Lag','Lead');
exportgraphics(f,fullfile(figDir,'simscape_controller_comparison.png'),'Resolution',180); clear cleanup
models={'dc_motor_simscape','dc_motor_pid_simscape','dc_motor_lag_simscape','dc_motor_lead_simscape'};
for j=1:numel(models)
    load_system(fullfile(root,'matlab','models',[models{j} '.slx']));
    print(['-s' models{j}],'-dpng',fullfile(figDir,[models{j} '_diagram.png']),'-r180');
    if j==1, print(['-s' models{j} '/Motor Model Subsystem'],'-dpng',fullfile(figDir,'dc_motor_simscape_subsystem.png'),'-r180'); end
    close_system(models{j},0);
end
record=struct('physicalValidated',true,'plantMaximumErrors',max(errors,[],1),'controllerMaximumErrors',max(closedErrors,[],1), ...
    'requiredLoadMaximumErrors',required.maxErrors,'requiredLoadMetrics',required.physicalMetrics,'horizon',12);
fid=fopen(fullfile(root,'results','json','simscape.json'),'w','n','UTF-8'); fileCleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(record,PrettyPrint=true)); disp(plant); disp(closed);
end

function saveTrace(folder,name,r)
out=r.physical; ref=r.reference;
writetable(table(out.t,out.w,out.i,out.u,ref.w,ref.i,ref.u,'VariableNames', ...
    {'time_s','omega_rad_s','current_A','voltage_V','omega_reference','current_reference','voltage_reference'}),fullfile(folder,[name '.csv']));
end
