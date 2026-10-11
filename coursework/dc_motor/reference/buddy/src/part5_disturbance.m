%% PART5_DISTURBANCE - Розділ 2.5 (бонус): збурення та візуалізація
%
%  Порядок дій:
%    1) оцінка запасу за моментом - наскільки взагалі серйозне збурення 0.05 Нм;
%    2) сценарій з умови: 0.05 Нм при t = 1 с;
%    3) синтез спостерігача моменту та прямої компенсації;
%    4) складніші сценарії, де компенсація справді дає виграш;
%    5) графіки;
%    6) запуск візуалізації в реальному часі.
%
%  Запуск:  >> part5_disturbance

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

p = motor_params();
m = motor_models(p);

K = [11.0456, 21.8900, 1.3288];
f3 = fullfile(resdir, 'part3_results.mat');
if exist(f3, 'file')
    S = load(f3, 'K_opt');
    if isfield(S, 'K_opt'), K = S.K_opt; end
end
fprintf('===== 2.5 ЗБУРЕННЯ ТА ВІЗУАЛІЗАЦІЯ =====\n');
fprintf('Регулятор з розділу 2.3: Kp = %.4f, Ki = %.4f, Kd = %.4f\n', K);

%% 1. Скільки моменту двигун узагалі здатен утримати?
i_lim  = (p.Vmax - p.Ke*p.w_ref)/p.Ra;
TL_lim = p.Kt*i_lim - p.B*p.w_ref;
fprintf('\n--- Запас за моментом при %.0f рад/с ---\n', p.w_ref);
fprintf('Напруга %.0f В мінус протиЕРС %.0f В дає струм %.2f А\n', ...
        p.Vmax, p.Ke*p.w_ref, i_lim);
fprintf('Максимальний утримуваний момент: %.3f Нм\n', TL_lim);
fprintf('Збурення з умови %.2f Нм = %.1f%% від межі\n', p.TL_step, 100*p.TL_step/TL_lim);
fprintf('Напруга для його компенсації: Ra*TL/Kt = %.2f В\n', p.Ra*p.TL_step/p.Kt);
fprintf('Статичний вплив у РОЗІМКНЕНІЙ системі був би %.2f рад/с;\n', ...
        abs(p.TL_step*m.Kdc_dist));
fprintf('інтегральна складова зводить його до нуля.\n');

%% 2. Спостерігач моменту навантаження
obs = design_observer(p, [-30 -35 -40]);
fprintf('\n--- Спостерігач розширеного стану ---\n');
fprintf('Ранг матриці спостережуваності: %d з 3\n', obs.rank_obsv);
fprintf('Задані полюси: %s\n', mat2str(obs.poles));
fprintf('Отримані полюси: %s\n', mat2str(round(sort(real(obs.eig_check))', 3)));
fprintf('L = [%.1f; %.3f; %.1f]\n', obs.L(1), obs.L(2), obs.L(3));
fprintf('%s\n', obs.note);

base = struct('Tend', 6.0);
oPID = base;                                   % лише ПІД
oOBS = base;  oOBS.obs = obs.L;  oOBS.ff = true;   % ПІД + спостерігач

%% 3. Сценарії
scen = { 'за умовою: 0.05 Нм @ t = 1 с',  p.TL_step, p.TL_time
         '0.05 Нм @ t = 3 с (після виходу)', p.TL_step, 3.0
         '0.50 Нм @ t = 3 с (10x)',          0.50,     3.0
         '1.50 Нм @ t = 3 с (біля межі)',    1.50,     3.0 };

fprintf('\n--- Відпрацювання збурення ---\n');
fprintf('%-34s%9s%10s%11s%10s\n', 'сценарій', 'провал', 'віднов.,с', 'дод. IAE', 'ts');
fprintf('%s\n', repmat('-', 1, 74));
RES  = cell(size(scen,1), 2);
VAR  = {oPID, oOBS};
TAGS = {'ПІД', 'ПІД+спостерігач'};
for s = 1:size(scen,1)
    for v = 1:2
        o = VAR{v};
        o.TL_step = scen{s,2};  o.TL_time = scen{s,3};
        o0 = o;  o0.TL_step = 0;  o0.TL_time = Inf;

        r  = simulate_closed_loop(p, K, o);
        r0 = simulate_closed_loop(p, K, o0);
        d  = r0.w - r.w;                       % відхилення від незбуреної траєкторії

        k1  = find(r.t >= scen{s,3}, 1, 'first');
        dip = max(d(k1:end));
        bad = find(abs(d(k1:end)) > 0.02*p.w_ref, 1, 'last');
        trec = 0;  if ~isempty(bad), trec = r.t(k1+bad) - scen{s,3}; end
        M = performance_metrics(r);

        RES{s,v} = r;
        tag = TAGS{v};
        fprintf('%-34s%9.3f%10.3f%11.3f%10.3f   %s\n', ...
                ternary(v==1, scen{s,1}, ''), dip, trec, trapz(r.t, abs(d)), M.ts, tag);
    end
end

M_clean = performance_metrics(simulate_closed_loop(p, K, base));
M_spec  = performance_metrics(RES{1,1});
fprintf(['\nВисновок: у момент t = 1 с двигун ще розганяється на повній напрузі\n' ...
         'і має понад 2 Нм запасу за моментом, тож 0.05 Нм майже не помітні -\n' ...
         'ts змінюється з %.3f на %.3f с, вимога залишається виконаною.\n' ...
         'Компенсація там нічого не дає: напруга вже в насиченні, і додати\n' ...
         'ще 1 В фізично нікуди. Виграш від спостерігача видно лише тоді,\n' ...
         'коли збурення приходить ПІСЛЯ виходу на уставку.\n'], ...
         M_clean.ts, M_spec.ts);

%% 4. Графіки
% (а) сценарій з умови
o = oPID;  o.TL_step = p.TL_step;  o.TL_time = p.TL_time;
r_spec = simulate_closed_loop(p, K, o);
f1 = plot_response(p, {'з збуренням 0.05 Нм @ 1 с', r_spec
                       'без збурення', simulate_closed_loop(p, K, base)}, ...
                   'Сценарій з умови', 4.0);
saveas(f1, fullfile(resdir, 'part5_spec_scenario.png'));

% (б) де компенсація справді працює: 0.5 Нм після виходу на уставку
f2 = figure('Name','2.5 Компенсація збурення','Position',[130 90 950 760]);
rA = RES{3,1};  rB = RES{3,2};

subplot(3,1,1); hold on; grid on; box on;
plot(rA.t, rA.w, 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
plot(rB.t, rB.w, 'LineWidth', 2, 'Color', [0.00 0.45 0.74]);
yline(p.w_ref, 'k--'); xline(3.0, 'r:', 'LineWidth', 1.4);
xlim([2.8 4.5]); ylabel('\omega, рад/с');
title('Збурення 0.5 Нм при t = 3 с');
legend({'лише ПІД','ПІД + спостерігач'}, 'Location','southeast');

subplot(3,1,2); hold on; grid on; box on;
plot(rA.t, rA.u, 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
plot(rB.t, rB.u, 'LineWidth', 2, 'Color', [0.00 0.45 0.74]);
xline(3.0, 'r:', 'LineWidth', 1.4);
xlim([2.8 4.5]); ylabel('V_{in}, В');
title('Керуючий вплив');

subplot(3,1,3); hold on; grid on; box on;
plot(rB.t, rB.TL,     'k--', 'LineWidth', 1.8);
plot(rB.t, rB.TL_hat, 'LineWidth', 2, 'Color', [0.47 0.67 0.19]);
xline(3.0, 'r:', 'LineWidth', 1.4);
xlim([2.8 4.5]); xlabel('Час, с'); ylabel('T_L, Нм');
title('Оцінка моменту навантаження спостерігачем');
legend({'істинний T_L','оцінка T_L'}, 'Location','southeast');
saveas(f2, fullfile(resdir, 'part5_observer.png'));

save(fullfile(resdir,'part5_results.mat'), 'K','obs','RES','scen');
fprintf('\nГрафіки збережено у %s\n', resdir);

%% 5. Візуалізація в реальному часі
fprintf('\n--- Візуалізація в реальному часі ---\n');
fprintf('Запускаю анімацію (%.0f с модельного часу).\n', 4.0);
fprintf('Для швидшого відтворення: opt.speed = 2, без затримок: opt.speed = Inf.\n');
vopt = struct('Tend', 4.0, 'TL_step', 0.5, 'TL_time', 3.0, ...
              'obs', obs.L, 'ff', true, 'speed', 1);
live_visualization(p, K, vopt);

%% ---------- допоміжна ----------
function s = ternary(c, a, b)
if c, s = a; else, s = b; end
end
