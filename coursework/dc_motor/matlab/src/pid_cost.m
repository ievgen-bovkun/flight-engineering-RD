function [cost,M]=pid_cost(K,p,cfg)
%PID_COST Primary coursework objective uses absolute voltage, not energy.
if nargin<3, cfg=struct(); end
defaults=struct('lambda',.2,'IAE_ref',1,'effort_ref',1,'penalty',100, ...
    'ts_target',.9*p.ts_spec,'os_target',p.os_spec,'ess_max',p.ess_spec, ...
    'simopt',struct('solver','rk4','dt',.0005));
fields=fieldnames(defaults);
for j=1:numel(fields), if ~isfield(cfg,fields{j}), cfg.(fields{j})=defaults.(fields{j}); end; end
pid_settings(p,K,cfg.simopt); % Programming/configuration errors must propagate.
try
    out=simulate_closed_loop(p,K,cfg.simopt); M=performance_metrics(out);
catch ME
    if strcmp(ME.identifier,'dc_motor:UnstableSimulation')
        cost=1e6; M=struct(); return
    end
    rethrow(ME)
end
cost=M.iae/cfg.IAE_ref+cfg.lambda*M.effort/cfg.effort_ref;
ts=M.ts; if ~isfinite(ts), ts=2*out.opt.Tend; end
violation=max(0,ts/cfg.ts_target-1)+max(0,M.os/cfg.os_target-1)+max(0,M.ess/cfg.ess_max-1);
if ~M.essValidated, violation=violation+1; end
cost=cost+cfg.penalty*violation;
end
