function mdl = build_model_pid(p, K, kind, outdir)
%BUILD_MODEL_PID  Замкнений контур з ПІД-регулятором у Simulink (розділ 2.2).
%
%   mdl = BUILD_MODEL_PID(p, K, kind, outdir)
%     kind - 'diffeq'     (типово) об'єкт із блоків за диф. рівняннями
%            'statespace' об'єкт одним блоком State-Space
%   Обидва варіанти дають однакову підсистему "Motor Model Subsystem" з
%   двома входами (Vin, TL) та виходом omega, тому решта схеми ідентична.
%   Це і є перехресна перевірка методів моделювання у замкненому контурі.
%
%   Схема:  уставка -> [PID (2-DOF)] -> напруга -> [Motor Model Subsystem] -> omega
%                                                                        |
%                                                        зворотний зв'язок
%
%   Використано блок "PID Controller (2DOF)", бо він штатно підтримує все,
%   що потрібно у цьому проєкті:
%     * вагові коефіцієнти уставки b та c. Ставимо b = 1, c = 0 - це і є
%       похідна по вимірюванню (структура PI-D), без "derivative kick";
%     * фільтр похідної з коефіцієнтом N;
%     * вбудоване обмеження виходу + anti-windup зворотним перерахунком.
%   Ці налаштування точно відповідають функції SIMULATE_CLOSED_LOOP, тому
%   результати Simulink і скриптової моделі мають збігатися.
%
%   ЯКЩО set_param спіткнеться на імені параметра (вони дещо різняться між
%   релізами MATLAB) - відкрийте діалог блока PID і виставте вручну:
%     Controller: PID | Form: Parallel | Time domain: Continuous-time
%     P = Kp, I = Ki, D = Kd, N = 20
%     Setpoint weight b = 1, c = 0
%     Output saturation: Limit output, Upper = Vmax, Lower = Vmin
%     Anti-windup method: back-calculation, Kb = 1/Tt

if nargin < 3 || isempty(kind), kind = 'diffeq'; end
if nargin < 4, outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'models'); end
if ~exist(outdir, 'dir'), mkdir(outdir); end

switch lower(kind)
    case 'diffeq',     mdl = 'motor_pid';
    case 'statespace', mdl = 'motor_pid_ss';
    otherwise, error('build_model_pid:kind', 'kind має бути diffeq або statespace');
end

m = motor_models(p);
push_params(p, m);
assignin('base', 'Kp', K(1));
assignin('base', 'Ki', K(2));
assignin('base', 'Kd', K(3));
assignin('base', 'Nf', 20);

% Коефіцієнт anti-windup: Kb = 1/Tt, Tt = sqrt(Ti*Td)
Ti = K(1)/K(2);  Td = K(3)/K(1);  Tt = sqrt(Ti*Td);
assignin('base', 'Kb', 1/Tt);

if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

% --- об'єкт керування ---
sub = [mdl '/Motor Model Subsystem'];
if strcmpi(kind, 'diffeq')
    % Копіюємо готову підсистему з моделі розділу 2.1
    mdl_de = build_model_diffeq(p);
    load_system(mdl_de);
    add_block([mdl_de '/Motor Model Subsystem'], sub, 'Position', [430 90 580 170]);
    close_system(mdl_de, 0);
else
    % Той самий інтерфейс, але всередині один блок State-Space
    add_block('simulink/Ports & Subsystems/Subsystem', sub, 'Position', [430 90 580 170]);
    delete_line(sub, 'In1/1', 'Out1/1');
    delete_block([sub '/In1']);  delete_block([sub '/Out1']);
    add_block('simulink/Sources/In1',  [sub '/Vin'], 'Port','1', 'Position',[ 40  93  70 107]);
    add_block('simulink/Sources/In1',  [sub '/TL'],  'Port','2', 'Position',[ 40 163  70 177]);
    add_block('simulink/Signal Routing/Mux', [sub '/Mux'], 'Inputs','2', ...
              'Position',[120 95 125 175]);
    add_block('simulink/Continuous/State-Space', [sub '/Motor SS'], ...
              'A','A_m', 'B','B_m', 'C','C_m', 'D','D_m', 'X0','X0_m', ...
              'Position',[180 110 300 160]);
    add_block('simulink/Sinks/Out1', [sub '/omega_out'], 'Port','1', ...
              'Position',[360 128 390 142]);
    add_line(sub, 'Vin/1',      'Mux/1',       'autorouting','on');
    add_line(sub, 'TL/1',       'Mux/2',       'autorouting','on');
    add_line(sub, 'Mux/1',      'Motor SS/1',  'autorouting','on');
    add_line(sub, 'Motor SS/1', 'omega_out/1', 'autorouting','on');
end

% --- уставка та збурення ---
add_block('simulink/Sources/Step', [mdl '/Setpoint'], ...
    'Time','0', 'Before','0', 'After','w_ref', 'Position',[ 40 105  70 135]);
add_block('simulink/Sources/Step', [mdl '/TL'], ...
    'Time','TL_time', 'Before','0', 'After','TL_step', 'Position',[350 195 380 225]);

% --- регулятор ---
pidblk = [mdl '/PID'];
add_block('simulink/Continuous/PID Controller (2DOF)', pidblk, ...
    'Position', [190 95 280 165]);
pidparams = { ...
    'Controller','PID', 'TimeDomain','Continuous-time', 'Form','Parallel', ...
    'P','Kp', 'I','Ki', 'D','Kd', 'N','Nf', ...
    'b','1', 'c','0', ...
    'LimitOutput','on', 'UpperSaturationLimit','Vmax', ...
    'LowerSaturationLimit','Vmin', ...
    'AntiWindupMode','back-calculation', 'Kb','Kb'};
for k = 1:2:numel(pidparams)
    try
        set_param(pidblk, pidparams{k}, pidparams{k+1});
    catch ME
        warning('PID: не вдалося встановити ''%s'' (%s). Виставте вручну.', ...
                pidparams{k}, ME.identifier);
    end
end

% --- реєстрація сигналів ---
add_block('simulink/Sinks/To Workspace', [mdl '/omega_log'], ...
    'VariableName','omega_cl', 'SaveFormat','Structure With Time', ...
    'SampleTime','-1', 'Position',[660 100 720 130]);
if strcmpi(kind, 'diffeq')
    add_block('simulink/Sinks/To Workspace', [mdl '/i_log'], ...
        'VariableName','i_cl', 'SaveFormat','Structure With Time', ...
        'SampleTime','-1', 'Position',[660 250 720 280]);
end
add_block('simulink/Sinks/To Workspace', [mdl '/u_log'], ...
    'VariableName','u_cl', 'SaveFormat','Structure With Time', ...
    'SampleTime','-1', 'Position',[330  40 390  70]);
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'Position',[660 180 690 210]);

L = @(a,b) add_line(mdl, a, b, 'autorouting','on');
L('Setpoint/1',               'PID/1');      % вхід уставки  (2-DOF)
L('Motor Model Subsystem/1',  'PID/2');      % вхід вимірювання (зворотний зв'язок)
L('PID/1',                    'Motor Model Subsystem/1');
L('PID/1',                    'u_log/1');
L('TL/1',                     'Motor Model Subsystem/2');
L('Motor Model Subsystem/1',  'omega_log/1');
L('Motor Model Subsystem/1',  'Scope/1');
if strcmpi(kind, 'diffeq')
    L('Motor Model Subsystem/2', 'i_log/1');   % струм якоря доступний лише тут
end

set_param(mdl, 'Solver','ode45', 'StopTime', num2str(p.Tsim), ...
               'RelTol','1e-8', 'AbsTol','1e-10', 'MaxStep','0.001');

save_system(mdl, fullfile(outdir, [mdl '.slx']));
fprintf('  [OK] Збережено модель: %s\n', fullfile(outdir, [mdl '.slx']));
end
