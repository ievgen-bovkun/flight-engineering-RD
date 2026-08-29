%RUN_DZ4_VARIANT1 Rebuild, simulate, verify visually, and export DZ4 results.

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'scripts'));

result = dz4_export_artifacts(dz4_run(1));

fprintf('DZ4 variant %d completed.\n', result.cfg.variant_id);
fprintf('Max MATLAB/Simulink difference: %.3e\n', result.max_abs_error);
fprintf('Altitude dip: %.4f m at t = %.3f s\n', ...
    result.altitude_dip_m, result.altitude_dip_time_s);
fprintf('Results folder: %s\n', fullfile(projectDir, 'results'));
