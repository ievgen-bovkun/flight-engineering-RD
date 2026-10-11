function settings=pid_settings(p,K,opt)
%PID_SETTINGS One controller definition for ODE, Simulink and Python export.
if nargin<3, opt=struct(); end
if numel(K)~=3 || any(~isfinite(K)) || any(K<0) || K(1)<=0
    error('dc_motor:InvalidGains','Expected finite nonnegative [Kp Ki Kd], with Kp>0.');
end
d=struct('Tend',p.Tsim,'dt',p.dt,'N',p.derivativeRatio,'sat',true,'aw',true, ...
    'Vmax',p.Vmax,'Vmin',p.Vmin,'TL_step',0,'TL_time',1,'w_ref',p.w_ref, ...
    'beta',p.beta,'gamma',p.gamma,'solver','ode45','MaxStep',.001,'x0',zeros(4,1));
names=fieldnames(d);
for j=1:numel(names), if ~isfield(opt,names{j}), opt.(names{j})=d.(names{j}); end; end
if opt.Tend<=0 || opt.dt<=0 || opt.N<=0 || opt.Vmin>=opt.Vmax || ~isfinite(opt.TL_time)
    error('dc_motor:InvalidOptions','Invalid horizon, time step, filter, limits or finite load event time.');
end
Tf=max(K(3)/(opt.N*K(1)),p.minimumFilterTime);
if K(2)>0
    Ti=K(1)/K(2); Td=K(3)/K(1);
    if Td>0, Tt=sqrt(Ti*Td); else, Tt=Ti; end
else
    Tt=Inf;
end
settings=struct('K',K(:)','Tf',Tf,'Tt',Tt,'opt',opt);
end
