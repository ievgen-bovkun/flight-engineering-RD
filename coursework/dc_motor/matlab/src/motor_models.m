function m=motor_models(p)
%MOTOR_MODELS State order [i;omega]; positive TL opposes shaft rotation.
values=[p.Ra,p.La,p.Kt,p.Ke,p.Jm,p.JL,p.Bm];
if any(~isfinite(values)) || any(values(1:6)<=0) || p.Bm<0
    error('dc_motor:InvalidParameters','Electrical/inertia constants must be positive, damping nonnegative.');
end
J=p.Jm+p.JL; B=p.Bm;
m.den=[p.La*J,p.La*B+p.Ra*J,p.Ra*B+p.Kt*p.Ke];
m.G=tf(p.Kt,m.den); m.Gd=tf(-[p.La,p.Ra],m.den);
m.A=[-p.Ra/p.La,-p.Ke/p.La;p.Kt/J,-B/J];
m.Bu=[1/p.La;0]; m.Bd=[0;-1/J];
m.C=[0,1;1,0]; m.D=zeros(2);
m.sys=ss(m.A,[m.Bu,m.Bd],m.C,m.D);
m.Kdc=dcgain(m.G); m.poles=pole(m.G);
end
