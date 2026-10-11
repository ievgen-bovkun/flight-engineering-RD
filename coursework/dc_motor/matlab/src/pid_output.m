function [e,u,raw,eD]=pid_output(x,K,Tf,opt)
%PID_OUTPUT Filtered derivative on measurement and saturated applied voltage.
w=x(2); e=opt.w_ref-w;
eP=opt.beta*opt.w_ref-w; eD=opt.gamma*opt.w_ref-w;
raw=K(1)*eP+x(3)+K(3)*(eD-x(4))/Tf;
if opt.sat, u=min(max(raw,opt.Vmin),opt.Vmax); else, u=raw; end
end
