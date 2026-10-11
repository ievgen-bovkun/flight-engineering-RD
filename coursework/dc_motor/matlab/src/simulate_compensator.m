function out=simulate_compensator(p,C,opt)
%SIMULATE_COMPENSATOR Direct motor equations plus dynamic compensator state.
% u_raw=Kc*e+Kc*(z-p)*xc; dxc=-p*xc+e+(u-u_raw)/(g2*Tt).
% Event-segmented integration; results are not labelled Simscape.
if nargin<3, opt=struct(); end
defaults=struct('Tend',12,'dt',p.dt,'sat',true,'aw',true,'Vmax',p.Vmax,'Vmin',p.Vmin, ...
    'TL_step',0,'TL_time',1,'w_ref',p.w_ref,'Tt',.1,'MaxStep',.01,'x0',[0;0;0]);
names=fieldnames(defaults);
for j=1:numel(names), if ~isfield(opt,names{j}), opt.(names{j})=defaults.(names{j}); end; end
values=[opt.Tend,opt.dt,opt.Vmin,opt.Vmax,opt.TL_step,opt.TL_time,opt.w_ref,opt.Tt,opt.MaxStep,opt.x0(:)'];
assert(all(isfinite(values)) && opt.Tend>0 && opt.dt>0 && opt.Vmax>opt.Vmin && ...
    opt.Tt>0 && opt.MaxStep>0 && numel(opt.x0)==3,'dc_motor:InvalidOptions','Invalid compensator scenario.');
assert(all(isfinite([C.Kc,C.z,C.p])) && all([C.Kc,C.z,C.p]>0), ...
    'dc_motor:InvalidCompensator','Compensator must have positive finite gain, pole and zero.');
g2=C.Kc*(C.z-C.p); t=(0:opt.dt:opt.Tend)';
if abs(t(end)-opt.Tend)>1e-12, t=[t;opt.Tend]; end
events=unique([0,opt.Tend,max(0,min(opt.Tend,opt.TL_time))]);
X=zeros(numel(t),3); state=opt.x0(:);
for j=1:numel(events)-1
    a=events(j); b=events(j+1); TL=0; if a>=opt.TL_time, TL=opt.TL_step; end
    sol=ode45(@(~,x) rhs(x,p,C,g2,opt,TL),[a,b],state, ...
        odeset('RelTol',p.RelTol,'AbsTol',p.AbsTol,'MaxStep',opt.MaxStep));
    mask=t>=a & t<=b; X(mask,:)=deval(sol,t(mask))'; state=deval(sol,b);
end
raw=C.Kc*(opt.w_ref-X(:,2))+g2*X(:,3); u=raw;
if opt.sat, u=min(max(raw,opt.Vmin),opt.Vmax); end
assert(all(isfinite(X(:))) && all(isfinite(u)),'dc_motor:UnstableSimulation','Compensator integration failed.');
out=struct('t',t,'i',X(:,1),'w',X(:,2),'xc',X(:,3),'u',u,'e',opt.w_ref-X(:,2), ...
    'TL',opt.TL_step*double(t>=opt.TL_time),'C',C,'opt',opt,'p',p);
end

function dx=rhs(x,p,C,g2,opt,TL)
e=opt.w_ref-x(2); raw=C.Kc*e+g2*x(3); u=raw;
if opt.sat, u=min(max(raw,opt.Vmin),opt.Vmax); end
dxc=-C.p*x(3)+e;
if opt.sat && opt.aw && abs(g2)>1e-12, dxc=dxc+(u-raw)/(g2*opt.Tt); end
dx=[(u-p.Ra*x(1)-p.Ke*x(2))/p.La;(p.Kt*x(1)-p.B*x(2)-TL)/p.J;dxc];
end
