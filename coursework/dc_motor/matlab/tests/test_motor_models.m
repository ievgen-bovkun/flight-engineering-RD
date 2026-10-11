function tests = test_motor_models
tests = functiontests(localfunctions);
end

function testAssignmentParametersAndIndependentCoefficients(tc)
p = motor_params(); m = motor_models(p);
verifyEqual(tc,[p.Ra,p.La,p.Kt,p.Ke,p.Jm,p.Bm,p.JL],[2,.5,.1,.1,.01,.001,.02]);
verifyEqual(tc,[p.J,p.B],[.03,.001],'AbsTol',1e-14);
verifyEqual(tc,m.den,[.015,.0605,.012],'AbsTol',1e-14);
verifyEqual(tc,m.A,[-4,-.2;10/3,-1/30],'AbsTol',1e-14);
verifyEqual(tc,m.Bu,[2;0]); verifyEqual(tc,m.Bd,[0;-100/3],'AbsTol',1e-14);
verifyEqual(tc,dcgain(m.G),25/3,'AbsTol',1e-12);
verifyEqual(tc,dcgain(m.Gd),-500/3,'AbsTol',1e-11);
end

function testLoadedAndUnloadedEquilibria(tc)
m = motor_models(motor_params());
verifyEqual(tc,m.A*[1;100]+m.Bu*12,[0;0],'AbsTol',1e-12);
verifyEqual(tc,m.A*[1.5;100]+m.Bu*13+m.Bd*.05,[0;0],'AbsTol',1e-12);
end

function testZeroInputAndOpposingTorque(tc)
p=motor_params(); m=motor_models(p);
verifyEqual(tc,m.A*zeros(2,1),zeros(2,1));
verifyLessThan(tc,m.Bd(2),0);
end

function testInvalidPhysicalParameterRejected(tc)
p=motor_params(); p.La=0;
verifyError(tc,@() motor_models(p),'dc_motor:InvalidParameters');
end
