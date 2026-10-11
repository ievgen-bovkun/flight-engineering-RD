function env = preflight(requireAll)
%PREFLIGHT Exercise the CLI and record actual required capabilities.
% preflight(false) permits independent core work. preflight(true) is the
% final pipeline gate and cannot silently skip Simscape or FMU prerequisites.
if nargin < 1, requireAll = true; end
env.projectRoot = fileparts(fileparts(mfilename('fullpath')));
env.release = version('-release');
env.version = version;
env.platform = computer;
env.timestampUTC = char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
installed = ver;
env.products = {installed.Name};
env.matlabSmoke = isequal(expm(zeros(2)), eye(2));
env.simulink = ~isempty(ver('simulink'));
env.control = ~isempty(ver('control'));
env.simscape = ~isempty(ver('simscape')) && ~isempty(which('fl_lib'));
env.simscapeElectrical = ~isempty(which('ee_lib'));
env.fmuExporter = ~isempty(which('exportToFMU'));
compilerC = mex.getCompilerConfigurations('C','Selected');
compilerCpp = mex.getCompilerConfigurations('C++','Selected');
env.compiler = ~isempty(compilerC) || ~isempty(compilerCpp);
env.compilerNames = [{compilerC.Name}, {compilerCpp.Name}];
env.simulinkSmoke = false;
if env.simulink
    mdl = 'dc_motor_preflight_smoke';
    if bdIsLoaded(mdl), close_system(mdl,0); end
    cleanup = onCleanup(@() closeSmoke(mdl));
    new_system(mdl);
    add_block('simulink/Sources/Constant',[mdl '/Input'],'Value','7');
    add_block('simulink/Sinks/To Workspace',[mdl '/Output'], ...
        'VariableName','smokeOutput','SaveFormat','Timeseries');
    add_line(mdl,'Input/1','Output/1');
    out = sim(mdl,'StopTime','0.01','ReturnWorkspaceOutputs','on');
    signal = out.get('smokeOutput');
    env.simulinkSmoke = all(signal.Data == 7);
    clear cleanup
end
env.coreComplete = env.matlabSmoke && env.simulinkSmoke && env.control;
env.missingRequired = {};
checks = {'matlabSmoke','simulinkSmoke','control','simscape','simscapeElectrical','fmuExporter','compiler'};
labels = {'MATLAB CLI smoke','Simulink CLI smoke','Control System Toolbox', ...
    'Simscape','Simscape Electrical','Standalone FMU exporter','Selected supported C/C++ compiler'};
for k = 1:numel(checks)
    if ~env.(checks{k}), env.missingRequired{end+1} = labels{k}; end
end
env.complete = isempty(env.missingRequired);
outputDir = fullfile(env.projectRoot,'results','json');
if ~isfolder(outputDir), mkdir(outputDir); end
fid = fopen(fullfile(outputDir,'environment.json'),'w','n','UTF-8');
assert(fid >= 0,'dc_motor:WriteFailed','Cannot write environment evidence.');
fileCleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(env,PrettyPrint=true));
clear fileCleanup
fprintf('CLI core ready: %d; complete environment: %d\n',env.coreComplete,env.complete);
if requireAll && ~env.complete
    error('dc_motor:MissingPrerequisites','Missing required capabilities: %s',strjoin(env.missingRequired,', '));
end
end

function closeSmoke(mdl)
if bdIsLoaded(mdl), close_system(mdl,0); end
end
