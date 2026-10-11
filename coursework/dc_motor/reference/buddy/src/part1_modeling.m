%% PART1_MODELING - Розділ 2.1: моделювання системи "ДПС + навантаження"
%
%  Скрипт виконує три речі:
%    1) будує аналітичні моделі (передавальна функція + простір станів);
%    2) доводить їх математичну еквівалентність;
%    3) створює й запускає дві Simulink-моделі (диф. рівняння та простір
%       станів) і порівнює всі чотири відгуки на один ступінчастий сигнал.
%
%  Модель Simscape додається у розділі 2.6 і вмикається в те саме
%  порівняння.
%
%  Запуск:  >> part1_modeling

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

%% 1. Параметри та аналітичні моделі
p = motor_params();
m = motor_models(p);

fprintf('===== 2.1 МОДЕЛЮВАННЯ СИСТЕМИ =====\n\n');
fprintf('Сумарна інерція   J = Jm + JL = %.2f + %.2f = %.3f кг*м^2\n', p.Jm, p.JL, p.J);
fprintf('Сумарне тертя     B = Bm      = %.4f Нм*с/рад\n\n', p.B);

fprintf('Передавальна функція omega(s)/Vin(s):\n');
disp(m.G);
fprintf('У нормованому вигляді: %.4f / (s^2 + %.4f*s + %.4f)\n\n', ...
        m.num/m.den(1), m.den(2)/m.den(1), m.den(3)/m.den(1));

fprintf('Полюси:            %.4f  та  %.4f  (1/с)\n', m.poles(1), m.poles(2));
fprintf('Сталі часу:        %.4f  та  %.4f  с\n', m.tau(1), m.tau(2));
fprintf('Статичний коеф.:   %.4f рад/(с*В)\n', m.Kdc);
fprintf('Напруга для %.0f рад/с: %.3f В\n', p.w_ref, m.V_ss);
fprintf('Чутливість до моменту: %.2f рад/(с*Нм) -> збурення %.2f Нм дає %.2f рад/с\n\n', ...
        m.Kdc_dist, p.TL_step, p.TL_step*m.Kdc_dist);

%% 2. Перевірка еквівалентності двох аналітичних форм
G_from_ss = tf(m.sys_u);
fprintf('--- Перевірка: простір станів -> передавальна функція ---\n');
fprintf('Характеристичний поліном A: ');  fprintf('%.6g  ', poly(m.A));  fprintf('\n');
fprintf('Знаменник G(s) (нормований): '); fprintf('%.6g  ', m.den/m.den(1)); fprintf('\n');
fprintf('Максимальна різниця полюсів: %.3e\n\n', ...
        max(abs(sort(pole(G_from_ss)) - sort(m.poles))));

%% 3. Побудова Simulink-моделей
fprintf('--- Побудова Simulink-моделей ---\n');
mdl_de = build_model_diffeq(p);
mdl_ss = build_model_statespace(p, m);

%% 4. Симуляція розімкненої системи: ступінь 12 В, TL = 0
V_step  = m.V_ss;      % 12 В -> точно 100 рад/с у сталому режимі
TL_step = 0;           % у розділі 2.1 збурення відсутнє
Tend    = p.Tsim_ol;
assignin('base','V_step',  V_step);
assignin('base','TL_step', TL_step);

t = (0:p.dt:Tend)';

% (а) передавальна функція
y_tf = step(V_step * m.G, t);

% (б) простір станів
y_ss = lsim(m.sys, [V_step*ones(size(t)), zeros(size(t))], t);

% (в) Simulink, диф. рівняння
so_de = sim(mdl_de, 'StopTime', num2str(Tend));
[t_de, y_de] = get_logged(so_de, 'omega');

% (г) Simulink, простір станів
so_ss = sim(mdl_ss, 'StopTime', num2str(Tend));
[t_sl, y_sl] = get_logged(so_ss, 'omega_ss');

%% 5. Кількісне порівняння методів
y_de_i = interp1(t_de, y_de, t, 'linear', 'extrap');
y_sl_i = interp1(t_sl, y_sl, t, 'linear', 'extrap');

fprintf('\n--- Порівняння методів моделювання ---\n');
fprintf('max|ПФ - простір станів|        = %.3e рад/с\n', max(abs(y_tf - y_ss)));
fprintf('max|ПФ - Simulink (диф. рівн.)| = %.3e рад/с\n', max(abs(y_tf - y_de_i)));
fprintf('max|ПФ - Simulink (простір ст.)|= %.3e рад/с\n', max(abs(y_tf - y_sl_i)));

si = stepinfo(y_tf, t, y_tf(end));
fprintf('\n--- Показники розімкненої системи (12 В) ---\n');
fprintf('Стале значення:            %.3f рад/с\n', y_tf(end));
fprintf('Час наростання 10-90%%:     %.3f с\n', si.RiseTime);
fprintf('Час перех. процесу (2%%):   %.3f с   <-- вимога 2.2: %.1f с\n', si.SettlingTime, p.ts_spec);
fprintf('Перерегулювання:           %.3f %%\n', si.Overshoot);
fprintf('\nВисновок: без регулятора система у %.1f разів повільніша за вимогу.\n', ...
        si.SettlingTime / p.ts_spec);

%% 6. Графіки
f = figure('Name','2.1 Порівняння методів моделювання','Position',[100 100 900 620]);

subplot(2,1,1); hold on; grid on;
plot(t, y_tf, 'LineWidth', 2.5, 'Color', [0.00 0.45 0.74]);
plot(t, y_ss, '--', 'LineWidth', 2.0, 'Color', [0.85 0.33 0.10]);
plot(t_de, y_de, ':',  'LineWidth', 2.0, 'Color', [0.47 0.67 0.19]);
plot(t_sl, y_sl, '-.', 'LineWidth', 1.5, 'Color', [0.49 0.18 0.56]);
yline(p.w_ref, 'k:', 'Ціль 100 рад/с');
xlabel('Час, с'); ylabel('\omega, рад/с');
title(sprintf('Відгук розімкненої системи на ступінь %.0f В', V_step));
legend({'Передавальна функція','Простір станів (аналітично)', ...
        'Simulink: диф. рівняння','Simulink: простір станів','Ціль'}, ...
        'Location','southeast');

subplot(2,1,2); hold on; grid on;
plot(t, y_tf - y_ss,   'LineWidth', 1.5);
plot(t, y_tf - y_de_i, 'LineWidth', 1.5);
plot(t, y_tf - y_sl_i, 'LineWidth', 1.5);
xlabel('Час, с'); ylabel('Відхилення, рад/с');
title('Різниця між методами (рівень числової похибки розв''язувача)');
legend({'ПФ - простір станів','ПФ - Simulink диф. рівн.','ПФ - Simulink простір ст.'}, ...
        'Location','best');

saveas(f, fullfile(resdir, 'part1_model_comparison.png'));
fprintf('\nГрафік збережено: %s\n', fullfile(resdir, 'part1_model_comparison.png'));

save(fullfile(resdir, 'part1_results.mat'), 'p', 'm', 't', 'y_tf', 'y_ss', 'si');

%% ---------- допоміжна функція ----------
function [t, y] = get_logged(so, name)
%GET_LOGGED  Дістає сигнал з блока To Workspace незалежно від версії MATLAB.
if isa(so, 'Simulink.SimulationOutput')
    s = so.get(name);
else
    s = evalin('base', name);
end
t = s.time;
y = squeeze(s.signals.values);
end
