function C=design_compensator(p,m,compensatorPole,zeta,thirdPole)
%DESIGN_COMPENSATOR Pole placement for Kc*(s+z)/(s+p), assignment plant.
% Adapted from reference/buddy/src; rejects invalid/unstable designs.
% Predictions are linear/unsaturated; they are not physical-model evidence.
if nargin<4, zeta=.7; end
b=p.Kt/(p.La*p.J); a1=(p.La*p.B+p.Ra*p.J)/(p.La*p.J);
a0=(p.Ra*p.B+p.Kt*p.Ke)/(p.La*p.J); S=a1+compensatorPole;
if nargin<5, thirdPole=S/3; end
assert(all(isfinite([compensatorPole,zeta,thirdPole])) && all([compensatorPole,zeta,thirdPole]>0), ...
    'dc_motor:InvalidCompensator','Pole, damping and third pole must be finite and positive.');
wn=(S-thirdPole)/(2*zeta);
assert(wn>0,'dc_motor:InvalidCompensator','Third pole exceeds the available pole sum.');
c1=wn^2+2*zeta*wn*thirdPole; c0=wn^2*thirdPole;
Kc=(c1-a0-a1*compensatorPole)/b;
z=(c0-a0*compensatorPole)/(b*Kc);
assert(isfinite(Kc) && isfinite(z) && Kc>0 && z>0, ...
    'dc_motor:InvalidCompensator','Requested poles require invalid gain or zero.');
C=struct('Kc',Kc,'z',z,'p',compensatorPole,'zeta',zeta,'wn',wn,'thirdPole',thirdPole);
C.tf=tf(Kc*[1,z],[1,compensatorPole]);
C.poles=pole(feedback(C.tf*m.G,1));
assert(all(real(C.poles)<0),'dc_motor:InvalidCompensator','Nominal closed loop must be stable.');
C.relativeError=1/(1+dcgain(m.G)*Kc*z/compensatorPole);
C.denominator=[1,S,c1,c0];
if z>compensatorPole, C.type='lag'; elseif z<compensatorPole, C.type='lead'; else, C.type='gain'; end
end
