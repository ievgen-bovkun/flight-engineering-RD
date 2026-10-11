function mdl = build_model_statespace(p, m, outdir)
%BUILD_MODEL_STATESPACE  Метод 2: модель ДПС у просторі станів.
%
%   mdl = BUILD_MODEL_STATESPACE(p, m, outdir) створює Simulink-модель на
%   базі одного блока State-Space з матрицями:
%
%       A  = [ -Ra/La  -Ke/La ;  Kt/J  -B/J ]      x = [i; omega]
%       B  = [  1/La    0     ;  0     -1/J ]      u = [Vin; TL]
%       C  = [  0       1     ]                    y = omega
%       D  = [  0       0     ]
%
%   Два входи зводяться у вектор блоком Mux. Модель математично тотожна
%   методу 1, але компактніша й зручніша для синтезу регуляторів.

if nargin < 3, outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'models'); end
if ~exist(outdir, 'dir'), mkdir(outdir); end

mdl = 'motor_statespace';
push_params(p, m);

if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

add_block('simulink/Sources/Step', [mdl '/Vin'], ...
    'Time','0', 'Before','0', 'After','V_step', 'Position',[ 60  95  90 125]);
add_block('simulink/Sources/Step', [mdl '/TL'], ...
    'Time','TL_time', 'Before','0', 'After','TL_step', 'Position',[ 60 165  90 195]);

add_block('simulink/Signal Routing/Mux', [mdl '/Mux'], ...
    'Inputs','2', 'Position',[140 100 145 190]);

add_block('simulink/Continuous/State-Space', [mdl '/Motor SS'], ...
    'A','A_m', 'B','B_m', 'C','C_m', 'D','D_m', 'X0','X0_m', ...
    'Position',[200 120 310 170]);

add_block('simulink/Sinks/To Workspace', [mdl '/omega_log'], ...
    'VariableName','omega_ss', 'SaveFormat','Structure With Time', ...
    'SampleTime','-1', 'Position',[370 130 430 160]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'Position',[370 200 400 230]);

add_line(mdl, 'Vin/1',      'Mux/1',       'autorouting','on');
add_line(mdl, 'TL/1',       'Mux/2',       'autorouting','on');
add_line(mdl, 'Mux/1',      'Motor SS/1',  'autorouting','on');
add_line(mdl, 'Motor SS/1', 'omega_log/1', 'autorouting','on');
add_line(mdl, 'Motor SS/1', 'Scope/1',     'autorouting','on');

set_param(mdl, 'Solver','ode45', 'StopTime','30', ...
               'RelTol','1e-8', 'AbsTol','1e-10', 'MaxStep','0.01');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
fprintf('  [OK] Збережено модель: %s\n', fullfile(outdir, [mdl '.slx']));
end
