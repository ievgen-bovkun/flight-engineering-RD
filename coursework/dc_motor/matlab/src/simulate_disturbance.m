function out=simulate_disturbance(p,K,opt)
%SIMULATE_DISTURBANCE Optional observer and shared PID law with live callback.
if nargin<3, opt=struct(); end
settings=pid_settings(p,K,opt); opt=settings.opt;
if ~isfield(opt,'obs'), opt.obs=[]; end
if ~isfield(opt,'ff'), opt.ff=false; end
if ~isfield(opt,'OutputFcn'), opt.OutputFcn=[]; end
useObs=~isempty(opt.obs);
assert(~opt.ff || useObs,'dc_motor:InvalidOptions','Feedforward requires observer gain.');
if ~useObs && isempty(opt.OutputFcn)
    out=simulate_closed_loop(p,K,opt); return
end
t=(0:opt.dt:opt.Tend)'; X=zeros(numel(t),4+3*useObs); state=[opt.x0(:);zeros(3*useObs,1)];
m=motor_models(p); Aa=[m.A,m.Bd;0,0,0]; Ba=[m.Bu;0];
events=unique([0,opt.Tend,max(0,min(opt.Tend,opt.TL_time))]);
for j=1:numel(events)-1
    a=events(j); b=events(j+1); TL=0; if a>=opt.TL_time, TL=opt.TL_step; end
    odeopt=odeset('RelTol',p.RelTol,'AbsTol',p.AbsTol,'MaxStep',opt.MaxStep);
    if ~isempty(opt.OutputFcn), odeopt=odeset(odeopt,'OutputFcn',opt.OutputFcn); end
    sol=ode45(@rhs,[a,b],state,odeopt);
    mask=t>=a & t<=b; X(mask,:)=deval(sol,t(mask))'; state=deval(sol,b);
end
u=zeros(size(t));
for j=1:numel(t), u(j)=appliedVoltage(X(j,:)'); end
out=struct('t',t,'i',X(:,1),'w',X(:,2),'Iint',X(:,3),'xf',X(:,4),'u',u, ...
    'e',opt.w_ref-X(:,2),'K',K(:)','opt',opt,'Tf',settings.Tf,'Tt',settings.Tt,'p',p, ...
    'TL',opt.TL_step*double(t>=opt.TL_time));
if useObs, out.i_hat=X(:,5); out.w_hat=X(:,6); out.TL_hat=X(:,7); end

    function [u,raw]=appliedVoltage(x)
        [~,~,raw]=pid_output(x,K,settings.Tf,opt);
        if opt.ff, raw=raw+p.Ra*x(7)/p.Kt; end
        u=raw; if opt.sat, u=min(max(u,opt.Vmin),opt.Vmax); end
    end
    function dx=rhs(~,x)
        [e,~,~,eD]=pid_output(x,K,settings.Tf,opt); [u,raw]=appliedVoltage(x);
        dI=K(2)*e;
        if opt.sat && opt.aw && isfinite(settings.Tt), dI=dI+(u-raw)/settings.Tt; end
        dx=[(u-p.Ra*x(1)-p.Ke*x(2))/p.La; ...
            (p.Kt*x(1)-p.Bm*x(2)-TL)/(p.Jm+p.JL);dI;(eD-x(4))/settings.Tf];
        if useObs, dx=[dx;Aa*x(5:7)+Ba*u+opt.obs(:)*(x(2)-x(6))]; end
    end
end
