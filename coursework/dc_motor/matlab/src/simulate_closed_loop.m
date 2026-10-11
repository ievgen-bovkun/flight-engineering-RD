function out=simulate_closed_loop(p,K,opt)
%SIMULATE_CLOSED_LOOP Direct equations; controller states [Iint,xf].
if nargin<3, opt=struct(); end
settings=pid_settings(p,K,opt); opt=settings.opt; Tf=settings.Tf; Tt=settings.Tt;
t=(0:opt.dt:opt.Tend)';
if abs(t(end)-opt.Tend)>1e-12, t=[t;opt.Tend]; end
events=unique([0,opt.Tend,max(0,min(opt.Tend,opt.TL_time))]);
X=zeros(numel(t),4); state=opt.x0(:);
assert(numel(state)==4,'dc_motor:InvalidOptions','Initial PID state must have four elements.');
for j=1:numel(events)-1
    a=events(j); b=events(j+1); TL=0;
    if a>=opt.TL_time, TL=opt.TL_step; end
    f=@(~,x) rhs(x,p,K,Tf,Tt,opt,TL);
    switch lower(opt.solver)
        case 'ode45'
            sol=ode45(f,[a,b],state,odeset('RelTol',p.RelTol,'AbsTol',p.AbsTol,'MaxStep',opt.MaxStep));
            mask=t>=a & t<=b; X(mask,:)=deval(sol,t(mask))'; state=deval(sol,b);
        case 'rk4'
            nodes=unique([a;t(t>a & t<b);b]);
            for n=1:numel(nodes)
                idx=find(abs(t-nodes(n))<1e-12,1);
                if ~isempty(idx), X(idx,:)=state'; end
                if n==numel(nodes), break; end
                h=nodes(n+1)-nodes(n);
                k1=f(0,state); k2=f(0,state+h*k1/2); k3=f(0,state+h*k2/2); k4=f(0,state+h*k3);
                state=state+h*(k1+2*k2+2*k3+k4)/6;
                if any(~isfinite(state)) || max(abs(state))>1e9
                    error('dc_motor:UnstableSimulation','Integration diverged.');
                end
            end
        otherwise
            error('dc_motor:InvalidOptions','Unknown solver: %s',opt.solver);
    end
end
u=zeros(size(t));
for j=1:numel(t), [~,u(j)]=pid_output(X(j,:)',K,Tf,opt); end
out=struct('t',t,'i',X(:,1),'w',X(:,2),'Iint',X(:,3),'xf',X(:,4),'u',u, ...
    'e',opt.w_ref-X(:,2),'K',K(:)','opt',opt,'Tf',Tf,'Tt',Tt,'p',p);
out.TL=opt.TL_step*double(t>=opt.TL_time);
end

function dx=rhs(x,p,K,Tf,Tt,opt,TL)
[e,u,raw,eD]=pid_output(x,K,Tf,opt);
dI=K(2)*e;
if opt.sat && opt.aw && isfinite(Tt), dI=dI+(u-raw)/Tt; end
dx=[(u-p.Ra*x(1)-p.Ke*x(2))/p.La; ...
    (p.Kt*x(1)-p.Bm*x(2)-TL)/(p.Jm+p.JL);dI;(eD-x(4))/Tf];
end
