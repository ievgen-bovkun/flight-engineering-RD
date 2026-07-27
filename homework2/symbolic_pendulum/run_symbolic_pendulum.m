function result = run_symbolic_pendulum(showDetails)
%RUN_SYMBOLIC_PENDULUM Derive and validate the inverted-pendulum equations.

if nargin < 1
    showDetails = true;
end

if exist('syms', 'file') ~= 2
    error(['Symbolic Math Toolbox is required for Task 3. Install it via ', ...
        'MathWorks Installer or Add-On Explorer, then run this script again.']);
end

homeworkDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(homeworkDir, 'inverted_pendulum'));

model = derive_pendulum_model();
P = pendulum_params();
variables = [model.symbols.M, model.symbols.m, model.symbols.b, ...
    model.symbols.I, model.symbols.l, model.symbols.g];
values = [P.M, P.m, P.b, P.I, P.l, P.g];

result.model = model;
result.numericA = double(subs(model.A, variables, values));
result.numericB = double(subs(model.B, variables, values));
result.maxDifferenceA = max(abs(result.numericA - P.A), [], 'all');
result.maxDifferenceB = max(abs(result.numericB - P.B), [], 'all');

if showDetails
    disp('Nonlinear cart equation:');
    disp(model.nonlinear.cartEquation);
    disp('Nonlinear pendulum equation:');
    disp(model.nonlinear.pendulumEquation);
    disp('Linearized A matrix:');
    disp(model.A);
    disp('Linearized B matrix:');
    disp(model.B);
    fprintf('Maximum A difference from CTMS: %.3e\n', result.maxDifferenceA);
    fprintf('Maximum B difference from CTMS: %.3e\n', result.maxDifferenceB);
end
end
