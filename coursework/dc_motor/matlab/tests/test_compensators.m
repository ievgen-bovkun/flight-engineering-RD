function tests=test_compensators
tests=functiontests(localfunctions);
end

function testStableLagLeadAndDcError(tc)
p=motor_params(); m=motor_models(p);
lag=design_compensator(p,m,.01,.7); lead=design_compensator(p,m,20,.7);
verifyEqual(tc,lag.type,'lag'); verifyGreaterThan(tc,lag.z,lag.p);
verifyEqual(tc,lead.type,'lead'); verifyLessThan(tc,lead.z,lead.p);
for C={lag,lead}
    c=C{1}; verifyTrue(tc,all(real(c.poles)<0));
    verifyEqual(tc,c.relativeError,1-dcgain(feedback(c.tf*m.G,1)),'AbsTol',1e-12);
end
end

function testInvalidDesignCannotProduceFalseSuccess(tc)
p=motor_params(); m=motor_models(p);
verifyError(tc,@() design_compensator(p,m,-1,.7),'dc_motor:InvalidCompensator');
verifyError(tc,@() design_compensator(p,m,.01,0),'dc_motor:InvalidCompensator');
verifyError(tc,@() design_compensator(p,m,.01,.7,10),'dc_motor:InvalidCompensator');
end

function testUnsaturatedEquationsMatchIndependentLsim(tc)
p=motor_params(); m=motor_models(p);
for pole=[.01,20]
    C=design_compensator(p,m,pole,.7);
    out=simulate_compensator(p,C,struct('sat',false,'aw',false,'Tend',12));
    reference=p.w_ref*ones(size(out.t));
    speed=lsim(feedback(C.tf*m.G,1),reference,out.t);
    voltage=lsim(feedback(C.tf,m.G),reference,out.t);
    verifyLessThan(tc,max(abs(out.w-speed)),2e-6);
    verifyLessThan(tc,max(abs(out.u-voltage)),2e-4);
end
end

function testSaturationAndEventRefinement(tc)
p=motor_params(); m=motor_models(p); C=design_compensator(p,m,.01,.7);
out=simulate_compensator(p,C,struct('Tend',12,'TL_step',.05,'TL_time',1));
fine=simulate_compensator(p,C,struct('Tend',12,'TL_step',.05,'TL_time',1,'MaxStep',.001));
verifyGreaterThanOrEqual(tc,min(out.u),p.Vmin);
verifyLessThanOrEqual(tc,max(out.u),p.Vmax);
verifyEqual(tc,out.TL(out.t<1),zeros(nnz(out.t<1),1));
verifyEqual(tc,out.TL(out.t>=1),.05*ones(nnz(out.t>=1),1));
verifyLessThan(tc,max(abs(out.w-fine.w)),1e-4);
verifyTrue(tc,all(isfinite(out.w)));
M=performance_metrics(out); verifyEqual(tc,M.horizon,12);
end
