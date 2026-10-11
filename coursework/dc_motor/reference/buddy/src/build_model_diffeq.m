function mdl = build_model_diffeq(p, outdir)
%BUILD_MODEL_DIFFEQ  Метод 1: модель ДПС блоками за диференціальними рівняннями.
%
%   mdl = BUILD_MODEL_DIFFEQ(p, outdir) програмно створює та зберігає
%   Simulink-модель, зібрану безпосередньо з рівнянь стану:
%
%       di/dt     = (1/La) * ( Vin - Ra*i - Ke*omega )
%       domega/dt = (1/J)  * ( Kt*i - B*omega - TL   )
%
%   Кожне рівняння реалізовано ланцюгом Sum -> Gain -> Integrator,
%   а зворотні зв'язки (Ra*i, Ke*omega, B*omega) замикаються підсилювачами.
%   Ядро двигуна упаковано в підсистему "Motor Model Subsystem" (вимога 2.6).
%
%   Вхід TL уже присутній - у розділі 2.1 він дорівнює нулю (TL_step = 0),
%   а в розділі 2.5 та сама модель використовується зі збуренням 0.05 Нм.

if nargin < 2, outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'models'); end
if ~exist(outdir, 'dir'), mkdir(outdir); end

mdl = 'motor_diffeq';
push_params(p);

if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

sub = [mdl '/Motor Model Subsystem'];
add_block('simulink/Ports & Subsystems/Subsystem', sub, 'Position', [220 90 400 210]);
delete_line(sub, 'In1/1', 'Out1/1');
delete_block([sub '/In1']);
delete_block([sub '/Out1']);

% ================== вміст підсистеми ==================
B_ = @(name) [sub '/' name];

add_block('simulink/Sources/In1',  B_('Vin'), 'Port','1', 'Position',[ 30  98  60 112]);
add_block('simulink/Sources/In1',  B_('TL'),  'Port','2', 'Position',[ 30 258  60 272]);

% --- електричне рівняння: Vin - Ra*i - Ke*omega ---
add_block('simulink/Math Operations/Sum', B_('Sum_V'), ...
    'Inputs','+--', 'IconShape','rectangular', 'Position',[110  85 130 135]);
add_block('simulink/Math Operations/Gain', B_('inv_La'), ...
    'Gain','1/La', 'Position',[165  95 195 125]);
add_block('simulink/Continuous/Integrator', B_('Int_i'), ...
    'InitialCondition','0', 'Position',[225  95 255 125]);

% --- електромагнітний момент Kt*i ---
add_block('simulink/Math Operations/Gain', B_('Kt_gain'), ...
    'Gain','Kt', 'Position',[300  95 330 125]);

% --- механічне рівняння: Kt*i - B*omega - TL ---
add_block('simulink/Math Operations/Sum', B_('Sum_T'), ...
    'Inputs','+--', 'IconShape','rectangular', 'Position',[370  85 390 135]);
add_block('simulink/Math Operations/Gain', B_('inv_J'), ...
    'Gain','1/J', 'Position',[425  95 455 125]);
add_block('simulink/Continuous/Integrator', B_('Int_w'), ...
    'InitialCondition','0', 'Position',[485  95 515 125]);

% --- зворотні зв'язки (орієнтація 'left' = сигнал іде справа наліво) ---
add_block('simulink/Math Operations/Gain', B_('Ra_gain'), ...
    'Gain','Ra', 'Orientation','left', 'Position',[225 175 255 205]);
add_block('simulink/Math Operations/Gain', B_('Ke_gain'), ...
    'Gain','Ke', 'Orientation','left', 'Position',[225 320 255 350]);
add_block('simulink/Math Operations/Gain', B_('B_gain'), ...
    'Gain','B',  'Orientation','left', 'Position',[425 175 455 205]);

% --- виходи підсистеми: omega та струм якоря i ---
add_block('simulink/Sinks/Out1', B_('omega_out'), 'Port','1', 'Position',[570  98 600 112]);
add_block('simulink/Sinks/Out1', B_('i_out'),     'Port','2', 'Position',[570 148 600 162]);

L = @(a,b) add_line(sub, a, b, 'autorouting', 'on');
L('Vin/1',      'Sum_V/1');
L('Sum_V/1',    'inv_La/1');
L('inv_La/1',   'Int_i/1');
L('Int_i/1',    'Kt_gain/1');
L('Kt_gain/1',  'Sum_T/1');
L('Sum_T/1',    'inv_J/1');
L('inv_J/1',    'Int_w/1');
L('Int_w/1',    'omega_out/1');
L('Int_i/1',    'Ra_gain/1');     % відгалуження: i -> Ra
L('Ra_gain/1',  'Sum_V/2');
L('Int_w/1',    'Ke_gain/1');     % відгалуження: omega -> Ke
L('Ke_gain/1',  'Sum_V/3');
L('Int_w/1',    'B_gain/1');      % відгалуження: omega -> B
L('B_gain/1',   'Sum_T/2');
L('TL/1',       'Sum_T/3');
L('Int_i/1',    'i_out/1');

% ================== верхній рівень ==================
add_block('simulink/Sources/Step', [mdl '/Vin'], ...
    'Time','0', 'Before','0', 'After','V_step', 'Position',[ 80 105 110 135]);
add_block('simulink/Sources/Step', [mdl '/TL'], ...
    'Time','TL_time', 'Before','0', 'After','TL_step', 'Position',[ 80 165 110 195]);

add_block('simulink/Sinks/To Workspace', [mdl '/omega_log'], ...
    'VariableName','omega', 'SaveFormat','Structure With Time', ...
    'SampleTime','-1', 'Position',[470 100 530 130]);
add_block('simulink/Sinks/To Workspace', [mdl '/i_log'], ...
    'VariableName','i_a', 'SaveFormat','Structure With Time', ...
    'SampleTime','-1', 'Position',[470 160 530 190]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'Position',[470 230 500 260]);

add_line(mdl, 'Vin/1',                    'Motor Model Subsystem/1', 'autorouting','on');
add_line(mdl, 'TL/1',                     'Motor Model Subsystem/2', 'autorouting','on');
add_line(mdl, 'Motor Model Subsystem/1',  'omega_log/1',             'autorouting','on');
add_line(mdl, 'Motor Model Subsystem/2',  'i_log/1',                 'autorouting','on');
add_line(mdl, 'Motor Model Subsystem/1',  'Scope/1',                 'autorouting','on');

% ================== налаштування розв'язувача ==================
set_param(mdl, 'Solver','ode45', 'StopTime','30', ...
               'RelTol','1e-8', 'AbsTol','1e-10', 'MaxStep','0.01');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
fprintf('  [OK] Збережено модель: %s\n', fullfile(outdir, [mdl '.slx']));
end
