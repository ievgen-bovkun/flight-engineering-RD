function tests = test_tff_zoh
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'));
end

function testContinuousModelMatchesGivenTransferFunction(testCase)
model = tff_continuous_model();
expected = tf([0.3333], [1 1 33.33]);
w = logspace(-2, 3, 100);
actualResponse = squeeze(freqresp(model.sys, w));
expectedResponse = squeeze(freqresp(expected, w));
verifyLessThan(testCase, max(abs(actualResponse-expectedResponse)), 1e-12);
end

function testOwnZohMatchesMatlabC2d(testCase)
model = tff_continuous_model();
sampleTime = 0.01;
[Ad,Bd,Cd,Dd] = exact_zoh_discretize(model.A, model.B, model.C, model.D, sampleTime);
reference = c2d(model.sys, sampleTime, 'zoh');
[Ar,Br,Cr,Dr] = ssdata(reference);
verifyEqual(testCase, Ad, Ar, 'AbsTol', 1e-12);
verifyEqual(testCase, Bd, Br, 'AbsTol', 1e-12);
verifyEqual(testCase, Cd, Cr, 'AbsTol', 0);
verifyEqual(testCase, Dd, Dr, 'AbsTol', 0);
end

function testRecurrenceUsesCurrentInputAndInitialState(testCase)
[Y,X] = simulate_discrete_ss(2, 1, 1, 0, [1;2;3], 0);
verifyEqual(testCase, X, [0;1;4], 'AbsTol', 0);
verifyEqual(testCase, Y, [0;1;4], 'AbsTol', 0);
end
