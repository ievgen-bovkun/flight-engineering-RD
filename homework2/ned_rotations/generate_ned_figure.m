function outputPath = generate_ned_figure()
%GENERATE_NED_FIGURE Save the Task 2 NED figure for the report.

projectDir = fileparts(mfilename('fullpath'));
assetDir = fullfile(projectDir, 'assets');
if ~isfolder(assetDir)
    mkdir(assetDir);
end

plot_ned_rotations();
outputPath = fullfile(assetDir, 'ned_roll_pitch_yaw.png');
exportgraphics(gcf, outputPath, 'Resolution', 180);
end
