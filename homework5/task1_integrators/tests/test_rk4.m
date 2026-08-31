function tests = test_rk4
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'src'));
end

function testOneStepForConstantDerivative(testCase)
y1 = rk4_step(@(~,~) 3, 0, 2, 0.25);
verifyEqual(testCase, y1, 2.75, 'AbsTol', 1e-14);
end

function testIntegratorHitsFinalTime(testCase)
[T,Y] = rk4_integrate(@(~,~) 1, [0 1], 0, 0.3);
verifyEqual(testCase, T(end), 1, 'AbsTol', 1e-14);
verifyEqual(testCase, Y(end,1), 1, 'AbsTol', 1e-13);
verifyEqual(testCase, diff(T(1:end-1)), 0.3*ones(3,1), 'AbsTol', 1e-14);
verifyEqual(testCase, T(end)-T(end-1), 0.1, 'AbsTol', 1e-14);
end

function testFourthOrderConvergence(testCase)
[~,Y1] = rk4_integrate(@(~,y) y, [0 1], 1, 0.2);
[~,Y2] = rk4_integrate(@(~,y) y, [0 1], 1, 0.1);
ratio = abs(Y1(end)-exp(1))/abs(Y2(end)-exp(1));
verifyGreaterThan(testCase, ratio, 12);
verifyLessThan(testCase, ratio, 20);
end

function testVectorOscillator(testCase)
frequency = 10;
omega = 2*pi*frequency;
rhs = @(~,x) [x(2); -omega^2*x(1)];
[T,Y] = rk4_integrate(rhs, [0 1/frequency], [0; omega], 1/(frequency*200));
verifySize(testCase, Y, [numel(T) 2]);
verifyLessThan(testCase, max(abs(Y(:,1)-sin(omega*T))), 1e-7);
end
