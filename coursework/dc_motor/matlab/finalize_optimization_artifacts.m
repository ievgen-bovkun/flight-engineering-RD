function T=finalize_optimization_artifacts()
%FINALIZE_OPTIMIZATION_ARTIFACTS Common comparison table and final saved model.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
p=motor_params(); K=load_optimized_gains();
T=readtable(fullfile(root,'results','csv','pid_baseline_summary.csv'),'TextType','string');
r=run_pid_comparison(p,K,struct()); M=performance_metrics(r.reference); errors=max(r.maxErrors,[],1);
newRow=table("optimized",K(1),K(2),K(3),M.ts,M.t_first,M.os,M.ess,M.essValidated, ...
    M.iae,M.effort,M.effort2,errors(1),errors(2),errors(3),'VariableNames',T.Properties.VariableNames);
T=[T;newRow]; writetable(T,fullfile(root,'results','csv','controller_metrics.csv'));
names={'dc_motor_pid_diffeq','dc_motor_pid_statespace'};
for j=1:2
    load_system(fullfile(root,'matlab','models',[names{j} '.slx']));
    cleanup=onCleanup(@() close_system(names{j},0));
    print(['-s' names{j}],'-dpng',fullfile(root,'results','figures',[names{j} '_diagram.png']),'-r180');
    clear cleanup
end
disp(T);
end
