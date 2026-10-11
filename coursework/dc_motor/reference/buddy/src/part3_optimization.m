%% PART3_OPTIMIZATION - Розділ 2.3: оптимізація коефіцієнтів ПІД
%
%  Порядок дій:
%    1) теоретична межа швидкодії (релейне керування) як орієнтир;
%    2) аналітична перевірка: чи незалежні критерії IAE та int|V|dt;
%    3) оптимізація двома алгоритмами - Нелдер-Мід та генетичний;
%    4) фронт Парето розгорткою вагового коефіцієнта lambda;
%    5) перевірка робастності до похибки коефіцієнтів;
%    6) графіки та підсумкова таблиця.
%
%  Запуск:  >> part3_optimization      (типово 3-6 хвилин)

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

p = motor_params();
m = motor_models(p);

K_zn = tune_ziegler_nichols(p, m);
K_pp = tune_pole_placement(p, m, 1.0, 5.0, 20.0);

fprintf('===== 2.3 ОПТИМІЗАЦІЯ =====\n');

%% 1. Теоретична межа
bb = time_optimal_benchmark(p, m);
fprintf('\n--- Межа швидкодії при %.0f В (релейне керування) ---\n', p.Vmax);
fprintf('Перемикання: +%.0f В протягом %.4f с, потім %.0f В протягом %.4f с\n', ...
        p.Vmax, bb.t1, p.Vmin, bb.t2);
fprintf('Нев''язка кінцевого стану: %.2e\n', bb.resid);
fprintf('ts(2%%) = %.4f с   IAE = %.3f   int V^2 = %.1f   int|V| = %.2f\n', ...
        bb.ts, bb.iae, bb.eff2, bb.effort);
fprintf('Жоден регулятор при %.0f В не зробить краще за ці значення.\n', p.Vmax);

%% 2. Чи конфліктують критерії з умови?
fprintf('\n--- Зв''язок між IAE та керуючим впливом ---\n');
c1 = p.Ra*p.B/p.Kt + p.Ke;
c0 = p.La*(p.B*p.w_ref/p.Kt) + p.Ra*(p.J*p.w_ref + p.B*p.w_ref*p.Tsim)/p.Kt ...
     + p.Ke*p.w_ref*p.Tsim;
fprintf('З інтегрування рівняння якоря: int|V|dt = %.4f - %.4f * IAE\n', c0, c1);
fprintf('Критерії строго антагоністичні: -1 рад IAE = +%.3f В*с напруги.\n', c1);
fprintf('Тому в цільовій функції керуючий вплив узято як int V^2 dt\n');
fprintf('(докладне обґрунтування - у коментарях PID_COST).\n');

%% 3. Оптимізація
out0 = simulate_closed_loop(p, K_pp);
M0   = performance_metrics(out0);

cfg = struct('lambda', 0.2, ...
             'ts_target', 0.9*p.ts_spec, ...   % запас 10% від вимоги
             'os_target', 1.0, ...
             'ess_max',   0.2, ...
             'IAE_ref',   M0.iae, ...
             'E2_ref',    M0.eff2, ...
             'penalty',   100, ...
             'simopt',    struct('solver','rk4','dt',5e-4));

fprintf('\n--- Оптимізація (lambda = %.2f, цільовий ts = %.2f с) ---\n', ...
        cfg.lambda, cfg.ts_target);
R = optimize_pid(p, cfg);
K_opt = R.K;
fprintf('\nКращий результат (%s): Kp = %.4f, Ki = %.4f, Kd = %.4f\n', ...
        R.method, K_opt(1), K_opt(2), K_opt(3));

%% 4. Підсумкове порівняння (точний розв'язувач)
cands = { 'Зіглер-Нікольс',      K_zn
          '2.2 розміщ. полюсів', K_pp
          '2.3 оптимізований',   K_opt };
fprintf('\n--- Підсумок (ode45, Tsim = %.0f с) ---\n', p.Tsim);
fprintf('%-22s%9s%9s%8s%8s%7s%9s%9s%9s\n', 'регулятор','Kp','Ki','Kd','ts','OS%','IAE','intV^2','int|V|');
fprintf('%-22s%9s%9s%8s%8.3f%7.2f%9.3f%9.1f%9.2f\n', ...
        'релейне (межа)','-','-','-', bb.ts, 0, bb.iae, bb.eff2, bb.effort);
OUT = cell(size(cands,1),1);  MET = cell(size(cands,1),1);
for k = 1:size(cands,1)
    OUT{k} = simulate_closed_loop(p, cands{k,2});
    MET{k} = performance_metrics(OUT{k});
    K = cands{k,2};  M = MET{k};
    fprintf('%-22s%9.3f%9.3f%8.3f%8.3f%7.2f%9.3f%9.1f%9.2f\n', ...
            cands{k,1}, K(1), K(2), K(3), M.ts, M.os, M.iae, M.eff2, M.effort);
end
Mo = MET{3};
fprintf('\nОптимізований проти базового: ts %+.1f%%, IAE %+.1f%%, int V^2 %+.1f%%\n', ...
        100*(Mo.ts/M0.ts-1), 100*(Mo.iae/M0.iae-1), 100*(Mo.eff2/M0.eff2-1));
fprintf('Відрив від теоретичної межі: ts %+.1f%%, IAE %+.1f%%\n', ...
        100*(Mo.ts/bb.ts-1), 100*(Mo.iae/bb.iae-1));

%% 5. Фронт Парето
fprintf('\n--- Фронт Парето (розгортка lambda) ---\n');
lams = [0, 0.05, 0.2, 0.5, 1, 3, 10];
PAR = zeros(numel(lams), 6);
fprintf('%8s%10s%10s%9s%8s%7s%9s%10s\n','lambda','Kp','Ki','Kd','ts','OS%','IAE','intV^2');
for k = 1:numel(lams)
    c = cfg;  c.lambda = lams(k);
    o = optimset('Display','off','TolX',1e-5,'TolFun',1e-9,'MaxFunEvals',800);
    xk = fminsearch(@(x) pid_cost(10.^x, p, c), log10(K_pp), o);
    Kk = 10.^xk;
    Mk = performance_metrics(simulate_closed_loop(p, Kk));
    PAR(k,:) = [Kk, Mk.ts, Mk.iae, Mk.eff2];
    fprintf('%8.2f%10.3f%10.3f%9.3f%8.3f%7.2f%9.3f%10.1f\n', ...
            lams(k), Kk(1), Kk(2), Kk(3), Mk.ts, Mk.os, Mk.iae, Mk.eff2);
end

%% 6. Робастність
fprintf('\n--- Робастність: усі коефіцієнти зміщено на +-20%% ---\n');
fprintf('%-22s%11s%10s%11s%11s\n','регулятор','ts(-20%)','ts(ном)','ts(+20%)','найгірше');
for k = 1:size(cands,1)
    r = zeros(1,3);  f = [0.8 1.0 1.2];
    for j = 1:3
        r(j) = performance_metrics(simulate_closed_loop(p, cands{k,2}*f(j))).ts;
    end
    fprintf('%-22s%11.3f%10.3f%11.3f%11.3f\n', cands{k,1}, r(1), r(2), r(3), max(r));
end
fprintf(['\nЦе не формальність: оптимум із занадто малими коефіцієнтами може\n' ...
         'дати найкраще J і водночас розвалитися при похибці параметрів.\n' ...
         'Саме тому в цільовій функції ts_target = %.1f с, а не %.1f с.\n'], ...
         cfg.ts_target, p.ts_spec);

%% 7. Графіки
f1 = figure('Name','2.3 Результат оптимізації','Position',[100 100 950 700]);
subplot(2,1,1); hold on; grid on;
plot(bb.t, bb.w, 'k:', 'LineWidth', 1.5);
cols = [0.85 0.33 0.10; 0.47 0.67 0.19; 0.00 0.45 0.74];
for k = 1:3, plot(OUT{k}.t, OUT{k}.w, 'LineWidth', 1.8+0.4*k, 'Color', cols(k,:)); end
yline(p.w_ref,'k--'); yline(p.w_ref*1.02,'k:'); yline(p.w_ref*0.98,'k:');
xlim([0 3]); ylim([0 112]);
xlabel('Час, с'); ylabel('\omega, рад/с'); title('Кутова швидкість');
legend([{'релейне (межа)'}; cands(:,1)], 'Location','southeast');

subplot(2,1,2); hold on; grid on;
plot(bb.t, bb.u, 'k:', 'LineWidth', 1.5);
for k = 1:3, plot(OUT{k}.t, OUT{k}.u, 'LineWidth', 1.8+0.4*k, 'Color', cols(k,:)); end
yline(p.Vmax,'k--'); yline(p.Vmin,'k--');
xlim([0 3]);
xlabel('Час, с'); ylabel('V_{in}, В'); title('Керуючий вплив');

saveas(f1, fullfile(resdir, 'part3_optimized.png'));

f2 = figure('Name','2.3 Фронт Парето','Position',[150 150 700 500]);
plot(PAR(:,5), PAR(:,6), 'o-', 'LineWidth', 1.8, 'MarkerFaceColor','w'); hold on; grid on;
plot(M0.iae, M0.eff2, 'sk', 'MarkerSize', 10, 'MarkerFaceColor','k');
plot(bb.iae, bb.eff2, 'p', 'MarkerSize', 14, 'MarkerFaceColor',[0.9 0.6 0]);
for k = 1:numel(lams)
    text(PAR(k,5), PAR(k,6), sprintf('  \\lambda=%.2g', lams(k)), 'FontSize', 9);
end
xlabel('IAE, рад'); ylabel('\int V^2 dt, В^2\cdot с');
title('Фронт Парето: швидкодія проти енергії');
legend({'фронт Парето','базовий (2.2)','релейне (межа)'}, 'Location','best');
saveas(f2, fullfile(resdir, 'part3_pareto.png'));

save(fullfile(resdir,'part3_results.mat'), 'K_opt','K_pp','K_zn','R','cfg','PAR','lams','bb','MET');
fprintf('\nГрафіки та дані збережено у %s\n', resdir);
fprintf('Регулятор для розділів 2.4-2.5: Kp = %.4f, Ki = %.4f, Kd = %.4f\n', ...
        K_opt(1), K_opt(2), K_opt(3));
