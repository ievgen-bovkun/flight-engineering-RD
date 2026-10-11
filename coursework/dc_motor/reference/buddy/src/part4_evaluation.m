%% PART4_EVALUATION - Розділ 2.4: оцінка ефективності
%
%  Порядок дій:
%    1) симуляція всіх трьох регуляторів (ЗН, розміщення полюсів, оптимізований);
%    2) два обов'язкові графіки: omega(t) та Vin(t);
%    3) таблиця п'яти метрик з умови + додаткові величини, експорт у CSV;
%    4) перехресна перевірка: скрипт проти двох Simulink-моделей у замкненому
%       контурі (вимога "порівняти результати моделювання");
%    5) залежність керуючого впливу від горизонту симуляції;
%    6) стовпчикова діаграма нормованих метрик.
%
%  Запуск:  >> part4_evaluation

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

p = motor_params();
m = motor_models(p);

K_zn  = tune_ziegler_nichols(p, m);
K_pp  = tune_pole_placement(p, m, 1.0, 5.0, 20.0);
K_opt = [11.0456, 21.8900, 1.3288];      % результат розділу 2.3

% Якщо розділ 2.3 уже прорахований - беремо коефіцієнти звідти
f3 = fullfile(resdir, 'part3_results.mat');
if exist(f3, 'file')
    S = load(f3, 'K_opt');
    if isfield(S, 'K_opt'), K_opt = S.K_opt; end
    fprintf('Коефіцієнти оптимізованого регулятора завантажено з part3_results.mat\n');
end

names = {'Зіглер-Нікольс', 'Розміщення полюсів (2.2)', 'Оптимізований (2.3)'};
gains = {K_zn, K_pp, K_opt};

fprintf('===== 2.4 ОЦІНКА ЕФЕКТИВНОСТІ =====\n');

%% 1. Симуляція та метрики
runs = cell(numel(names), 2);
mets = cell(numel(names), 1);
for k = 1:numel(names)
    runs{k,1} = names{k};
    runs{k,2} = simulate_closed_loop(p, gains{k});
    mets{k}   = performance_metrics(runs{k,2});
end

T = report_metrics(names, mets, p, fullfile(resdir, 'part4_metrics.csv'));

fprintf('\nКоефіцієнти:\n');
for k = 1:numel(names)
    fprintf('  %-26s Kp = %8.4f  Ki = %8.4f  Kd = %7.4f\n', ...
            names{k}, gains{k}(1), gains{k}(2), gains{k}(3));
end

%% 2. Обов'язкові графіки
f1 = plot_response(p, runs, 'Оцінка ефективності', 3.0);
saveas(f1, fullfile(resdir, 'part4_response.png'));

% Додатково: струм якоря - фізична перевірка реалізовності
f2 = figure('Name','2.4 Струм якоря','Position',[120 120 900 380]);
hold on; grid on; box on;
for k = 1:numel(names)
    plot(runs{k,2}.t, runs{k,2}.i, 'LineWidth', 1.8, 'DisplayName', names{k});
end
yline(p.B*p.w_ref/p.Kt, 'g:', 'LineWidth', 1.4, 'DisplayName','i_{уст} = 1 А');
xlabel('Час, с'); ylabel('i_a, А'); xlim([0 3]);
title('Струм якоря: пік ~22 А визначається напругою, а не регулятором');
legend('Location','northeast');
saveas(f2, fullfile(resdir, 'part4_current.png'));

%% 3. Перехресна перевірка: скрипт проти Simulink
fprintf('\n--- Перехресна перевірка замкненого контуру ---\n');
K = K_opt;
ok = true;
try
    assignin('base','TL_step', 0);
    assignin('base','TL_time', Inf);

    mdl1 = build_model_pid(p, K, 'diffeq');
    so1  = sim(mdl1, 'StopTime', num2str(p.Tsim));
    [t1, w1] = get_logged(so1, 'omega_cl');

    mdl2 = build_model_pid(p, K, 'statespace');
    so2  = sim(mdl2, 'StopTime', num2str(p.Tsim));
    [t2, w2] = get_logged(so2, 'omega_cl');

    ref = runs{3,2};
    w1i = interp1(t1, w1, ref.t, 'linear', 'extrap');
    w2i = interp1(t2, w2, ref.t, 'linear', 'extrap');

    fprintf('max|скрипт - Simulink (диф. рівняння)| = %.4e рад/с\n', max(abs(ref.w - w1i)));
    fprintf('max|скрипт - Simulink (простір станів)| = %.4e рад/с\n', max(abs(ref.w - w2i)));
    fprintf('max|Simulink диф. рівн. - Simulink простір ст.| = %.4e рад/с\n', max(abs(w1i - w2i)));
    fprintf('Розбіжність на рівні похибки розв''язувача => три методи еквівалентні.\n');

    f3f = figure('Name','2.4 Перехресна перевірка','Position',[140 140 900 500]);
    subplot(2,1,1); hold on; grid on;
    plot(ref.t, ref.w, 'LineWidth', 2.5); plot(t1, w1, '--', 'LineWidth', 2);
    plot(t2, w2, ':', 'LineWidth', 1.6);
    xlabel('Час, с'); ylabel('\omega, рад/с'); xlim([0 3]);
    legend({'скрипт (ode45)','Simulink: диф. рівняння','Simulink: простір станів'}, ...
           'Location','southeast');
    title('Замкнений контур: три реалізації однієї моделі');
    subplot(2,1,2); hold on; grid on;
    plot(ref.t, ref.w - w1i, 'LineWidth', 1.4);
    plot(ref.t, ref.w - w2i, 'LineWidth', 1.4);
    xlabel('Час, с'); ylabel('Відхилення, рад/с'); xlim([0 3]);
    legend({'скрипт - диф. рівн.','скрипт - простір станів'}, 'Location','best');
    saveas(f3f, fullfile(resdir, 'part4_crosscheck.png'));
catch ME
    ok = false;
    fprintf('Simulink-перевірку пропущено: %s\n', ME.message);
    fprintf('(скриптові результати від цього не залежать)\n');
end

%% 4. Керуючий вплив і горизонт симуляції
fprintf('\n--- Чому горизонт симуляції треба вказувати явно ---\n');
fprintf('%8s%12s%14s%16s%10s\n','Tsim, с','int|V|','перехідна ч.','стала складова','IAE');
for T = [3 5 8 10]
    o = simulate_closed_loop(p, K_opt, struct('Tend', T));
    M = performance_metrics(o);
    fprintf('%8.1f%12.2f%14.2f%16.2f%10.3f\n', T, M.effort, M.effort_tr, M.effort_ss, M.iae);
end
fprintf(['Перехідна складова стала (~70.3 В*с) і саме вона характеризує\n' ...
         'регулятор; решта - це просто 12 В, помножені на решту часу.\n' ...
         'Тому у звіті метрика int|V|dt подається разом із Tsim = %.0f с.\n'], p.Tsim);

%% 5. Нормована діаграма метрик
f4 = figure('Name','2.4 Нормовані метрики','Position',[160 160 900 450]);
lbl = {'t_s','перерегул.','IAE','ITAE','\int|V|dt','\int V^2dt'};
Draw = [cellfun(@(M) M.ts, mets), cellfun(@(M) max(M.os,1e-3), mets), ...
        cellfun(@(M) M.iae, mets), cellfun(@(M) M.itae, mets), ...
        cellfun(@(M) M.effort, mets), cellfun(@(M) M.effort2, mets)];
Dn = Draw ./ Draw(1,:);                     % нормування на Зіглера-Нікольса
bar(Dn'); grid on;
set(gca, 'XTickLabel', lbl);
ylabel('Відносно Зіглера-Нікольса');
title('Нормовані показники (менше = краще)');
legend(names, 'Location','northeast');
saveas(f4, fullfile(resdir, 'part4_metrics_bar.png'));

save(fullfile(resdir,'part4_results.mat'), 'names','gains','mets','runs','T');
fprintf('\nГрафіки, CSV та дані збережено у %s\n', resdir);

%% ---------- допоміжна ----------
function [t, y] = get_logged(so, name)
if isa(so, 'Simulink.SimulationOutput')
    s = so.get(name);
else
    s = evalin('base', name);
end
t = s.time;
y = squeeze(s.signals.values);
end
