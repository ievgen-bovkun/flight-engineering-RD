function tests = test_rkf45
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'));
end

function testConstantDerivativeIsExact(testCase)
[y4,y5,errorVector] = rkf45_step(@(~,~) [2;-3], 0, [1;4], 0.25);
expected = [1.5;3.25];
verifyEqual(testCase, y4, expected, 'AbsTol', 1e-14);
verifyEqual(testCase, y5, expected, 'AbsTol', 1e-14);
verifyEqual(testCase, errorVector, zeros(2,1), 'AbsTol', 1e-14);
end

function testFifthOrderEstimateBeatsFourthOrder(testCase)
[y4,y5,~] = rkf45_step(@(~,y) y, 0, 1, 0.2);
truth = exp(0.2);
verifyLessThan(testCase, abs(y5-truth), abs(y4-truth));
end

function testAdaptiveIntegratorRejectsLargeTrial(testCase)
opts = struct('h0',0.1,'tolerance',1e-9,'hMin',1e-8,'hMax',0.1);
[T,Y,stats] = rkf45_integrate(@(~,y) 50*y, [0 0.1], 1, opts);
verifyGreaterThan(testCase, stats.rejectedSteps, 0);
verifyEqual(testCase, T(end), 0.1, 'AbsTol', 1e-14);
verifyLessThan(testCase, abs(Y(end)-exp(5)), 2e-5);
verifyEqual(testCase, stats.acceptedSteps, numel(T)-1);
end

function testStepBoundsAndVectorState(testCase)
opts = struct('h0',0.01,'tolerance',1e-8,'hMin',1e-5,'hMax',0.08);
[T,Y,stats] = rkf45_integrate(@(~,~) [0;0], [0 0.2], [3;-1], opts);
verifyEqual(testCase, Y, repmat([3 -1], numel(T), 1), 'AbsTol', 0);
verifyLessThanOrEqual(testCase, max(stats.trialStepSizes), opts.hMax);
verifyEqual(testCase, T(end), 0.2, 'AbsTol', 1e-14);
end

function testVectorOscillator(testCase)
frequency = 10;
omega = 2*pi*frequency;
rhs = @(~,x) [x(2); -omega^2*x(1)];
opts = struct('h0',1/(4*frequency),'tolerance',1e-8,'hMin',1e-9,'hMax',1/(2*frequency));
[T,Y,~] = rkf45_integrate(rhs, [0 1/frequency], [0;omega], opts);
verifySize(testCase, Y, [numel(T) 2]);
verifyLessThan(testCase, max(abs(Y(:,1)-sin(omega*T))), 2e-7);
end
