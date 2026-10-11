function R=run_optimization()
%RUN_OPTIMIZATION Real search, common-horizon tradeoffs and measured evidence.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab','src'));
set(groot,'defaultFigureVisible','off'); p=motor_params();
cfg=struct('lambda',.2,'MaxFunEvals',250,'gaPop',24,'gaGen',24,'seed',7, ...
    'simopt',struct('solver','rk4','dt',.0005));
fprintf('Primary objective: normalized IAE + lambda * integral(abs(voltage)).\n');
R=optimize_pid(p,cfg);
assert(R.feasible,'dc_motor:NoFeasibleController','Search did not produce a validated feasible controller.');
fprintf('Selected K=[%.9g %.9g %.9g], method=%s, ts=%.4f, OS=%.5f%%\n',R.K,R.method,R.validation.ts,R.validation.os);
comparison=run_pid_comparison(p,R.K,struct());
R.maximumComparisonErrors=max(comparison.maxErrors,[],1);
csvDir=fullfile(root,'results','csv'); figDir=fullfile(root,'results','figures');
jsonDir=fullfile(root,'results','json');
out=comparison.reference;
writetable(table(out.t,out.w,out.i,out.u,out.e,'VariableNames', ...
    {'time_s','omega_rad_s','current_A','voltage_V','error_rad_s'}),fullfile(csvDir,'pid_optimized.csv'));
lambdas=[0,.05,.2,.5,1,3,10]; gains=zeros(numel(lambdas),3); rows=zeros(numel(lambdas),5);
lo=log10(R.bounds(1,:)); hi=log10(R.bounds(2,:));
for j=1:numel(lambdas)
    c=R.cfg; c.lambda=lambdas(j);
    x=fminsearch(@(x) sweepCost(x,lo,hi,p,c),log10(R.K), ...
        optimset('Display','off','MaxFunEvals',160,'TolX',1e-4,'TolFun',1e-7));
    gains(j,:)=min(max(10.^x,R.bounds(1,:)),R.bounds(2,:));
    M=performance_metrics(simulate_closed_loop(p,gains(j,:)));
    feasible=M.ts<=p.ts_spec && M.os<=p.os_spec && M.ess<=p.ess_spec && M.essValidated;
    rows(j,:)=[M.iae,M.effort,M.ts,M.os,feasible];
    fprintf('Lambda %.2g: IAE %.6f, effort %.6f, feasible=%d\n',lambdas(j),M.iae,M.effort,feasible);
end
nonDominated=logical(rows(:,5));
for j=1:size(rows,1)
    dominates=all(rows(:,1:2)<=rows(j,1:2),2) & any(rows(:,1:2)<rows(j,1:2),2) & logical(rows(:,5));
    if any(dominates), nonDominated(j)=false; end
end
R.sweep=struct('lambda',lambdas,'gains',gains,'metrics',rows,'nonDominated',nonDominated);
writetable(array2table([lambdas',gains,rows,nonDominated],'VariableNames', ...
    {'lambda','Kp','Ki','Kd','IAE_rad','effort_Vs','settling_s','overshoot_pct','feasible','nondominated'}),fullfile(csvDir,'optimization_tradeoffs.csv'));
% Deliberately separate gain sensitivity from plant-parameter sensitivity.
sensitivity=struct('gain',[],'plant',[]);
for factor=[.8,1,1.2]
    M=performance_metrics(simulate_closed_loop(p,R.K*factor));
    sensitivity.gain=[sensitivity.gain;struct('factor',factor,'metrics',M)];
end
fields={'Ra','JL','Bm'};
for j=1:3
    for factor=[.8,1.2]
        q=p; q.(fields{j})=p.(fields{j})*factor; q.J=q.Jm+q.JL; q.B=q.Bm;
        M=performance_metrics(simulate_closed_loop(q,R.K));
        sensitivity.plant=[sensitivity.plant;struct('parameter',fields{j},'factor',factor,'metrics',M)];
    end
end
R.sensitivity=sensitivity;
R.provenance=struct('timestampUTC',char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    'matlabVersion',version,'parametersSHA256',file_sha256(fullfile(root,'config','parameters.json')), ...
    'scenariosSHA256',file_sha256(fullfile(root,'config','scenarios.json')));
files=dir(fullfile(root,'matlab','src','*.m')); sources=struct('name',{},'sha256',{});
for j=1:numel(files), sources(j)=struct('name',files(j).name,'sha256',file_sha256(fullfile(files(j).folder,files(j).name))); end
R.provenance.sources=sources;
writeJson(fullfile(jsonDir,'optimization.json'),R);
f=figure('Visible','off','Position',[100,100,1000,700]); cleanup=onCleanup(@() close(f));
baseline=simulate_closed_loop(p,[33.63,75,3.895]);
tiledlayout(2,1); nexttile;
plot(baseline.t,baseline.w,'--',out.t,out.w,'LineWidth',1.5); grid on;
yline(100,'k:','HandleVisibility','off'); xline(2,'k:','HandleVisibility','off');
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с'); legend('Базове розміщення полюсів','Оптимізований ПІД','Location','southeast');
nexttile; plot(baseline.t,baseline.u,'--',out.t,out.u,'LineWidth',1.5); grid on;
xlabel('Час, с'); ylabel('Напруга якоря, В'); legend('Базовий ПІД','Оптимізований ПІД');
exportgraphics(f,fullfile(figDir,'optimized_pid_comparison.png'),'Resolution',180); clear cleanup
f=figure('Visible','off'); cleanup=onCleanup(@() close(f));
plot(rows(:,1),rows(:,2),'o'); hold on;
plot(rows(nonDominated,1),rows(nonDominated,2),'s','MarkerFaceColor',[0,.45,.74]); grid on;
xlabel('IAE, рад'); ylabel('Інтеграл |V|, В·с'); title('Емпіричний компроміс за однакового горизонту 5 с');
legend('Перевірені кандидати','Недоміновані допустимі кандидати','Location','best');
exportgraphics(f,fullfile(figDir,'optimization_tradeoffs.png'),'Resolution',180);
fprintf('Validated optimization evidence saved; no claim of global optimum.\n');
end

function cost=sweepCost(x,lo,hi,p,cfg)
outside=max(lo-x,0)+max(x-hi,0);
if any(outside>0), cost=1e6+1e3*sum(outside.^2); else, cost=pid_cost(10.^x,p,cfg); end
end

function writeJson(file,value)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0,'Cannot write optimization evidence');
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,PrettyPrint=true));
end
