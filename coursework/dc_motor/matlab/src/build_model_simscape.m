function [mdl,filename]=build_model_simscape(p,modelDir,overrides)
%BUILD_MODEL_SIMSCAPE Actual R2026a physical DC Motor, external load and sensors.
% Verified library paths/parameters/port order; no manual or equation fallback.
if nargin<2 || isempty(modelDir), modelDir=fullfile(dc_project_root(),'matlab','models'); end
if nargin<3, overrides=struct(); end
motor_models(p);
assert(abs(p.Kt-p.Ke)<1e-12,'dc_motor:InvalidParameters','Physical DC Motor uses equal SI torque/back-emf constants.');
assert(~isempty(which('ee_lib')) && ~isempty(which('fl_lib')), ...
    'dc_motor:MissingPrerequisites','Simscape and Simscape Electrical are required.');
load_system('ee_lib'); load_system('fl_lib'); load_system('nesl_utility');
lib=struct('motor','ee_lib/Electromechanical/Brushed Motors/DC Motor', ...
    'voltage','fl_lib/Electrical/Electrical Sources/Controlled Voltage Source', ...
    'current','fl_lib/Electrical/Electrical Sensors/Current Sensor', ...
    'electricalReference','fl_lib/Electrical/Electrical Elements/Electrical Reference', ...
    'speed','fl_lib/Mechanical/Mechanical Sensors/Ideal Rotational Motion Sensor', ...
    'load','fl_lib/Mechanical/Rotational Elements/Inertia', ...
    'mechanicalReference','fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', ...
    'torque','fl_lib/Mechanical/Mechanical Sources/Ideal Torque Source', ...
    'solver','nesl_utility/Solver Configuration','input','nesl_utility/Simulink-PS Converter', ...
    'output','nesl_utility/PS-Simulink Converter');
names=fieldnames(overrides);
for j=1:numel(names), assert(isfield(lib,names{j}),'dc_motor:InvalidOptions','Unknown physical library override.'); lib.(names{j})=overrides.(names{j}); end
names=fieldnames(lib);
for j=1:numel(names)
    assert(getSimulinkBlockHandle(lib.(names{j}))~=-1,'dc_motor:MissingPhysicalBlock','Required physical block is absent: %s',lib.(names{j}));
end
[mdl,filename,sub]=init_motor_model('dc_motor_simscape',p,modelDir);
try
    set_param(mdl,'Solver','ode23t','MaxStep','0.001');
    B=@(name) [sub '/' name];
    set_param(B('omega'),'Position',[685,170,715,184]);
    set_param(B('i'),'Position',[685,90,715,104]);
    add_block(lib.motor,B('DC Motor'),'Position',[320,100,410,205]);
    set_param(B('DC Motor'),'ShowName','on');
    configure(B('DC Motor'),struct('field_option','ee.enum.field_option.pm', ...
        'parameterization','ee.enum.dcparam_option.circuit_param','emf_or_torque','ee.enum.emf_or_torque.ki', ...
        'Ra','p.Ra','Ra_unit','Ohm','La','p.La','La_unit','H','Ki','p.Kt','Ki_unit','N*m/A', ...
        'J','p.Jm','J_unit','kg*m^2','lam_param','ee.enum.lam_param.damping', ...
        'lam','p.Bm','lam_unit','N*m*s/rad','speed0','x0(2)','speed0_unit','rad/s'));
    add_block(lib.load,B('Load inertia'),'Position',[465,60,520,100]);
    configure(B('Load inertia'),struct('inertia','p.JL','inertia_unit','kg*m^2'));
    add_block(lib.voltage,B('Voltage source'),'Position',[140,90,195,175]);
    add_block(lib.current,B('Current Sensor'),'Position',[235,85,290,140]);
    add_block(lib.electricalReference,B('Electrical Reference'),'Position',[150,215,180,245]);
    add_block(lib.speed,B('Speed Sensor'),'Position',[475,155,535,220]);
    configure(B('Speed Sensor'),struct('position_port','false','acceleration_port','false','velocity_port','true'));
    add_block(lib.torque,B('Opposing Torque'),'Position',[355,295,415,355]);
    add_block(lib.mechanicalReference,B('Mechanical Reference'),'Position',[475,340,505,375]);
    add_block(lib.solver,B('Solver Configuration'),'Position',[225,250,285,290]);
    add_block(lib.input,B('Voltage to PS'),'Position',[70,90,110,120]);
    configure(B('Voltage to PS'),struct('Unit','V','FilteringAndDerivatives','provide','UdotUserProvided','0'));
    add_block('simulink/Math Operations/Gain',B('Opposing sign'),'Gain','-1','Position',[75,285,105,315]);
    add_block(lib.input,B('Torque to PS'),'Position',[145,285,185,315]);
    configure(B('Torque to PS'),struct('Unit','N*m','FilteringAndDerivatives','provide','UdotUserProvided','0'));
    add_block(lib.output,B('Speed from PS'),'Position',[590,160,630,190]); configure(B('Speed from PS'),struct('Unit','rad/s'));
    add_block(lib.output,B('Current from PS'),'Position',[590,80,630,110]); configure(B('Current from PS'),struct('Unit','A'));
    add_line(sub,'Vin/1','Voltage to PS/1','autorouting','on');
    add_line(sub,'TL/1','Opposing sign/1','autorouting','on');
    add_line(sub,'Opposing sign/1','Torque to PS/1','autorouting','on');
    add_line(sub,'Speed from PS/1','omega/1','autorouting','on');
    add_line(sub,'Current from PS/1','i/1','autorouting','on');
    ports=@(name) get_param(B(name),'PortHandles');
    motor=ports('DC Motor'); source=ports('Voltage source'); current=ports('Current Sensor');
    eref=ports('Electrical Reference'); load=ports('Load inertia'); speed=ports('Speed Sensor');
    torque=ports('Opposing Torque'); mref=ports('Mechanical Reference'); solver=ports('Solver Configuration');
    vin=ports('Voltage to PS'); tin=ports('Torque to PS'); wout=ports('Speed from PS'); iout=ports('Current from PS');
    wire=@(a,b) add_line(sub,a,b,'autorouting','on');
    % Motor LConn=[+,R], RConn=[-,C]; source LConn=+, RConn=[S,-].
    % Current Sensor LConn=+, RConn=[I,-]; speed RConn=[C,W].
    wire(vin.RConn(1),source.RConn(1)); wire(source.LConn(1),current.LConn(1));
    wire(current.RConn(2),motor.LConn(1)); wire(motor.RConn(1),eref.LConn(1));
    wire(source.RConn(2),eref.LConn(1)); wire(current.RConn(1),iout.LConn(1));
    wire(motor.LConn(2),load.LConn(1)); wire(motor.LConn(2),speed.LConn(1));
    wire(motor.LConn(2),torque.LConn(1)); wire(motor.RConn(2),mref.LConn(1));
    wire(speed.RConn(1),mref.LConn(1)); wire(torque.RConn(2),mref.LConn(1));
    wire(tin.RConn(1),torque.RConn(1)); wire(speed.RConn(2),wout.LConn(1));
    wire(solver.RConn(1),eref.LConn(1));
    set_param(mdl,'SimulationCommand','update');
    save_system(mdl,filename);
catch failure
    close_system(mdl,0); rethrow(failure);
end
end

function configure(block,values)
names=fieldnames(values); parameters=get_param(block,'DialogParameters');
for j=1:numel(names)
    assert(isfield(parameters,names{j}),'dc_motor:PhysicalParameterMissing','Unsupported physical parameter %s on %s.',names{j},block);
    set_param(block,names{j},values.(names{j}));
    assert(strcmp(get_param(block,names{j}),values.(names{j})), ...
        'dc_motor:PhysicalParameterMismatch','Physical parameter was not retained.');
end
end
