function [t,X]=plant_reference(p,s)
%PLANT_REFERENCE Direct physical equations, event-aligned ode45 integration.
t=(0:s.outputStep:s.tEnd)'; X=zeros(numel(t),2);
events=[0,s.tEnd];
if isfield(s,'loadTime'), events=[events,s.loadTime]; end
events=unique(events(events>=0 & events<=s.tEnd));
state=s.x0(:);
for j=1:numel(events)-1
    a=events(j); b=events(j+1);
    TL=0;
    if ~isfield(s,'loadTime') || a>=s.loadTime, TL=s.loadTorque; end
    rhs=@(~,x) [(s.voltage-p.Ra*x(1)-p.Ke*x(2))/p.La; ...
        (p.Kt*x(1)-p.Bm*x(2)-TL)/(p.Jm+p.JL)];
    solution=ode45(rhs,[a,b],state,odeset('RelTol',p.RelTol,'AbsTol',p.AbsTol,'MaxStep',.01));
    mask=t>=a & t<=b;
    X(mask,:)=deval(solution,t(mask))';
    state=deval(solution,b);
end
end
