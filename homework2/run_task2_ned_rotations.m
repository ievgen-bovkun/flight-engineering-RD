% RUN_TASK2_NED_ROTATIONS Generate the NED roll-pitch-yaw visualization.
% Open this file in MATLAB and press the green Run button.

homeworkDir = fileparts(mfilename('fullpath'));
addpath(genpath(homeworkDir));
cd(fullfile(homeworkDir, 'ned_rotations'));
generate_ned_figure;
