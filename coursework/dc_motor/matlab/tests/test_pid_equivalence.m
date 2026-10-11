function tests=test_pid_equivalence
tests=functiontests(localfunctions);
end

function testSharedFilterAndNoBaseOverwrite(tc)
p=motor_params(); K=[11.0456,21.89,1.3288]; settings=pid_settings(p,K,struct());
assignin('base','TL_step',.1234);
cleanup=onCleanup(@() evalin('base','clear TL_step'));
[mdl,~]=build_model_pid(p,K,'diffeq',struct('TL_step',0));
ws=get_param(mdl,'ModelWorkspace');
verifyEqual(tc,ws.evalin('TorqueValue'),0);
verifyEqual(tc,ws.evalin('Nf'),1/settings.Tf,'AbsTol',1e-12);
verifyEqual(tc,evalin('base','TL_step'),.1234);
close_system(mdl,0);
end

function testNominalGainsReproduceAuditedResponse(tc)
p=motor_params(); out=simulate_closed_loop(p,[11.0456,21.89,1.3288]);
M=performance_metrics(out);
verifyEqual(tc,M.ts,1.717,'AbsTol',.002);
verifyEqual(tc,M.os,.137,'AbsTol',.01);
verifyLessThan(tc,M.ess,.2);
verifyGreaterThanOrEqual(tc,min(out.u),-48);
verifyLessThanOrEqual(tc,max(out.u),48);
end

function testTwoClosedLoopModelsMatchOde(tc)
p=motor_params(); K=[11.0456,21.89,1.3288];
options={struct('w_ref',1,'sat',false,'aw',false,'Tend',2), ...
    struct('Tend',5),struct('Tend',3,'TL_step',.05,'TL_time',1)};
for j=1:numel(options)
    r=run_pid_comparison(p,K,options{j});
    verifyLessThanOrEqual(tc,max(r.maxErrors(:,1)),1e-4);
    verifyLessThanOrEqual(tc,max(r.maxErrors(:,2)),1e-5);
    verifyLessThanOrEqual(tc,max(r.maxErrors(:,3)),1e-3);
end
end

function testPidTuneAndFeasibilityAnchors(tc)
p=motor_params(); m=motor_models(p);
[K,info]=tune_pole_placement(p,m,1,5,20);
verifyEqual(tc,K,[33.63,75,3.895],'AbsTol',1e-12);
verifyEqual(tc,sort(real(info.actual_poles)),[-20;-5;-5],'AbsTol',1e-5);
[zn,zinfo]=tune_ziegler_nichols(p,m);
verifyTrue(tc,all(zn>0)); verifyEqual(tc,zinfo.Ku,Inf);
fb=check_feasibility(p,m,[24,48]);
verifyGreaterThan(tc,fb.t_reach(1),2); verifyLessThan(tc,fb.t_reach(2),2);
verifyEqual(tc,fb.V_ss,12,'AbsTol',1e-12);
end
