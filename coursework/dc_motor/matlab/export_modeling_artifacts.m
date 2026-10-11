function summary=export_modeling_artifacts()
%EXPORT_MODELING_ARTIFACTS Package actual measured traces and CLI diagrams.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','src'));
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
if ~isfolder(figDir), mkdir(figDir); end
ids={'zero_input','open_loop_12V','plant_load_step','nonzero_initial'};
speed=zeros(4,2); current=zeros(4,2);
for k=1:4
    T=readtable(fullfile(csvDir,[ids{k} '.csv']));
    speed(k,:)=[max(abs(T.omega_diffeq-T.omega_reference)),max(abs(T.omega_statespace-T.omega_reference))];
    current(k,:)=[max(abs(T.current_diffeq-T.current_reference)),max(abs(T.current_statespace-T.current_reference))];
end
summary=table(ids',speed(:,1),speed(:,2),current(:,1),current(:,2), ...
    'VariableNames',{'scenario','max_speed_error_diffeq','max_speed_error_statespace','max_current_error_diffeq','max_current_error_statespace'});
writetable(summary,fullfile(csvDir,'plant_comparison_summary.csv'));
T=readtable(fullfile(csvDir,'plant_load_step.csv'));
f=figure('Visible','off','Position',[100,100,1000,700]);
cleanup=onCleanup(@() close(f));
tiledlayout(2,1);
nexttile; plot(T.time_s,[T.omega_reference,T.omega_diffeq,T.omega_statespace],'LineWidth',1.3);
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); grid on;
title('Стрибок напруги 12 В та моменту 0,05 Н·м при t = 1 с');
legend('Прямі рівняння (ode45)','Simulink: диф. рівняння','Simulink: простір станів','Location','southeast');
nexttile; plot(T.time_s,[T.current_reference,T.current_diffeq,T.current_statespace],'LineWidth',1.3);
xlabel('Час, с'); ylabel('Струм якоря, А'); grid on;
legend('Прямі рівняння (ode45)','Simulink: диф. рівняння','Simulink: простір станів','Location','northeast');
exportgraphics(f,fullfile(figDir,'plant_load_comparison.png'),'Resolution',180);
clear cleanup
p=motor_params();
fid=fopen(fullfile(root,'results','json','physical_parameters.json'),'w','n','UTF-8');
assert(fid>=0,'Cannot write parameter manifest');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(p,PrettyPrint=true)); clear cleanup
names={'dc_motor_diffeq','dc_motor_statespace'};
for k=1:2
    mdl=names{k}; load_system(fullfile(root,'matlab','models',[mdl '.slx']));
    cleanup=onCleanup(@() close_system(mdl,0));
    output=sim(mdl,'StopTime','0.1'); y=output.get('plantTrace');
    assert(all(isfinite(y.Data),'all') && y.Data(end,1)>0,'Saved model failed fresh-session smoke');
    print(['-s' mdl],'-dpng',fullfile(figDir,[mdl '_diagram.png']),'-r180');
    print(['-s' mdl '/Motor Model Subsystem'],'-dpng',fullfile(figDir,[mdl '_subsystem.png']),'-r180');
    clear cleanup
end
disp(summary);
end
