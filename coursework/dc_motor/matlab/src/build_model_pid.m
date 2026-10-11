function [mdl,path]=build_model_pid(p,K,kind,opt,modelDir)
%BUILD_MODEL_PID Match the direct simulator's filter and anti-windup exactly.
if nargin<3, kind='diffeq'; end
if nargin<4, opt=struct(); end
if nargin<5, modelDir=fullfile(dc_project_root(),'matlab','models'); end
settings=pid_settings(p,K,opt); opt=settings.opt;
switch kind
    case 'diffeq', [plant,~]=build_model_diffeq(p,modelDir);
    case 'statespace', [plant,~]=build_model_statespace(p,modelDir);
    otherwise, error('dc_motor:InvalidOptions','Unknown plant kind.');
end
[mdl,path,sub]=init_motor_model(['dc_motor_pid_' kind],p,modelDir);
delete_line(mdl,'Vin/1','Motor Model Subsystem/1');
delete_line(mdl,'TL/1','Motor Model Subsystem/2');
delete_line(mdl,'Motor Model Subsystem/1','Outputs/1');
delete_line(mdl,'Motor Model Subsystem/2','Outputs/2');
delete_block(sub); add_block([plant '/Motor Model Subsystem'],sub,'Position',[340,90,540,260]);
close_system(plant,0);
% Copying a subsystem does not copy its source model workspace.
ws=get_param(mdl,'ModelWorkspace'); m=motor_models(p);
assignin(ws,'A',m.A); assignin(ws,'B',[m.Bu,m.Bd]); assignin(ws,'C',m.C); assignin(ws,'D',m.D);
assignin(ws,'Kp',K(1)); assignin(ws,'Ki',K(2)); assignin(ws,'Kd',K(3));
assignin(ws,'Nf',1/settings.Tf); assignin(ws,'Kb',0);
if opt.aw && isfinite(settings.Tt), assignin(ws,'Kb',1/settings.Tt); end
assignin(ws,'Reference',opt.w_ref); assignin(ws,'TorqueValue',opt.TL_step); assignin(ws,'TorqueTime',opt.TL_time);
assignin(ws,'Vmin',opt.Vmin); assignin(ws,'Vmax',opt.Vmax);
assignin(ws,'beta',opt.beta); assignin(ws,'gamma',opt.gamma);
delete_block([mdl '/Vin']);
add_block('simulink/Sources/Step',[mdl '/Reference'],'Time','0','Before','0','After','Reference','Position',[20,50,60,90]);
pid=[mdl '/PID'];
add_block('simulink/Continuous/PID Controller (2DOF)',pid,'Position',[125,65,245,145]);
set_param(pid,'Controller','PID','TimeDomain','Continuous-time','Form','Parallel', ...
    'P','Kp','I','Ki','D','Kd','N','Nf','b','beta','c','gamma', ...
    'UpperSaturationLimit','Vmax','LowerSaturationLimit','Vmin', ...
    'AntiWindupMode','back-calculation','Kb','Kb');
if opt.sat, set_param(pid,'LimitOutput','on'); else, set_param(pid,'LimitOutput','off'); end
add_line(mdl,'Reference/1','PID/1','autorouting','on');
add_line(mdl,'Motor Model Subsystem/1','PID/2','autorouting','on');
add_line(mdl,'PID/1','Motor Model Subsystem/1','autorouting','on');
add_block('simulink/Sinks/To Workspace',[mdl '/Voltage trace'],'VariableName','voltageTrace', ...
    'SaveFormat','Timeseries','Position',[275,15,390,45]);
add_line(mdl,'PID/1','Voltage trace/1','autorouting','on');
% Reconnect copied subsystem ports removed with its predecessor.
add_line(mdl,'TL/1','Motor Model Subsystem/2','autorouting','on');
add_line(mdl,'Motor Model Subsystem/1','Outputs/1','autorouting','on');
add_line(mdl,'Motor Model Subsystem/2','Outputs/2','autorouting','on');
set_param(mdl,'StopTime',num2str(opt.Tend),'MaxStep',num2str(opt.MaxStep,16));
save_system(mdl,path);
end
