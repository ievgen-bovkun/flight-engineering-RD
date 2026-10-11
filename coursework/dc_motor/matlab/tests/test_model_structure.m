function tests = test_model_structure
tests=functiontests(localfunctions);
end

function testBothBuildersSharePortsAndPersistParameters(tc)
p=motor_params(); output=fullfile(tempdir,'dc_motor_structure_tests');
builders={@build_model_diffeq,@build_model_statespace};
for k=1:2
    [mdl,path]=builders{k}(p,output);
    cleanup=onCleanup(@() close_system(mdl,0));
    sub=[mdl '/Motor Model Subsystem'];
    ports=get_param(sub,'PortHandles');
    verifyEqual(tc,numel(ports.Inport),2);
    verifyEqual(tc,numel(ports.Outport),2);
    verifyEqual(tc,get_param([sub '/omega'],'Port'),'1');
    verifyEqual(tc,get_param([sub '/i'],'Port'),'2');
    verifyTrue(tc,isfile(path));
    clear cleanup
    load_system(path);
    cleanup=onCleanup(@() close_system(mdl,0));
    ws=get_param(mdl,'ModelWorkspace');
    verifyEqual(tc,ws.evalin('p.J'),.03,'AbsTol',1e-14);
    set_param(mdl,'SimulationCommand','update');
    clear cleanup
end
end

function testAllPlantScenariosMatchIndependentReference(tc)
p=motor_params(); data=jsondecode(fileread(fullfile(dc_project_root(),'config','scenarios.json')));
scenarios=data.scenarios;
if ~iscell(scenarios), scenarios=num2cell(scenarios); end
for k=1:numel(scenarios)
    s=scenarios{k};
    if ~strcmp(s.kind,'plant'), continue; end
    r=run_plant_comparison(p,s);
    verifyLessThanOrEqual(tc,max(r.maxSpeedError),1e-4,s.id);
    verifyLessThanOrEqual(tc,max(r.maxCurrentError),1e-5,s.id);
    verifyTrue(tc,all(isfinite(r.reference),'all'));
end
end

function testBuilderDoesNotOverwriteBaseDisturbance(tc)
assignin('base','TL_step',.1234); assignin('base','TL_time',99);
cleanup=onCleanup(@() evalin('base','clear TL_step TL_time'));
[mdl,~]=build_model_diffeq(motor_params(),fullfile(tempdir,'dc_motor_structure_tests'));
close_system(mdl,0);
verifyEqual(tc,evalin('base','TL_step'),.1234);
verifyEqual(tc,evalin('base','TL_time'),99);
end
