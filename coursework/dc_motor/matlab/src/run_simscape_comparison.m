function r=run_simscape_comparison(p,s,physicalParameters)
%RUN_SIMSCAPE_COMPARISON Physical acceptance depends on measured trace errors.
if nargin<3, physicalParameters=p; end
assert(numel(s.x0)==2 && s.x0(1)==0,'dc_motor:InvalidOptions','Physical harness requires zero initial armature current.');
[r.time,state]=plant_reference(p,s); r.reference=state(:,[2,1]);
[mdl,~]=build_model_simscape(physicalParameters); cleanup=onCleanup(@() close_system(mdl,0));
loadTime=1; if isfield(s,'loadTime'), loadTime=s.loadTime; end
input=Simulink.SimulationInput(mdl);
input=input.setVariable('VinValue',s.voltage,'Workspace',mdl);
input=input.setVariable('TorqueValue',s.loadTorque,'Workspace',mdl);
input=input.setVariable('TorqueTime',loadTime,'Workspace',mdl);
input=input.setVariable('x0',s.x0(:),'Workspace',mdl);
input=input.setModelParameter('StopTime',num2str(s.tEnd),'OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(r.time',15));
result=sim(input); trace=result.get('plantTrace');
assert(trace.Time(1)<=r.time(1) && trace.Time(end)>=r.time(end),'dc_motor:IncompleteTrace','Physical trace has incomplete coverage.');
[times,idx]=unique(trace.Time,'last'); r.physical=interp1(times,trace.Data(idx,:),r.time,'pchip');
assert(all(isfinite(r.physical(:))),'dc_motor:InvalidTrace','Physical model produced invalid data.');
r.maxSpeedError=max(abs(r.physical(:,1)-r.reference(:,1)));
r.maxCurrentError=max(abs(r.physical(:,2)-r.reference(:,2)));
assert(r.maxSpeedError<=1e-3 && r.maxCurrentError<=1e-4,'dc_motor:ComparisonFailed', ...
    'Simscape discrepancy: speed %.8g rad/s, current %.8g A.',r.maxSpeedError,r.maxCurrentError);
r.physicalValidated=true;
writetable(array2table([r.time,r.reference,r.physical],'VariableNames', ...
    {'time_s','omega_reference','current_reference','omega_simscape','current_simscape'}), ...
    fullfile(dc_project_root(),'results','csv',[s.id '.csv']));
end
