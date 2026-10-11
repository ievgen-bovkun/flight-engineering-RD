function tests=test_fmu_export
tests=functiontests(localfunctions);
end

function testTrialRouteDoesNotClaimStandaloneLicense(tc)
env=preflight(false,'tool_coupling');
verifyTrue(tc,env.toolCouplingExporter);
verifyEqual(tc,env.fmuRoute,'tool_coupling');
verifyEqual(tc,env.fmuLicense,logical(license('test','Simulink_FMU_Builder')));
verifyTrue(tc,env.complete);
end

function testScalarPlantInterfaceAndEquations(tc)
folder=tempname; mkdir(folder);
p=motor_params(); K=load_optimized_gains();
[mdl,file]=build_fmu_harness(p,K,'plant',folder);
c=onCleanup(@() close_system(mdl,0));
verifyTrue(tc,isfile(file));
verifyEqual(tc,get_param(mdl,'FixedStep'),'0.00001');
verifyEqual(tc,portNames(mdl,'Inport'),{'Vin','TL'});
verifyEqual(tc,portNames(mdl,'Outport'),{'omega','i'});
t=(0:.001:1)'; input=[t,12+0*t,0*t];
s=Simulink.SimulationInput(mdl).setExternalInput(input).setModelParameter('StopTime','1');
y=sim(s); w=y.yout.get('omega').Values;
m=motor_models(p); expected=lsim(m.G,12+0*w.Time,w.Time);
verifyLessThan(tc,max(abs(w.Data-expected)),1e-5);
clear c
end

function testPidHarnessMatchesValidatedController(tc)
folder=tempname; mkdir(folder);
p=motor_params(); K=load_optimized_gains();
[mdl,~]=build_fmu_harness(p,K,'pid',folder);
c=onCleanup(@() close_system(mdl,0));
verifyEqual(tc,portNames(mdl,'Inport'),{'omega_ref','TL'});
verifyEqual(tc,portNames(mdl,'Outport'),{'omega','i','Vin'});
t=(0:.001:5)'; input=[t,100+0*t,0*t];
y=sim(Simulink.SimulationInput(mdl).setExternalInput(input).setModelParameter('StopTime','5'));
r=simulate_closed_loop(p,K);
w=y.yout.get('omega').Values; v=y.yout.get('Vin').Values;
verifyLessThan(tc,max(abs(interp1(w.Time,w.Data,r.t)-r.w)),1e-4);
verifyLessThan(tc,max(abs(interp1(v.Time,v.Data,r.t)-r.u)),1e-3);
clear c
end

function testInvalidHarnessKindIsRejected(tc)
verifyError(tc,@() build_fmu_harness(motor_params(),load_optimized_gains(),'unknown',tempname),'dc_motor:InvalidFMUKind');
end

function names=portNames(mdl,type)
blocks=find_system(mdl,'SearchDepth',1,'BlockType',type);
numbers=cellfun(@(x) str2double(get_param(x,'Port')),blocks);
[~,order]=sort(numbers); names=cellfun(@(x) get_param(x,'Name'),blocks(order),'UniformOutput',false)';
end
