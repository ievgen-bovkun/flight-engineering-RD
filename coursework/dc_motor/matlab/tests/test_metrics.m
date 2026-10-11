function tests=test_metrics
tests=functiontests(localfunctions);
end

function out=fixture(w,ref)
out.t=(0:numel(w)-1)'; out.w=w(:); out.u=12*ones(size(out.t));
out.i=ones(size(out.t)); out.opt=struct('w_ref',ref,'Vmin',-48,'Vmax',48);
out.p=motor_params();
end

function testLastExitNotFirstEntry(tc)
M=performance_metrics(fixture([0,99,103,100,100,100,100],100));
verifyEqual(tc,M.t_first,1); verifyEqual(tc,M.ts,3);
verifyEqual(tc,M.os,3); verifyEqual(tc,M.ess,0);
verifyEqual(tc,M.effort,72); verifyEqual(tc,M.effort2,864);
verifyTrue(tc,M.settled); verifyTrue(tc,M.essValidated);
end

function testNeverSettlingAndFinalExcursion(tc)
M=performance_metrics(fixture([0,80,80,80],100)); verifyEqual(tc,M.ts,Inf);
M=performance_metrics(fixture([0,100,100,103],100)); verifyEqual(tc,M.ts,Inf);
verifyFalse(tc,M.settled);
end

function testSignedAndZeroReference(tc)
M=performance_metrics(fixture([0,-100,-103,-100,-100],-100));
verifyEqual(tc,M.ts,3); verifyEqual(tc,M.os,3);
M=performance_metrics(fixture([0,.01,0,0],0)); verifyEqual(tc,M.ts,0);
verifyEqual(tc,M.os,0); verifyTrue(tc,isfinite(M.iae));
end

function testNonfiniteTrajectoryRejected(tc)
out=fixture([0,NaN,100],100);
verifyError(tc,@() performance_metrics(out),'dc_motor:InvalidTrace');
out=fixture([0,100,100],100); out.t=[0;0;1];
verifyError(tc,@() performance_metrics(out),'dc_motor:InvalidTrace');
end
