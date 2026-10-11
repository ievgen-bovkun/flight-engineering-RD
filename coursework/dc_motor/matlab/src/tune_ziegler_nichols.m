function [K,info]=tune_ziegler_nichols(~,m)
%TUNE_ZIEGLER_NICHOLS Analytical reaction-curve tangent for this motor.
rates=sort(-real(m.poles)); a=rates(1); b=rates(2);
assert(all(rates>0) && abs(a-b)>1e-10,'dc_motor:UnsupportedPlant','Reaction curve expects distinct stable real poles.');
tinf=log(b/a)/(b-a);
y=m.Kdc*(1-(b*exp(-a*tinf)-a*exp(-b*tinf))/(b-a));
slope=m.Kdc*a*b*(exp(-a*tinf)-exp(-b*tinf))/(b-a);
L=tinf-y/slope; Ti=2*L; Td=.5*L; Kp=1.2/(slope*L);
K=[Kp,Kp/Ti,Kp*Td];
info=struct('Ku',Inf,'L',L,'T',m.Kdc/slope,'R',slope,'t_infl',tinf, ...
    'note','Ultimate-gain method has no finite Ku for this delay-free second-order plant.');
end
