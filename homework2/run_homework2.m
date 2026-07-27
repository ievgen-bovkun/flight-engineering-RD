% RUN_HOMEWORK2 Run Homework 2 Task 1 validation and Task 2 NED visualization.
% Open this file in MATLAB and press the green Run button.

homeworkDir = fileparts(mfilename('fullpath'));
addpath(genpath(homeworkDir));
cd(fullfile(homeworkDir, 'inverted_pendulum'));
generate_task1_results;

cd(fullfile(homeworkDir, 'ned_rotations'));
generate_ned_figure;

cd(homeworkDir);
fprintf('Homework 2 figures were saved in inverted_pendulum/assets and ned_rotations/assets.\n');
