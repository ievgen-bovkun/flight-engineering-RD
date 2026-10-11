function r=run_pid_comparison(p,K,opt)
%RUN_PID_COMPARISON Assert speed, current and applied-voltage equivalence.
r.reference=simulate_closed_loop(p,K,opt); opt=r.reference.opt;
r.maxErrors=zeros(2,3); kinds={'diffeq','statespace'}; r.traces=cell(1,2);
for k=1:2
    [mdl,~]=build_model_pid(p,K,kinds{k},opt);
    cleanup=onCleanup(@() close_system(mdl,0));
    input=Simulink.SimulationInput(mdl);
    input=input.setModelParameter('OutputOption','SpecifiedOutputTimes', ...
        'OutputTimes',mat2str(r.reference.t',15));
    simout=sim(input); y=simout.get('plantTrace'); v=simout.get('voltageTrace');
    [ty,iy]=unique(y.Time,'last'); [tv,iv]=unique(v.Time,'last');
    assert(ty(1)<=r.reference.t(1) && ty(end)>=r.reference.t(end),'dc_motor:IncompleteTrace','Incomplete PID trace.');
    values=[interp1(ty,y.Data(iy,:),r.reference.t,'pchip'),interp1(tv,v.Data(iv,:),r.reference.t,'pchip')];
    expected=[r.reference.w,r.reference.i,r.reference.u];
    r.maxErrors(k,:)=max(abs(values-expected),[],1); r.traces{k}=values;
    clear cleanup
end
assert(all(r.maxErrors<=[1e-4,1e-5,1e-3],'all'),'dc_motor:ComparisonFailed', ...
    'PID speed/current/voltage comparison exceeded tolerance: %s',mat2str(r.maxErrors));
end
