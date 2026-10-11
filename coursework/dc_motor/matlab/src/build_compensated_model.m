function [mdl,filename]=build_compensated_model(p,controller,scenario,modelDir)
%BUILD_COMPENSATED_MODEL PID/lag/lead around the actual physical subsystem.
if nargin<3, scenario=struct(); end
if nargin<4, modelDir=fullfile(dc_project_root(),'matlab','models'); end
d=struct('Tend',12,'w_ref',p.w_ref,'TL_step',0,'TL_time',1,'Vmin',p.Vmin,'Vmax',p.Vmax, ...
    'Tt',.1,'MaxStep',.001,'dt',p.dt,'sat',true,'aw',true);
names=fieldnames(d); for j=1:numel(names), if ~isfield(scenario,names{j}), scenario.(names{j})=d.(names{j}); end; end
if isnumeric(controller)
    settings=pid_settings(p,controller,scenario); scenario=settings.opt; kind='pid';
else
    assert(all(isfinite([controller.Kc,controller.z,controller.p])) && all([controller.Kc,controller.z,controller.p]>0), ...
        'dc_motor:InvalidCompensator','Invalid physical compensator.');
    kind='lag'; if controller.z<controller.p, kind='lead'; end
end
[plant,~]=build_model_simscape(p,modelDir);
[mdl,filename,sub]=init_motor_model(['dc_motor_' kind '_simscape'],p,modelDir);
try
    delete_line(mdl,'Vin/1','Motor Model Subsystem/1');
    delete_line(mdl,'TL/1','Motor Model Subsystem/2');
    delete_line(mdl,'Motor Model Subsystem/1','Outputs/1');
    delete_line(mdl,'Motor Model Subsystem/2','Outputs/2');
    delete_block(sub); add_block([plant '/Motor Model Subsystem'],sub,'Position',[480,95,670,245]);
    close_system(plant,0); delete_block([mdl '/Vin']);
    set_param([mdl '/Outputs'],'Position',[725,125,730,210]);
    set_param([mdl '/Trace'],'Position',[790,150,890,185]);
    set_param([mdl '/TL'],'Position',[30,425,75,460]);
    ws=get_param(mdl,'ModelWorkspace');
    assignin(ws,'Reference',scenario.w_ref); assignin(ws,'TorqueValue',scenario.TL_step);
    assignin(ws,'TorqueTime',scenario.TL_time); assignin(ws,'Vmin',scenario.Vmin); assignin(ws,'Vmax',scenario.Vmax);
    add_block('simulink/Sources/Step',[mdl '/Reference'],'Time','0','Before','0','After','Reference','Position',[20,50,60,90]);
    if strcmp(kind,'pid')
        K=controller; assignin(ws,'Kp',K(1)); assignin(ws,'Ki',K(2)); assignin(ws,'Kd',K(3));
        assignin(ws,'Nf',1/settings.Tf); assignin(ws,'beta',scenario.beta); assignin(ws,'gamma',scenario.gamma);
        Kb=0; if scenario.aw && isfinite(settings.Tt), Kb=1/settings.Tt; end; assignin(ws,'Kb',Kb);
        block=[mdl '/PID']; add_block('simulink/Continuous/PID Controller (2DOF)',block,'Position',[135,65,255,150]);
        set_param(block,'Controller','PID','TimeDomain','Continuous-time','Form','Parallel', ...
            'P','Kp','I','Ki','D','Kd','N','Nf','b','beta','c','gamma', ...
            'UpperSaturationLimit','Vmax','LowerSaturationLimit','Vmin','AntiWindupMode','back-calculation','Kb','Kb');
        if scenario.sat, set_param(block,'LimitOutput','on'); else, set_param(block,'LimitOutput','off'); end
        add_line(mdl,'Reference/1','PID/1','autorouting','on');
        add_line(mdl,'Motor Model Subsystem/1','PID/2','autorouting','on');
        controlPort='PID/1';
    else
        g2=controller.Kc*(controller.z-controller.p); Kaw=0;
        if scenario.sat && scenario.aw && abs(g2)>1e-12, Kaw=1/(g2*scenario.Tt); end
        assignin(ws,'Kc',controller.Kc); assignin(ws,'g2',g2); assignin(ws,'pc',controller.p); assignin(ws,'Kaw',Kaw);
        add_block('simulink/Math Operations/Sum',[mdl '/Error'],'Inputs','+-','Position',[95,60,115,90]);
        add_block('simulink/Math Operations/Gain',[mdl '/Direct'],'Gain','Kc','Position',[160,45,205,80]);
        add_block('simulink/Math Operations/Gain',[mdl '/Dynamic'],'Gain','g2','Position',[245,160,290,195]);
        add_block('simulink/Math Operations/Sum',[mdl '/Raw voltage'],'Inputs','++','Position',[325,65,345,105]);
        add_block('simulink/Discontinuities/Saturation',[mdl '/Voltage limiter'],'UpperLimit','Vmax','LowerLimit','Vmin','Position',[385,65,425,105]);
        if ~scenario.sat, set_param([mdl '/Voltage limiter'],'UpperLimit','inf','LowerLimit','-inf'); end
        add_block('simulink/Continuous/Integrator',[mdl '/Compensator state'],'InitialCondition','0','Position',[180,175,215,210]);
        add_block('simulink/Math Operations/Gain',[mdl '/Pole'],'Gain','-pc','Position',[250,250,295,285]);
        add_block('simulink/Math Operations/Sum',[mdl '/State derivative'],'Inputs','+++','Position',[120,170,140,230]);
        add_block('simulink/Math Operations/Sum',[mdl '/Saturation error'],'Inputs','+-','Position',[325,310,345,350]);
        add_block('simulink/Math Operations/Gain',[mdl '/Anti-windup'],'Gain','Kaw','Position',[215,315,260,350]);
        links={'Reference/1','Error/1';'Motor Model Subsystem/1','Error/2';'Error/1','Direct/1'; ...
            'Direct/1','Raw voltage/1';'Compensator state/1','Dynamic/1';'Dynamic/1','Raw voltage/2'; ...
            'Raw voltage/1','Voltage limiter/1';'Error/1','State derivative/1'; ...
            'Compensator state/1','Pole/1';'Pole/1','State derivative/2'; ...
            'Voltage limiter/1','Saturation error/1';'Raw voltage/1','Saturation error/2'; ...
            'Saturation error/1','Anti-windup/1';'Anti-windup/1','State derivative/3'; ...
            'State derivative/1','Compensator state/1'};
        for j=1:size(links,1), add_line(mdl,links{j,1},links{j,2},'autorouting','on'); end
        controlPort='Voltage limiter/1';
    end
    add_block('simulink/Sinks/To Workspace',[mdl '/Voltage trace'],'VariableName','voltageTrace', ...
        'SaveFormat','Timeseries','Position',[455,15,565,45]);
    add_line(mdl,controlPort,'Motor Model Subsystem/1','autorouting','on');
    add_line(mdl,controlPort,'Voltage trace/1','autorouting','on');
    add_line(mdl,'TL/1','Motor Model Subsystem/2','autorouting','on');
    add_line(mdl,'Motor Model Subsystem/1','Outputs/1','autorouting','on');
    add_line(mdl,'Motor Model Subsystem/2','Outputs/2','autorouting','on');
    set_param(mdl,'Solver','ode23t','StopTime',num2str(scenario.Tend),'MaxStep',num2str(scenario.MaxStep,16));
    set_param(mdl,'SimulationCommand','update'); save_system(mdl,filename);
catch failure
    if bdIsLoaded(plant), close_system(plant,0); end
    if bdIsLoaded(mdl), close_system(mdl,0); end
    rethrow(failure);
end
end
