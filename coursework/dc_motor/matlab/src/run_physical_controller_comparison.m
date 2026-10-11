function r=run_physical_controller_comparison(p,controller,scenario)
%RUN_PHYSICAL_CONTROLLER_COMPARISON Common actual voltage/speed/current traces.
if nargin<3, scenario=struct(); end
if ~isfield(scenario,'Tend'), scenario.Tend=12; end
if isnumeric(controller), out=simulate_closed_loop(p,controller,scenario);
else, out=simulate_compensator(p,controller,scenario); end
[mdl,~]=build_compensated_model(p,controller,scenario); cleanup=onCleanup(@() close_system(mdl,0));
input=Simulink.SimulationInput(mdl);
input=input.setModelParameter('OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(out.t',15));
result=sim(input); plant=result.get('plantTrace'); voltage=result.get('voltageTrace');
physical=out;
physicalStates=resample(plant,out.t); physical.w=physicalStates(:,1); physical.i=physicalStates(:,2);
physical.u=resample(voltage,out.t); physical.e=physical.opt.w_ref-physical.w;
r.maxErrors=[max(abs(physical.w-out.w)),max(abs(physical.i-out.i)),max(abs(physical.u-out.u))];
assert(all(isfinite(r.maxErrors)) && all(r.maxErrors<=[1e-3,1e-4,1e-3]), ...
    'dc_motor:ComparisonFailed','Physical closed-loop errors [speed,current,voltage]=[%g,%g,%g].',r.maxErrors);
r.physicalValidated=true; r.reference=out; r.physical=physical;
r.referenceMetrics=performance_metrics(out); r.physicalMetrics=performance_metrics(physical);
end

function data=resample(trace,t)
assert(trace.Time(1)<=t(1) && trace.Time(end)>=t(end),'dc_motor:IncompleteTrace','Physical trace does not cover the comparison grid.');
[times,idx]=unique(trace.Time,'last'); data=interp1(times,trace.Data(idx,:),t,'pchip');
assert(all(isfinite(data(:))),'dc_motor:InvalidTrace','Physical controller produced invalid samples.');
end
