function tests=test_simscape
tests=functiontests(localfunctions);
end

function testPhysicalSubsystemAndPersistedConfiguration(tc)
p=motor_params(); [mdl,filename]=build_model_simscape(p);
cleanup=onCleanup(@() close_system(mdl,0));
sub=[mdl '/Motor Model Subsystem']; handles=get_param(sub,'PortHandles');
verifyEqual(tc,numel(handles.Inport),2); verifyEqual(tc,numel(handles.Outport),2);
verifyEqual(tc,get_param([sub '/omega'],'Port'),'1');
verifyEqual(tc,get_param([sub '/i'],'Port'),'2');
verifyTrue(tc,isfile(filename));
verifyNotEmpty(tc,get_param([sub '/DC Motor'],'ReferenceBlock'));
ws=get_param(mdl,'ModelWorkspace'); verifyEqual(tc,ws.evalin('p.Jm'),.01);
verifyEqual(tc,ws.evalin('p.JL'),.02); verifyEqual(tc,ws.evalin('p.Bm'),.001);
set_param(mdl,'SimulationCommand','update');
end

function testRequiredOpenLoopPhysicalScenarios(tc)
p=motor_params();
scenarios={struct('id','simscape_zero','voltage',0,'loadTorque',0,'loadTime',1,'x0',[0;0],'tEnd',1,'outputStep',.001), ...
    struct('id','simscape_step','voltage',12,'loadTorque',0,'loadTime',1,'x0',[0;0],'tEnd',30,'outputStep',.001), ...
    struct('id','simscape_load','voltage',12,'loadTorque',.05,'loadTime',1,'x0',[0;0],'tEnd',30,'outputStep',.001)};
for j=1:numel(scenarios)
    r=run_simscape_comparison(p,scenarios{j});
    verifyTrue(tc,r.physicalValidated);
    verifyLessThanOrEqual(tc,r.maxSpeedError,1e-3);
    verifyLessThanOrEqual(tc,r.maxCurrentError,1e-4);
end
end

function testMissingPhysicalBlockFails(tc)
verifyError(tc,@() build_model_simscape(motor_params(),[], ...
    struct('motor','ee_lib/DoesNotExist/DC Motor')),'dc_motor:MissingPhysicalBlock');
end

function testWrongBlockParameterizationFails(tc)
verifyError(tc,@() build_model_simscape(motor_params(),[], ...
    struct('motor','fl_lib/Electrical/Electrical Elements/Resistor')),'dc_motor:PhysicalParameterMissing');
end

function testWrongPhysicalParametersCannotClaimAgreement(tc)
p=motor_params(); wrong=p; wrong.Ra=4;
s=struct('id','rejected_physical_mismatch','voltage',12,'loadTorque',0,'loadTime',1,'x0',[0;0],'tEnd',5,'outputStep',.001);
verifyError(tc,@() run_simscape_comparison(p,s,wrong),'dc_motor:ComparisonFailed');
end

function testPhysicalControllersMatchReferenceEquations(tc)
p=motor_params(); m=motor_models(p);
controllers={load_optimized_gains(),design_compensator(p,m,.01,.7),design_compensator(p,m,20,.7)};
for j=1:numel(controllers)
    r=run_physical_controller_comparison(p,controllers{j},struct('Tend',12));
    verifyTrue(tc,r.physicalValidated);
    verifyLessThanOrEqual(tc,r.maxErrors,[1e-3,1e-4,1e-3]);
end
r=run_physical_controller_comparison(p,controllers{1},struct('Tend',6,'TL_step',.05,'TL_time',1));
verifyTrue(tc,r.physicalValidated);
verifyLessThan(tc,r.physicalMetrics.ts,2);
end
