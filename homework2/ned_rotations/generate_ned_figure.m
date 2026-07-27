function outputPath = generate_ned_figure()
%GENERATE_NED_FIGURE Save the Task 2 NED figure for the report.

projectDir = fileparts(mfilename('fullpath'));
assetDir = fullfile(projectDir, 'assets');
if ~isfolder(assetDir)
    mkdir(assetDir);
end

plot_ned_rotations();
outputPath = fullfile(assetDir, 'ned_yaw_pitch_roll_sequence.png');
exportgraphics(gcf, outputPath, 'Resolution', 180);

plot_ned_rotation_steps();
stepOutputPath = fullfile(assetDir, 'ned_yaw_pitch_roll_steps.png');
exportgraphics(gcf, stepOutputPath, 'Resolution', 180);
end
