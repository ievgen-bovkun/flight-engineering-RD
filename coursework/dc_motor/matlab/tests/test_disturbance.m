function tests=test_disturbance
tests=functiontests(localfunctions);
end

function testRequiredLoadPreservesPerformanceAndEquilibrium(tc)
p=motor_params(); K=load_optimized_gains();
out=simulate_closed_loop(p,K,struct('TL_step',.05,'TL_time',1,'Tend',6));
M=performance_metrics(out);
verifyLessThanOrEqual(tc,M.ts,2); verifyLessThanOrEqual(tc,M.os,5);
verifyEqual(tc,out.w(end),100,'AbsTol',.001);
verifyEqual(tc,out.i(end),1.5,'AbsTol',.001);
verifyEqual(tc,out.u(end),13,'AbsTol',.001);
end

function testRecoveryBeyondEndReturnsExplicitStatus(tc)
R=disturbance_recovery([0;1;2],[0;0;5],1,2);
verifyEqual(tc,R.recoveryTime,Inf); verifyFalse(tc,R.recovered);
R=disturbance_recovery([0;1;2;3],[0;5;1;0],1,2);
verifyEqual(tc,R.recoveryTime,1); verifyTrue(tc,R.recovered);
end

function testObserverIsObservableAndConverges(tc)
p=motor_params(); obs=design_observer(p,[-30,-35,-40]);
verifyEqual(tc,rank(obsv(obs.A,obs.C)),3);
verifyLessThan(tc,max(real(eig(obs.A-obs.L*obs.C))),0);
K=load_optimized_gains();
out=simulate_disturbance(p,K,struct('Tend',5,'TL_step',.5,'TL_time',3,'obs',obs.L,'ff',true));
verifyEqual(tc,out.TL_hat(end),.5,'AbsTol',1e-4);
verifyEqual(tc,out.w(end),100,'AbsTol',.001);
end

function testLiveUpdatesUseSameTrajectory(tc)
p=motor_params(); K=load_optimized_gains(); dirPath=tempname;
cleanup=onCleanup(@() removePreview(dirPath));
opt=struct('Tend',.3,'TL_step',0,'realTime',false,'visible',false,'outputDir',dirPath);
r=live_visualization(p,K,opt);
ref=simulate_closed_loop(p,K,struct('Tend',.3));
verifyGreaterThan(tc,r.updateCount,1); verifyTrue(tc,isfile(fullfile(dirPath,'latest.png')));
verifyEqual(tc,r.out.w,ref.w,'AbsTol',1e-6);
end

function removePreview(folder)
assert(startsWith(folder,tempdir),'Preview cleanup must stay within the test temporary directory.');
if isfolder(folder), rmdir(folder,'s'); end
end
