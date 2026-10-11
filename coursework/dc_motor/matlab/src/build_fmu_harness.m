function [mdl,file]=build_fmu_harness(p,K,kind,modelDir)
%BUILD_FMU_HARNESS Scalar FMI interface with embedded physics/controller.
% Tool-coupling FMUs require local matching MATLAB/Simulink at runtime.
if ~ismember(string(kind),["plant","pid"])
    error('dc_motor:InvalidFMUKind','Expected plant or pid.');
end
if nargin<4, modelDir=fullfile(dc_project_root(),'matlab','models'); end
if ~isfolder(modelDir), mkdir(modelDir); end
mdl=['dc_motor_' kind]; file=fullfile(modelDir,[mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl); ws=get_param(mdl,'ModelWorkspace'); m=motor_models(p);
assignin(ws,'A',m.A); assignin(ws,'B',[m.Bu,m.Bd]);
assignin(ws,'C',m.C); assignin(ws,'D',m.D); assignin(ws,'x0',[0;0]);
set_param(mdl,'SolverType','Fixed-step','Solver','ode4','FixedStep','0.00001', ...
    'StartTime','0','StopTime','5','SaveOutput','on','OutputSaveName','yout', ...
    'SaveFormat','Dataset','ReturnWorkspaceOutputs','on');
first='Vin'; if strcmp(kind,'pid'), first='omega_ref'; end
add_block('simulink/Sources/In1',[mdl '/' first],'Port','1','Position',[20,35,50,55]);
add_block('simulink/Sources/In1',[mdl '/TL'],'Port','2','Position',[20,210,50,230],'Unit','N*m');
add_block('simulink/Signal Routing/Mux',[mdl '/Inputs'],'Inputs','2','Position',[290,95,295,205]);
add_block('simulink/Continuous/State-Space',[mdl '/Motor'],'A','A','B','B','C','C','D','D', ...
    'X0','x0','Position',[330,105,465,185]);
add_block('simulink/Signal Routing/Demux',[mdl '/Outputs'],'Outputs','2','Position',[495,110,500,180]);
add_line(mdl,'Inputs/1','Motor/1'); add_line(mdl,'Motor/1','Outputs/1');
add_line(mdl,'TL/1','Inputs/2','autorouting','on');
for j=1:2
    names={'omega','i'}; units={'rad/s','A'};
    add_block('simulink/Sinks/Out1',[mdl '/' names{j}],'Port',num2str(j), ...
        'Unit',units{j},'Position',[600,90+j*50,630,110+j*50]);
    line=add_line(mdl,['Outputs/' num2str(j)],[names{j} '/1'],'autorouting','on');
    set_param(line,'Name',names{j});
end
if strcmp(kind,'plant')
    set_param([mdl '/Vin'],'Unit','V'); add_line(mdl,'Vin/1','Inputs/1','autorouting','on');
else
    set_param([mdl '/omega_ref'],'Unit','rad/s');
    settings=pid_settings(p,K); assignin(ws,'Kp',K(1)); assignin(ws,'Ki',K(2)); assignin(ws,'Kd',K(3));
    assignin(ws,'Nf',1/settings.Tf); assignin(ws,'Kb',1/settings.Tt);
    assignin(ws,'Vmin',p.Vmin); assignin(ws,'Vmax',p.Vmax);
    assignin(ws,'beta',p.beta); assignin(ws,'gamma',p.gamma);
    add_block('simulink/Continuous/PID Controller (2DOF)',[mdl '/PID'],'Position',[125,35,230,105]);
    set_param([mdl '/PID'],'Controller','PID','TimeDomain','Continuous-time','Form','Parallel', ...
        'P','Kp','I','Ki','D','Kd','N','Nf','b','beta','c','gamma', ...
        'LimitOutput','on','UpperSaturationLimit','Vmax','LowerSaturationLimit','Vmin', ...
        'AntiWindupMode','back-calculation','Kb','Kb');
    add_line(mdl,'omega_ref/1','PID/1'); add_line(mdl,'Outputs/1','PID/2','autorouting','on');
    add_line(mdl,'PID/1','Inputs/1','autorouting','on');
    add_block('simulink/Sinks/Out1',[mdl '/Vin'],'Port','3','Unit','V','Position',[600,50,630,70]);
    line=add_line(mdl,'PID/1','Vin/1','autorouting','on'); set_param(line,'Name','Vin');
end
set_param(mdl,'SimulationCommand','update'); save_system(mdl,file);
end
