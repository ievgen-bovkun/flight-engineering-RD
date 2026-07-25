% RUN_HOMEWORK2 Run the completed Homework 2, Task 1 comparison.
% Open this file in MATLAB and press the green Run button.

homeworkDir = fileparts(mfilename('fullpath'));
addpath(genpath(homeworkDir));
cd(fullfile(homeworkDir, 'inverted_pendulum'));
generate_task1_results;
