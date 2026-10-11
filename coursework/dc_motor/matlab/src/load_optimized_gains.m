function K=load_optimized_gains(resultPath)
%LOAD_OPTIMIZED_GAINS Reject absent/stale results instead of fallback gains.
root=dc_project_root();
if nargin<1, resultPath=fullfile(root,'results','json','optimization.json'); end
if ~isfile(resultPath), error('dc_motor:MissingOptimization','Run run_optimization before using selected gains.'); end
R=jsondecode(fileread(resultPath));
if ~isfield(R,'provenance') || ~isfield(R.provenance,'parametersSHA256') ...
        || ~strcmp(R.provenance.parametersSHA256,file_sha256(fullfile(root,'config','parameters.json'))) ...
        || ~isfield(R.provenance,'scenariosSHA256') ...
        || ~strcmp(R.provenance.scenariosSHA256,file_sha256(fullfile(root,'config','scenarios.json')))
    error('dc_motor:StaleOptimization','Optimization does not match the current configuration. Regenerate it.');
end
required={'pid_cost.m','pid_settings.m','pid_output.m','simulate_closed_loop.m', ...
    'performance_metrics.m','motor_params.m','motor_models.m','optimize_pid.m','ga_simple.m'};
if ~isfield(R.provenance,'sources') || ~all(ismember(required,{R.provenance.sources.name}))
    error('dc_motor:StaleOptimization','Required source hashes are absent.');
end
for j=1:numel(R.provenance.sources)
    item=R.provenance.sources(j); file=fullfile(root,'matlab','src',item.name);
    if ~isfile(file) || ~strcmp(item.sha256,file_sha256(file))
        error('dc_motor:StaleOptimization','Source changed: %s. Regenerate optimization.',item.name);
    end
end
if ~isfield(R,'feasible') || ~R.feasible
    error('dc_motor:NoFeasibleController','Cached candidate failed validation.');
end
K=R.K(:)'; pid_settings(motor_params(),K,struct());
end
