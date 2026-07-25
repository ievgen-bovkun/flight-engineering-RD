function out = run_simulink_demo(showFigure)
%RUN_SIMULINK_DEMO One-click Simulink entry point for Task 1.
% Open this file in MATLAB and press the green Run button.

if nargin < 1
    showFigure = true;
end

rootDir = fileparts(mfilename('fullpath'));
simulinkDir = fullfile(rootDir, 'simulink');
addpath(simulinkDir);

build_quadrotor_simulink(true);
out = run_simulink_channel('vertical', showFigure);

fprintf(['Simulink vertical test completed. The model is open and the ', ...
    'Position scope should show z decreasing below -10 m (climb in NED).\n']);
end
