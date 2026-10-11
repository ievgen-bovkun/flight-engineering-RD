function R=optimize_pid(p,cfg,starts)
%OPTIMIZE_PID Bounded multistart Nelder-Mead plus a seeded genetic search.
if nargin<2, cfg=struct(); end
if nargin<3, starts=[33.63,75,3.895;11.0456,21.89,1.3288;60,150,6;5,6,.7;100,300,10]; end
defaults=struct('MaxFunEvals',250,'gaPop',24,'gaGen',24,'seed',7,'verbose',true, ...
    'lambda',.2,'simopt',struct('solver','rk4','dt',.0005));
fields=fieldnames(defaults);
for j=1:numel(fields), if ~isfield(cfg,fields{j}), cfg.(fields{j})=defaults.(fields{j}); end; end
baseline=performance_metrics(simulate_closed_loop(p,[33.63,75,3.895],cfg.simopt));
if ~isfield(cfg,'IAE_ref'), cfg.IAE_ref=baseline.iae; end
if ~isfield(cfg,'effort_ref'), cfg.effort_ref=baseline.effort; end
bounds=[2,1,.1;300,800,40]; lo=log10(bounds(1,:)); hi=log10(bounds(2,:));
objective=@(x) boundedCost(x,lo,hi,p,cfg);
R.nm=struct('K',{},'score',{},'exitflag',{},'evaluations',{});
best=Inf; bestK=[]; evaluations=0;
for j=1:size(starts,1)
    x0=log10(min(max(starts(j,:),bounds(1,:)),bounds(2,:)));
    opts=optimset('Display','off','TolX',1e-4,'TolFun',1e-7,'MaxIter',cfg.MaxFunEvals,'MaxFunEvals',cfg.MaxFunEvals);
    [x,f,exitflag,info]=fminsearch(objective,x0,opts);
    candidate=min(max(10.^x,bounds(1,:)),bounds(2,:));
    score=pid_cost(candidate,p,cfg);
    R.nm(j)=struct('K',candidate,'score',score,'exitflag',exitflag,'evaluations',info.funcCount);
    evaluations=evaluations+info.funcCount+1;
    if score<best, best=score; bestK=candidate; end
    if cfg.verbose, fprintf('NM start %d/%d: score %.8f, evaluations %d, exit %d\n',j,size(starts,1),f,info.funcCount,exitflag); end
end
[x,f,history]=ga_simple(objective,lo,hi,struct('pop',cfg.gaPop,'gen',cfg.gaGen, ...
    'seed',cfg.seed,'verbose',cfg.verbose));
R.ga=struct('K',10.^x,'score',f,'history',history);
evaluations=evaluations+cfg.gaPop*(cfg.gaGen+1);
if f<best, best=f; bestK=10.^x; R.method='genetic'; else, R.method='multistart_nelder_mead'; end
R.K=bestK; R.score=best; R.evaluations=evaluations; R.seed=cfg.seed; R.cfg=cfg; R.bounds=bounds;
R.validation=performance_metrics(simulate_closed_loop(p,bestK));
R.feasible=R.validation.ts<=p.ts_spec && R.validation.os<=p.os_spec ...
    && R.validation.ess<=p.ess_spec && R.validation.essValidated;
end

function f=boundedCost(x,lo,hi,p,cfg)
outside=max(lo-x,0)+max(x-hi,0);
if any(outside>0), f=1e6+1e3*sum(outside.^2); else, f=pid_cost(10.^x,p,cfg); end
end
