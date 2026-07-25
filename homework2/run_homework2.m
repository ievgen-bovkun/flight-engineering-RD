% RUN_HOMEWORK2 Start Homework 2, Task 1 from one file.
% Open this file in MATLAB and press the green Run button.

homeworkDir = fileparts(mfilename('fullpath'));
addpath(genpath(homeworkDir));
cd(fullfile(homeworkDir, 'inverted_pendulum'));
run_pendulum_simulink;
