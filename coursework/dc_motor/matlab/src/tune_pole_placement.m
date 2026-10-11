function [K,info]=tune_pole_placement(p,m,zeta,wn,p3)
%TUNE_POLE_PLACEMENT Nominal ideal PID design; validate actual filtered loop.
if nargin<3, zeta=1; end
if nargin<4, wn=5; end
if nargin<5, p3=4*zeta*wn; end
b=p.Kt/(p.La*(p.Jm+p.JL)); a=m.den(2:3)/m.den(1);
K=[(wn^2+2*zeta*wn*p3-a(2))/b,wn^2*p3/b,(2*zeta*wn+p3-a(1))/b];
info.den_cl=[1,a(1)+b*K(3),a(2)+b*K(1),b*K(2)];
info.actual_poles=roots(info.den_cl);
info.desired_poles=[roots([1,2*zeta*wn,wn^2]);-p3];
info.sys_cl=tf(b*[K(1),K(2)],info.den_cl);
end
