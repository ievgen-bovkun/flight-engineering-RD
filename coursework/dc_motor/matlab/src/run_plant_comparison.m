function r=run_plant_comparison(p,s)
%RUN_PLANT_COMPARISON Measure agreement without relying on base workspace.
set(groot,'defaultFigureVisible','off');
[r.time,state]=plant_reference(p,s); r.reference=state(:,[2,1]);
builders={@build_model_diffeq,@build_model_statespace};
r.maxSpeedError=zeros(1,2); r.maxCurrentError=zeros(1,2); r.traces=cell(1,2);
for k=1:2
    [mdl,~]=builders{k}(p);
    cleanup=onCleanup(@() close_system(mdl,0));
    loadTime=1; if isfield(s,'loadTime'), loadTime=s.loadTime; end
    input=Simulink.SimulationInput(mdl);
    input=input.setVariable('VinValue',s.voltage,'Workspace',mdl);
    input=input.setVariable('TorqueValue',s.loadTorque,'Workspace',mdl);
    input=input.setVariable('TorqueTime',loadTime,'Workspace',mdl);
    input=input.setVariable('x0',s.x0(:),'Workspace',mdl);
    input=input.setModelParameter('StopTime',num2str(s.tEnd), ...
        'OutputOption','SpecifiedOutputTimes','OutputTimes',mat2str(r.time',15));
    output=sim(input); trace=output.get('plantTrace');
    assert(trace.Time(1)<=r.time(1) && trace.Time(end)>=r.time(end), ...
        'dc_motor:IncompleteTrace','Simulation does not cover requested times.');
    % States are continuous at the load event; no extrapolation is permitted.
    [times,idx]=unique(trace.Time,'last');
    y=interp1(times,trace.Data(idx,:),r.time,'pchip');
    r.traces{k}=y;
    r.maxSpeedError(k)=max(abs(y(:,1)-r.reference(:,1)));
    r.maxCurrentError(k)=max(abs(y(:,2)-r.reference(:,2)));
    clear cleanup
end
assert(all(r.maxSpeedError<=1e-4) && all(r.maxCurrentError<=1e-5), ...
    'dc_motor:ComparisonFailed','Plant comparison exceeded speed/current tolerance.');
csvDir=fullfile(dc_project_root(),'results','csv'); if ~isfolder(csvDir), mkdir(csvDir); end
values=[r.time,r.reference,r.traces{1},r.traces{2}];
names={'time_s','omega_reference','current_reference','omega_diffeq','current_diffeq','omega_statespace','current_statespace'};
writetable(array2table(values,'VariableNames',names),fullfile(csvDir,[s.id '.csv']));
end
