function summary=run_compensator_study()
%RUN_COMPENSATOR_STUDY Fair 12 s reference study; physical comparison pending.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
p=motor_params(); m=motor_models(p); K=load_optimized_gains();
controllers={design_compensator(p,m,.01,.7),design_compensator(p,m,20,.7)};
ids={'PID','lag','lead'}; runs={simulate_closed_loop(p,K,struct('Tend',12)), ...
    simulate_compensator(p,controllers{1}),simulate_compensator(p,controllers{2})};
metrics=cellfun(@performance_metrics,runs,'UniformOutput',false);
get=@(field) cellfun(@(M) M.(field),metrics)';
predicted=[0;controllers{1}.relativeError*p.w_ref;controllers{2}.relativeError*p.w_ref];
summary=table(string(ids)',get('ts'),get('os'),get('ess'),get('essValidated'),get('iae'),get('effort'),predicted, ...
    'VariableNames',{'controller','settling_s','overshoot_pct','tail_error_rad_s','tail_equilibrium_validated', ...
    'IAE_rad','effort_Vs','predicted_unsaturated_error_rad_s'});
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
writetable(summary,fullfile(csvDir,'compensator_reference_metrics.csv'));
for j=1:3
    out=runs{j}; writetable(table(out.t,out.w,out.i,out.u,'VariableNames', ...
        {'time_s','omega_rad_s','current_A','voltage_V'}),fullfile(csvDir,['compensator_reference_' ids{j} '.csv']));
end
f=figure('Visible','off','Position',[100,100,1000,720]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1); nexttile; hold on;
for j=1:3, plot(runs{j}.t,runs{j}.w,'LineWidth',1.4); end
yline(100,'--','HandleVisibility','off'); yline(98,':','HandleVisibility','off');
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); grid on; legend('ПІД','Lag','Lead','Location','southeast');
title('Порівняння на рівняннях: перевірка Simscape ще не виконана');
nexttile; hold on; for j=1:3, plot(runs{j}.t,runs{j}.u,'LineWidth',1.4); end
xlabel('Час, с'); ylabel('Напруга, В'); grid on; legend('ПІД','Lag','Lead');
exportgraphics(f,fullfile(figDir,'compensator_reference_comparison.png'),'Resolution',180);
record=struct('implementation','reference equations only','physicalValidated',false,'horizon',12,'voltageLimits',[p.Vmin,p.Vmax], ...
    'PID',K,'lag',serializable(controllers{1}),'lead',serializable(controllers{2}));
encoded=jsonencode(record,PrettyPrint=true);
fid=fopen(fullfile(root,'results','json','compensator_reference.json'),'w','n','UTF-8');
fileCleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',encoded);
disp(summary);
end

function value=serializable(C)
value=rmfield(C,{'tf','poles'});
value.polesReal=real(C.poles); value.polesImag=imag(C.poles);
end
