function M=performance_metrics(out,w_ref,band)
%PERFORMANCE_METRICS Explicit time horizon, reference band and effort units.
if nargin<2, w_ref=out.opt.w_ref; end
if nargin<3, band=.02; end
t=out.t(:); w=out.w(:); u=out.u(:); i=out.i(:);
if numel(t)<2 || any(diff(t)<=0) || any([numel(w),numel(u),numel(i)]~=numel(t)) ...
        || any(~isfinite([t;w;u;i;w_ref])) || band<=0
    error('dc_motor:InvalidTrace','Finite equal-length traces and strictly increasing time are required.');
end
e=w_ref-w; width=band*max(abs(w_ref),1); outside=abs(e)>width;
last=find(outside,1,'last'); first=find(~outside,1,'first');
if isempty(last), M.ts=0; elseif last==numel(t), M.ts=Inf; else, M.ts=t(last+1)-t(1); end
if isempty(first), M.t_first=Inf; else, M.t_first=t(first)-t(1); end
if w_ref==0, M.os=0; else, M.os=max(0,100*(max(sign(w_ref)*w)-abs(w_ref))/abs(w_ref)); end
M.endpointError=abs(e(end));
tail=t>=t(end)-min(.5,.1*(t(end)-t(1)));
M.essValidated=(max(w(tail))-min(w(tail)))<=1e-3*max(abs(w_ref),1);
M.ess=abs(w_ref-mean(w(tail)));
M.iae=trapz(t,abs(e)); M.ise=trapz(t,e.^2); M.itae=trapz(t,(t-t(1)).*abs(e));
M.effort=trapz(t,abs(u)); M.effort2=trapz(t,u.^2);
M.energy_net=trapz(t,u.*i); M.copper_loss=trapz(t,out.p.Ra*i.^2);
M.settled=isfinite(M.ts); M.status='not_settled'; if M.settled, M.status='settled'; end
M.horizon=t(end)-t(1); M.Tsim=M.horizon;
M.umax=max(u); M.umin=min(u); M.imax=max(abs(i));
M.tsat=trapz(t,double(u>=out.opt.Vmax-1e-6 | u<=out.opt.Vmin+1e-6));
end
