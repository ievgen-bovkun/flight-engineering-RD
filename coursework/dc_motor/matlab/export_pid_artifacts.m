function summary=export_pid_artifacts()
%EXPORT_PID_ARTIFACTS Measured baseline results; no optimization claim.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
p=motor_params(); m=motor_models(p);
Kzn=tune_ziegler_nichols(p,m); Kpp=tune_pole_placement(p,m,1,5,20);
gains=[Kzn;Kpp;11.0456,21.89,1.3288];
ids={'ziegler_nichols','pole_placement','buddy_baseline'};
labels={'Зіглер–Нікольс','Розміщення полюсів','Коефіцієнти колеги'};
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
outs=cell(3,1); metrics=cell(3,1); errors=zeros(3,3);
for k=1:3
    r=run_pid_comparison(p,gains(k,:),struct()); out=r.reference;
    outs{k}=out; metrics{k}=performance_metrics(out); errors(k,:)=max(r.maxErrors,[],1);
    T=table(out.t,out.w,out.i,out.u,out.e,out.TL,'VariableNames', ...
        {'time_s','omega_rad_s','current_A','voltage_V','error_rad_s','load_Nm'});
    writetable(T,fullfile(csvDir,['pid_' ids{k} '.csv']));
end
get=@(field) cellfun(@(x) x.(field),metrics);
summary=table(ids',gains(:,1),gains(:,2),gains(:,3),get('ts'),get('t_first'),get('os'),get('ess'), ...
    get('essValidated'),get('iae'),get('effort'),get('effort2'),errors(:,1),errors(:,2),errors(:,3), ...
    'VariableNames',{'controller','Kp','Ki','Kd','settling_s','first_entry_s','overshoot_pct','tail_error_rad_s', ...
    'tail_equilibrium_validated','IAE_rad','effort_Vs','effort_V2s','max_speed_error','max_current_error','max_voltage_error'});
writetable(summary,fullfile(csvDir,'pid_baseline_summary.csv'));
f=figure('Visible','off','Position',[100,100,1000,720]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1);
nexttile; hold on; grid on;
for k=1:3, plot(outs{k}.t,outs{k}.w,'LineWidth',1.5,'DisplayName',labels{k}); end
yline(100,'k--','Уставка','HandleVisibility','off');
yline(98,'k:','HandleVisibility','off'); yline(102,'k:','HandleVisibility','off');
xline(2,'k:','Вимога 2 с','HandleVisibility','off');
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); title('ПІД: відтворення базових налаштувань'); legend('Location','southeast');
nexttile; hold on; grid on;
for k=1:3, plot(outs{k}.t,outs{k}.u,'LineWidth',1.5,'DisplayName',labels{k}); end
xlabel('Час, с'); ylabel('Напруга якоря, В'); legend('Location','northeast');
exportgraphics(f,fullfile(figDir,'pid_baselines.png'),'Resolution',180); clear cleanup
capability=check_feasibility(p,m,[24,48]);
writeJson(fullfile(root,'results','json','pid_baselines.json'), ...
    struct('kind','baseline_not_new_optimization','gains',gains,'metrics',{metrics}, ...
    'maximumComparisonErrors',errors,'voltageFeasibility',capability));
names={'dc_motor_pid_diffeq','dc_motor_pid_statespace'};
for k=1:2
    load_system(fullfile(root,'matlab','models',[names{k} '.slx']));
    cleanup=onCleanup(@() close_system(names{k},0));
    print(['-s' names{k}],'-dpng',fullfile(figDir,[names{k} '_diagram.png']),'-r180');
    clear cleanup
end
disp(summary);
end

function writeJson(file,value)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'Cannot write PID evidence');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
