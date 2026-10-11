function tests=test_optimization
tests=functiontests(localfunctions);
end

function testObjectiveUsesCanonicalMetricsAndBothRequiredTerms(tc)
p=motor_params(); K=[11.0456,21.89,1.3288];
cfg=struct('lambda',.2,'IAE_ref',90,'effort_ref',110,'penalty',0, ...
    'simopt',struct('solver','rk4','dt',.001));
[cost,M]=pid_cost(K,p,cfg);
verifyTrue(tc,isfinite(cost)); verifyTrue(tc,isfield(M,'effort2'));
verifyEqual(tc,cost,M.iae/90+.2*M.effort/110,'AbsTol',1e-12);
cfg.lambda=.4; [cost2,M2]=pid_cost(K,p,cfg);
verifyEqual(tc,cost2-cost,.2*M2.effort/110,'AbsTol',1e-12);
end

function testInvalidGainsRejectedRatherThanMasked(tc)
verifyError(tc,@() pid_cost([NaN,1,1],motor_params(),struct()),'dc_motor:InvalidGains');
end

function testGeneticSearchDeterministicAndBounded(tc)
f=@(x) sum((x-[.25,-.4]).^2); opt=struct('pop',8,'gen',6,'seed',7,'verbose',false);
[a,fa]=ga_simple(f,[-1,-1],[1,1],opt); [b,fb]=ga_simple(f,[-1,-1],[1,1],opt);
verifyEqual(tc,a,b); verifyEqual(tc,fa,fb);
verifyTrue(tc,all(a>=-1 & a<=1));
verifyLessThan(tc,fa,1);
end

function testOptimizerProducesARealSmokeResult(tc)
p=motor_params(); cfg=struct('MaxFunEvals',12,'gaPop',6,'gaGen',2,'seed',7, ...
    'simopt',struct('solver','rk4','dt',.001),'verbose',false);
R=optimize_pid(p,cfg,[11.0456,21.89,1.3288]);
verifyTrue(tc,all(isfinite(R.K)) && isfinite(R.score));
verifyGreaterThan(tc,R.evaluations,0);
verifyTrue(tc,all(R.K>=R.bounds(1,:) & R.K<=R.bounds(2,:)));
end

function testMissingOrStaleGainsCannotBeLoaded(tc)
verifyError(tc,@() load_optimized_gains(fullfile(tempdir,'no_such_dc_motor_result.json')), ...
    'dc_motor:MissingOptimization');
file=[tempname '.json']; cleanup=onCleanup(@() delete(file));
record=struct('K',[11,21,1],'provenance',struct('parametersSHA256','stale','scenariosSHA256','stale'));
fid=fopen(file,'w'); fprintf(fid,'%s',jsonencode(record)); fclose(fid);
verifyError(tc,@() load_optimized_gains(file),'dc_motor:StaleOptimization');
end
