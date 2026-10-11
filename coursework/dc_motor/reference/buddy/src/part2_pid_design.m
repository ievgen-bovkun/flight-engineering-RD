%% PART2_PID_DESIGN - Розділ 2.2: проєктування системи керування
%
%  Порядок дій:
%    1) перевірка фізичної досяжності вимоги (вибір напруги живлення);
%    2) налаштування за Зіглером-Нікольсом (метод кривої розгону);
%    3) аналітичний синтез методом розміщення полюсів;
%    4) симуляція обох варіантів з насиченням та anti-windup;
%    5) графіки omega(t) і Vin(t), таблиця показників.
%
%  Запуск:  >> part2_pid_design

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

p = motor_params();
m = motor_models(p);

fprintf('===== 2.2 ПРОЄКТУВАННЯ СИСТЕМИ КЕРУВАННЯ =====\n');

%% 1. Чи досяжна вимога взагалі?
fb = check_feasibility(p, m);
fprintf('\n--- Перевірка досяжності (стратегія "повний газ") ---\n');
fprintf('Для %.0f рад/с у сталому режимі достатньо %.2f В.\n', p.w_ref, fb.V_ss);
fprintf('%-10s %s\n', 'Vmax, В', 'мін. час досягнення 100 рад/с, с');
for k = 1:numel(fb.V)
    if isinf(fb.t_reach(k))
        fprintf('%-10.0f  недосяжно\n', fb.V(k));
    else
        ok = ''; if fb.t_reach(k) < p.ts_spec, ok = '  <-- вкладається'; end
        fprintf('%-10.0f  %.3f%s\n', fb.V(k), fb.t_reach(k), ok);
    end
end
fprintf('\nМінімальна напруга, щоб лише ДОТОРКНУТИСЯ 100 рад/с за %.0f с: %.2f В\n', ...
        p.ts_spec, fb.V_min_touch);
fprintf('Обрано Vmax = %.0f В (стандартна шина + запас на гальмування).\n', p.Vmax);
if p.Vmax < fb.V_min_touch
    warning('Vmax = %.0f В НЕ дозволяє виконати вимогу %.0f с!', p.Vmax, p.ts_spec);
end

%% 2. Зіглер-Нікольс
[K_zn, zn] = tune_ziegler_nichols(p, m);
fprintf('\n--- Зіглер-Нікольс ---\n');
fprintf('%s\n', zn.note);
fprintf('Крива розгону: точка перегину t = %.4f с, нахил R = %.4f 1/с\n', zn.t_infl, zn.R);
fprintf('Уявне запізнення L = %.4f с, стала часу T = %.4f с (T/L = %.1f)\n', zn.L, zn.T, zn.T/zn.L);
fprintf('Kp = %.4f   Ki = %.4f   Kd = %.4f   (Ti = %.4f с, Td = %.4f с)\n', ...
        K_zn(1), K_zn(2), K_zn(3), zn.Ti, zn.Td);

%% 3. Розміщення полюсів
zeta = 1.0;  wn = 5.0;  p3 = 20.0;
[K_pp, pp] = tune_pole_placement(p, m, zeta, wn, p3);
fprintf('\n--- Розміщення полюсів (zeta = %.1f, wn = %.1f, p3 = %.1f) ---\n', zeta, wn, p3);
fprintf('Бажані полюси:  %s\n', mat2str(round(pp.desired_poles', 4)));
fprintf('Отримані полюси: %s\n', mat2str(round(sort(pp.actual_poles)', 4)));
fprintf('Kp = %.4f   Ki = %.4f   Kd = %.4f\n', K_pp(1), K_pp(2), K_pp(3));

% Лінійний відгук (без насичення) - перевірка задуму проєктування
tl = (0:1e-3:3)';
yl = p.w_ref*step(pp.sys_cl, tl);
si_lin = stepinfo(yl, tl, p.w_ref);
fprintf('Лінійна система (без насичення): ts = %.3f с, перерегулювання = %.2f %%\n', ...
        si_lin.SettlingTime, si_lin.Overshoot);
fprintf('  Причина перерегулювання - нуль PI-складової при s = %.3f\n', pp.zero_pi);
fprintf('  Пікова напруга без насичення склала б Kp*w_ref = %.0f В (нереально).\n', K_pp(1)*p.w_ref);

%% 4. Симуляція з насиченням та anti-windup
out_zn = simulate_closed_loop(p, K_zn);
out_pp = simulate_closed_loop(p, K_pp);
M_zn = performance_metrics(out_zn);
M_pp = performance_metrics(out_pp);

fprintf('\n--- Показники з урахуванням насичення %.0f В ---\n', p.Vmax);
hdr = {'метод','ts,с','OS,%','ess','IAE','int|V|','Umax','Imax','t_нас'};
fprintf('%-18s%8s%8s%9s%10s%10s%8s%8s%8s\n', hdr{:});
prn = @(nm, M) fprintf('%-18s%8.3f%8.2f%9.5f%10.3f%10.2f%8.1f%8.2f%8.3f\n', ...
        nm, M.ts, M.os, M.ess, M.iae, M.effort, M.umax, M.imax, M.tsat);
prn('Зіглер-Нікольс', M_zn);
prn('Розміщ. полюсів', M_pp);

fprintf('\nВимога ts <= %.1f с: ЗН - %s, розміщення полюсів - %s\n', p.ts_spec, ...
    ternary(M_zn.ts <= p.ts_spec, 'ВИКОНАНО', 'НЕ ВИКОНАНО'), ...
    ternary(M_pp.ts <= p.ts_spec, 'ВИКОНАНО', 'НЕ ВИКОНАНО'));

%% 5. Графіки
f = figure('Name','2.2 Порівняння налаштувань ПІД','Position',[100 100 950 700]);

subplot(2,1,1); hold on; grid on;
plot(out_zn.t, out_zn.w, 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]);
plot(out_pp.t, out_pp.w, 'LineWidth', 2.2, 'Color', [0.00 0.45 0.74]);
yline(p.w_ref, 'k--');
yline(p.w_ref*1.02, 'k:'); yline(p.w_ref*0.98, 'k:');
xline(p.ts_spec, 'r:', 'LineWidth', 1.2);
xlabel('Час, с'); ylabel('\omega, рад/с');
title('Кутова швидкість: Зіглер-Нікольс проти розміщення полюсів');
legend({sprintf('ЗН (ts=%.2f с, OS=%.1f%%)', M_zn.ts, M_zn.os), ...
        sprintf('Полюси (ts=%.2f с, OS=%.2f%%)', M_pp.ts, M_pp.os), ...
        'Уставка 100 рад/с','смуга \pm2%','', 'вимога 2 с'}, 'Location','southeast');
ylim([0 115]);

subplot(2,1,2); hold on; grid on;
plot(out_zn.t, out_zn.u, 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]);
plot(out_pp.t, out_pp.u, 'LineWidth', 2.2, 'Color', [0.00 0.45 0.74]);
yline( p.Vmax, 'k--', 'V_{max}');
yline( m.V_ss, 'g:',  'V_{уст} = 12 В');
xlabel('Час, с'); ylabel('V_{in}, В');
title('Керуючий вплив (напруга якоря)');
legend({'ЗН','Розміщення полюсів'}, 'Location','northeast');

saveas(f, fullfile(resdir, 'part2_pid_comparison.png'));
fprintf('\nГрафік збережено: %s\n', fullfile(resdir, 'part2_pid_comparison.png'));

save(fullfile(resdir, 'part2_results.mat'), 'K_zn', 'K_pp', 'out_zn', 'out_pp', ...
     'M_zn', 'M_pp', 'zn', 'pp', 'fb');
fprintf('\nБазовий регулятор для розділу 2.3: Kp = %.4f, Ki = %.4f, Kd = %.4f\n', ...
        K_pp(1), K_pp(2), K_pp(3));

%% ---------- допоміжна ----------
function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
