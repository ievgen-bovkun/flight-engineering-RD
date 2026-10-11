function [mdl,path,sub]=init_motor_model(name,p,modelDir)
%INIT_MOTOR_MODEL Common standalone harness; all values persist with model.
if nargin<3, modelDir=fullfile(dc_project_root(),'matlab','models'); end
if ~isfolder(modelDir), mkdir(modelDir); end
mdl=name; path=fullfile(modelDir,[name '.slx']);
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);
ws=get_param(mdl,'ModelWorkspace');
assignin(ws,'p',p); assignin(ws,'x0',[0;0]);
assignin(ws,'VinValue',12); assignin(ws,'TorqueValue',0); assignin(ws,'TorqueTime',1);
set_param(mdl,'Solver','ode45','StopTime','30','RelTol',num2str(p.RelTol,16), ...
    'AbsTol',num2str(p.AbsTol,16),'MaxStep','0.001','ReturnWorkspaceOutputs','on');
sub=[mdl '/Motor Model Subsystem'];
add_block('simulink/Ports & Subsystems/Subsystem',sub,'Position',[230,65,445,230]);
delete_line(sub,'In1/1','Out1/1'); delete_block([sub '/In1']); delete_block([sub '/Out1']);
add_block('simulink/Sources/In1',[sub '/Vin'],'Port','1','Position',[25,88,55,102]);
add_block('simulink/Sources/In1',[sub '/TL'],'Port','2','Position',[25,235,55,249]);
add_block('simulink/Sinks/Out1',[sub '/omega'],'Port','1','Position',[685,88,715,102]);
add_block('simulink/Sinks/Out1',[sub '/i'],'Port','2','Position',[685,155,715,169]);
add_block('simulink/Sources/Step',[mdl '/Vin'],'Time','0','Before','0','After','VinValue','Position',[50,75,95,115]);
add_block('simulink/Sources/Step',[mdl '/TL'],'Time','TorqueTime','Before','0','After','TorqueValue','Position',[50,170,95,210]);
add_block('simulink/Signal Routing/Mux',[mdl '/Outputs'],'Inputs','2','Position',[490,90,495,175]);
add_block('simulink/Sinks/To Workspace',[mdl '/Trace'],'VariableName','plantTrace', ...
    'SaveFormat','Timeseries','Position',[560,115,660,145]);
add_line(mdl,'Vin/1','Motor Model Subsystem/1','autorouting','on');
add_line(mdl,'TL/1','Motor Model Subsystem/2','autorouting','on');
add_line(mdl,'Motor Model Subsystem/1','Outputs/1','autorouting','on');
add_line(mdl,'Motor Model Subsystem/2','Outputs/2','autorouting','on');
add_line(mdl,'Outputs/1','Trace/1','autorouting','on');
end
