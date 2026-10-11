function tests=test_orchestration
% Check bootstrap ordering without repeating the full, expensive search.
tests=functiontests(localfunctions);
end

function testRegenerationPrecedesMissingGainConsumers(tc)
checkBootstrap(tc,false);
end

function testRegenerationPrecedesStaleGainConsumers(tc)
checkBootstrap(tc,true);
end

function checkBootstrap(tc,stale)
root=dc_project_root(); sandbox=tempname; mkdir(sandbox);
previousPath=path;
cleanup=onCleanup(@() restoreFixture(previousPath,sandbox));
mkdir(fullfile(sandbox,'matlab')); mkdir(fullfile(sandbox,'matlab','tests'));
mkdir(fullfile(sandbox,'results')); mkdir(fullfile(sandbox,'results','json'));
copyfile(fullfile(root,'matlab','src'),fullfile(sandbox,'matlab','src'));
copyfile(fullfile(root,'config'),fullfile(sandbox,'config'));
source=fileread(fullfile(root,'matlab','run_coursework.m'));
source=strrep(source,'function record=run_coursework(', ...
    'function record=run_coursework_bootstrap_probe(');
writeFile(fullfile(sandbox,'matlab','run_coursework_bootstrap_probe.m'),source);
% The search is the sole stub: abort exactly when requested regeneration
% begins. Actual cache-reading tests must never run before that boundary.
writeFile(fullfile(sandbox,'matlab','run_optimization.m'), ...
    sprintf('function run_optimization()\nerror(''dc_motor:RegenerationReached'',''Requested regeneration started.'');\nend\n'));
cache=fullfile(sandbox,'results','json','optimization.json');
if stale
    record=struct('K',[11,21,1],'provenance',struct( ...
        'parametersSHA256','stale','scenariosSHA256','stale'));
    writeFile(cache,jsonencode(record));
end
consumer=sprintf(['function tests=test_cached_gain_consumer\n' ...
    'tests=functiontests(localfunctions);\nend\n' ...
    'function testReadsGains(tc)\n' ...
    'K=load_optimized_gains(''%s''); verifyTrue(tc,all(isfinite(K)));\nend\n'], ...
    strrep(cache,'''',''''''));
writeFile(fullfile(sandbox,'matlab','tests','test_cached_gain_consumer.m'),consumer);
addpath(fullfile(sandbox,'matlab'));
verifyError(tc,@() run_coursework_bootstrap_probe('core',true), ...
    'dc_motor:RegenerationReached');
end

function writeFile(filename,content)
fid=fopen(filename,'w','n','UTF-8'); cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',content);
end

function restoreFixture(previousPath,sandbox)
path(previousPath);
clear run_coursework_bootstrap_probe run_optimization test_cached_gain_consumer;
rmdir(sandbox,'s');
end
