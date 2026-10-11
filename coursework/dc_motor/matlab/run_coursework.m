function record=run_coursework(mode,regenerateOptimization)
%RUN_COURSEWORK Verified CLI orchestration; core is not a full submission.
if nargin<1, mode='core'; end
if nargin<2, regenerateOptimization=false; end
assert(ismember(string(mode),["core","full"]),'dc_motor:InvalidMode','Mode must be core or full.');
root=fileparts(fileparts(mfilename('fullpath')));
previousPath=path; previousVisibility=get(groot,'defaultFigureVisible');
cleanup=onCleanup(@() restoreSession(previousPath,previousVisibility));
addpath(fullfile(root,'matlab'),fullfile(root,'matlab','src'));
set(groot,'defaultFigureVisible','off');
environment=preflight(strcmp(mode,'full'),'tool_coupling');
for folder={'csv','json','figures','logs'}
    target=fullfile(root,'results',folder{1}); if ~isfolder(target), mkdir(target); end
end
p=motor_params(); scenarios=jsondecode(fileread(fullfile(root,'config','scenarios.json')));
% Bootstrap gains before tests consume them, including missing/stale caches.
if regenerateOptimization
    run_optimization();
else
    load_optimized_gains(); % Explicit verified-artifact mode; no fallback gains.
end
tests=runtests(fullfile(root,'matlab','tests')); assertSuccess(tests);
% Tests build alternate scenarios. Regenerate deliverable models afterwards.
for j=1:numel(scenarios.scenarios)
    if iscell(scenarios.scenarios), s=scenarios.scenarios{j}; else, s=scenarios.scenarios(j); end
    if isfield(s,'loadTime') && isempty(s.loadTime), s=rmfield(s,'loadTime'); end
    if strcmp(s.kind,'plant'), run_plant_comparison(p,s); end
end
export_modeling_artifacts(); export_pid_artifacts();
finalize_optimization_artifacts(); run_disturbance_study(); run_compensator_study(); export_physical_artifacts();
K=load_optimized_gains();
for kind={'diffeq','statespace'}
    mdl=['dc_motor_pid_' kind{1}]; load_system(fullfile(root,'matlab','models',[mdl '.slx']));
    ws=get_param(mdl,'ModelWorkspace');
    assert(norm(ws.evalin('[Kp,Ki,Kd]')-K)<1e-10 && ws.evalin('TorqueValue')==0 && ...
        str2double(get_param(mdl,'StopTime'))==5,'dc_motor:SavedModelMismatch','Saved model must be optimized nominal scenario.');
    close_system(mdl,0);
end
if strcmp(mode,'full'), export_coursework_fmu(); end
environment=preflight(false,'tool_coupling');
record=struct('schemaVersion',1,'mode',mode,'complete',false,'corePassed',true, ...
    'timestampUTC',char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    'matlabVersion',version,'optimizationRegenerated',logical(regenerateOptimization), ...
    'tests',struct('total',numel(tests),'passed',nnz([tests.Passed]),'failed',nnz([tests.Failed]),'incomplete',nnz([tests.Incomplete])), ...
    'pending',{{'Tool-coupling MATLAB FMU export and Python execution','Final report and clean-copy packaging'}}, ...
    'environment',environment);
record.sources=struct('path',{},'sha256',{});
files=[dir(fullfile(root,'matlab','*.m'));dir(fullfile(root,'matlab','src','*.m'));dir(fullfile(root,'matlab','tests','*.m'));dir(fullfile(root,'config','*.json'))];
for j=1:numel(files)
    filename=fullfile(files(j).folder,files(j).name);
    relative=replace(extractAfter(string(filename),strlength(root)+1),'\','/');
    record.sources(j)=struct('path',char(relative),'sha256',file_sha256(filename));
end
fid=fopen(fullfile(root,'results','json','matlab_run.json'),'w','n','UTF-8');
fileCleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(record,PrettyPrint=true));
fprintf('CORE VERIFIED: MATLAB %d/%d tests; full submission remains incomplete.\n',record.tests.passed,record.tests.total);
end

function restoreSession(previousPath,previousVisibility)
bdclose('all'); close all; path(previousPath);
set(groot,'defaultFigureVisible',previousVisibility);
end
