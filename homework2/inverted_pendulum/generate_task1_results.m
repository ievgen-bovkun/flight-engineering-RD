function result = generate_task1_results()
%GENERATE_TASK1_RESULTS Create the comparison plot used in the Task 1 report.

projectDir = fileparts(mfilename('fullpath'));
assetDir = fullfile(projectDir, 'assets');
if ~isfolder(assetDir)
    mkdir(assetDir);
end

result = run_pendulum_comparison(true);
exportgraphics(gcf, fullfile(assetDir, 'task1_method_comparison.png'), ...
    'Resolution', 180);

fprintf('Maximum error, analytical vs MATLAB RK4: %.3e\n', ...
    result.maxError.analyticVsRk4);
fprintf('Maximum error, analytical vs Simulink: %.3e\n', ...
    result.maxError.analyticVsSimulink);
fprintf('Maximum error, MATLAB RK4 vs Simulink: %.3e\n', ...
    result.maxError.rk4VsSimulink);
end
