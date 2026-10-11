function summary=run_disturbance_study()
%RUN_DISTURBANCE_STUDY Required load, post-settling loads and observer benefit.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
set(groot,'defaultFigureVisible','off'); p=motor_params(); K=load_optimized_gains();
obs=design_observer(p,[-30,-35,-40]); loads=[.05,.05,.5,1.5]; times=[1,3,3,3];
records=struct('scenario',{},'controller',{},'metrics',{},'recovery',{}); runs=cell(4,2);
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
for s=1:4
    for v=1:2
        opt=struct('Tend',6,'TL_step',loads(s),'TL_time',times(s));
        controller='PID';
        if v==2, opt.obs=obs.L; opt.ff=true; controller='PID_observer'; end
        clean=opt; clean.TL_step=0;
        out=simulate_disturbance(p,K,opt); baseline=simulate_disturbance(p,K,clean);
        runs{s,v}=out; recovery=disturbance_recovery(out.t,baseline.w-out.w,times(s),2);
        metric=performance_metrics(out);
        records(end+1)=struct('scenario',s,'controller',controller,'metrics',metric,'recovery',recovery);
        T=table(out.t,out.w,out.i,out.u,out.TL,'VariableNames', ...
            {'time_s','omega_rad_s','current_A','voltage_V','load_Nm'});
        if v==2, T.estimated_load_Nm=out.TL_hat; end
        writetable(T,fullfile(csvDir,sprintf('disturbance_%d_%s.csv',s,controller)));
    end
end
get=@(field) arrayfun(@(r) r.metrics.(field),records)';
summary=table([records.scenario]',string({records.controller})',get('ts'),get('os'),get('ess'), ...
    arrayfun(@(r) r.recovery.dip,records)',arrayfun(@(r) r.recovery.recoveryTime,records)', ...
    arrayfun(@(r) r.recovery.additionalIAE,records)', ...
    'VariableNames',{'scenario','controller','settling_s','overshoot_pct','tail_error_rad_s','trajectory_dip_rad_s','recovery_s','additional_IAE_rad'});
writetable(summary,fullfile(csvDir,'disturbance_summary.csv'));
f=figure('Visible','off','Position',[100,100,1000,720]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1); nexttile;
plot(runs{1,1}.t,runs{1,1}.w,runs{1,2}.t,runs{1,2}.w,'LineWidth',1.5); grid on;
xline(1,'k:','Збурення','HandleVisibility','off'); yline(100,'k:','HandleVisibility','off');
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); title('Необхідний сценарій: 0,05 Н·м при t = 1 с');
legend('ПІД','ПІД зі спостерігачем','Location','southeast');
nexttile; plot(runs{1,1}.t,runs{1,1}.u,runs{1,2}.t,runs{1,2}.u,'LineWidth',1.5); grid on;
xlabel('Час, с'); ylabel('Напруга, В'); legend('ПІД','ПІД зі спостерігачем');
exportgraphics(f,fullfile(figDir,'required_disturbance.png'),'Resolution',180); clear cleanup
f=figure('Visible','off','Position',[100,100,1000,850]); cleanup=onCleanup(@() close(f));
tiledlayout(3,1); nexttile;
plot(runs{3,1}.t,runs{3,1}.w,runs{3,2}.t,runs{3,2}.w,'LineWidth',1.5); xlim([2.8,4.5]); grid on;
ylabel('Швидкість, рад/с'); legend('ПІД','ПІД зі спостерігачем'); title('Збурення 0,5 Н·м після розгону');
nexttile; plot(runs{3,1}.t,runs{3,1}.u,runs{3,2}.t,runs{3,2}.u,'LineWidth',1.5); xlim([2.8,4.5]); grid on;
ylabel('Напруга, В');
nexttile; plot(runs{3,2}.t,runs{3,2}.TL,'--',runs{3,2}.t,runs{3,2}.TL_hat,'LineWidth',1.5); xlim([2.8,4.5]); grid on;
xlabel('Час, с'); ylabel('Момент, Н·м'); legend('Істинний момент','Оцінка');
exportgraphics(f,fullfile(figDir,'observer_disturbance.png'),'Resolution',180); clear cleanup
live=live_visualization(p,K,struct('Tend',.5,'visible',false,'realTime',false));
record=struct('gains',K,'observer',obs,'scenarios',records,'liveUpdates',live.updateCount);
fid=fopen(fullfile(root,'results','json','disturbance.json'),'w','n','UTF-8');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(record,PrettyPrint=true));
disp(summary);
end
