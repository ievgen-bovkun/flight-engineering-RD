function obs=design_observer(p,poles)
%DESIGN_OBSERVER Estimate constant opposing load torque from measured speed.
if nargin<2, poles=[-30,-35,-40]; end
m=motor_models(p);
obs.A=[m.A,m.Bd;0,0,0]; obs.B=[m.Bu;0]; obs.C=[0,1,0];
obs.rank_obsv=rank(obsv(obs.A,obs.C));
assert(obs.rank_obsv==3,'dc_motor:Unobservable','Augmented load state is unobservable.');
obs.L=place(obs.A',obs.C',poles)'; obs.poles=eig(obs.A-obs.L*obs.C);
assert(all(real(obs.poles)<0),'dc_motor:UnstableObserver','Observer must be stable.');
end
