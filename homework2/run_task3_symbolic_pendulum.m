% RUN_TASK3_SYMBOLIC_PENDULUM Derive the pendulum equations symbolically.
% Requires Symbolic Math Toolbox.

homeworkDir = fileparts(mfilename('fullpath'));
addpath(genpath(homeworkDir));
cd(fullfile(homeworkDir, 'symbolic_pendulum'));
run_symbolic_pendulum;
