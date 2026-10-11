function record=export_coursework_fmu()
%EXPORT_COURSEWORK_FMU Genuine MATLAB FMI2 exports using licensed Simulink.
% This route deliberately needs local matching MATLAB/Simulink at runtime.
root=dc_project_root(); preflight(true,'tool_coupling');
p=motor_params(); K=load_optimized_gains(); output=fullfile(root,'fmu');
if ~isfolder(output), mkdir(output); end
record=struct('route','tool_coupling','standalone',false,'runtimeRequired', ...
    'Matching locally installed and licensed MATLAB and Simulink', ...
    'release',version('-release'),'fixedStep',1e-5,'exportPassed',false,'files',[]);
previous=pwd; cleanup=onCleanup(@() cd(previous));
for kind={'plant','pid'}
    [mdl,modelFile]=build_fmu_harness(p,K,kind{1});
    build=fullfile(output,'build',[kind{1} '_' char(java.util.UUID.randomUUID)]);
    project=slproject.create(build);
    projectCleanup=onCleanup(@() project.close());
    destination=fullfile(project.RootFolder,[mdl '.slx']);
    copyfile(modelFile,destination); project.addFile([mdl '.slx']); project.addPath(project.RootFolder);
    close_system(mdl,0); load_system(destination);
    Simulink.fmuexport.ExportSimulinkProjectToFMU(project,[mdl '.slx'], ...
        '-fmuname',fullfile(output,mdl),'-author','Ievgen Bovkun', ...
        '-description','DC motor coursework. Tool-coupling: requires licensed MATLAB/Simulink R2026a.');
    file=fullfile(output,[mdl '.fmu']);
    assert(isfile(file),'dc_motor:FMUExportFailed','Actual FMU export missing.');
    record.files=[record.files,struct('path',['fmu/' mdl '.fmu'],'sha256',file_sha256(file))];
    close_system(mdl,0); clear projectCleanup
end
record.exportPassed=true;
record.configSHA256=file_sha256(fullfile(root,'config','parameters.json'));
record.gains=K;
fid=fopen(fullfile(root,'results','json','fmu_export.json'),'w','n','UTF-8');
c=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(record,PrettyPrint=true));
fprintf('MATLAB TOOL-COUPLING FMU EXPORTS VERIFIED: 2/2\n');
end
