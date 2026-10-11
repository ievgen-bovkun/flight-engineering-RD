%% PART6_SIMSCAPE - Розділ 2.6: фізична модель Simscape та компенсатори
%
%  Порядок дій:
%    1) побудова Simscape-моделі та перевірка її проти моделі розділу 2.1;
%    2) структурне обмеження компенсаторів C(s) = Kc(s+z)/(s+p);
%    3) розгортка по полюсу компенсатора: де закінчується lag і починається lead;
%    4) синтез lag та lead, порівняння між собою та з ПІД;
%    5) графіки.
%
%  Запуск:  >> part6_simscape

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));
resdir = fullfile(fileparts(mfilename('fullpath')), '..', 'results');
if ~exist(resdir, 'dir'), mkdir(resdir); end

p = motor_params();
m = motor_models(p);
b  = p.Kt/(p.La*p.J);
a1 = (p.La*p.B + p.Ra*p.J)/(p.La*p.J);
a0 = (p.Ra*p.B + p.Kt*p.Ke)/(p.La*p.J);

Tcmp = 12;                       % спільний горизонт порівняння (lag повільний)

fprintf('===== 2.6 SIMSCAPE ТА КОМПЕНСАТОРИ =====\n');

%% 1. Simscape-модель і її перевірка
fprintf('\n--- Побудова фізичної моделі ---\n');
simscape_ok = false;
try
    [mdl_ss, built] = build_model_simscape(p);
    if built
        V_step = m.V_ss;
        assignin('base','V_step',  V_step);
        assignin('base','TL_step', 0);
        assignin('base','TL_time', Inf);

        so = sim(mdl_ss, 'StopTime', num2str(p.Tsim_ol));
        s  = so.get('omega_ss_phys');
        t_ph = s.time;  w_ph = squeeze(s.signals.values);

        t_ref = (0:p.dt:p.Tsim_ol)';
        w_ref = step(V_step*m.G, t_ref);
        w_phi = interp1(t_ph, w_ph, t_ref, 'linear', 'extrap');

        err = max(abs(w_ref - w_phi));
        fprintf('\n--- Перевірка Simscape проти розділу 2.1 ---\n');
        fprintf('Ступінь %.0f В, %.0f с симуляції\n', V_step, p.Tsim_ol);
        fprintf('Стале значення: ПФ %.4f рад/с, Simscape %.4f рад/с\n', ...
                w_ref(end), w_phi(end));
        fprintf('Максимальне відхилення: %.3e рад/с\n', err);
        if err < 1e-3
            fprintf('Моделі збігаються - фізична модель підтверджує виведення 2.1.\n');
        else
            fprintf('УВАГА: відхилення завелике. Див. таблицю причин у\n');
            fprintf('models/SIMSCAPE_BUILD.md, розділ "Перевірка".\n');
        end

        f0 = figure('Name','2.6 Simscape проти рівнянь','Position',[100 100 900 500]);
        subplot(2,1,1); hold on; grid on;
        plot(t_ref, w_ref, 'LineWidth', 2.5);
        plot(t_ph,  w_ph, '--', 'LineWidth', 2);
        xlabel('Час, с'); ylabel('\omega, рад/с');
        title(sprintf('Розімкнена система, ступінь %.0f В', V_step));
        legend({'2.1: передавальна функція','2.6: Simscape'}, 'Location','southeast');
        subplot(2,1,2); grid on;
        plot(t_ref, w_ref - w_phi, 'LineWidth', 1.5);
        xlabel('Час, с'); ylabel('Відхилення, рад/с');
        title('Різниця між фізичною та рівняннєвою моделями');
        saveas(f0, fullfile(resdir,'part6_simscape_check.png'));
        simscape_ok = true;
    end
catch ME
    fprintf('Simscape-частину пропущено: %s\n', ME.message);
    fprintf('Зберіть модель вручну за models/SIMSCAPE_BUILD.md.\n');
end

%% 2. Структурне обмеження компенсаторів
fprintf('\n--- Чому lag не може бути швидким ---\n');
fprintf('Замкнений поліном: s^3 + (a1+p)s^2 + (a0+a1*p+b*Kc)s + (a0*p+b*Kc*z)\n');
fprintf('Сума ВСІХ трьох полюсів = -(a1+p) = -(%.4f + p) - залежить ЛИШЕ від p.\n', a1);
fprintf('%8s%14s%20s\n', 'p', 'сума полюсів', 'середня дійсна ч.');
for pc = [0.03 0.1 1 5 10 20 40]
    S = a1 + pc;
    fprintf('%8.2f%14.3f%20.3f\n', pc, -S, -S/3);
end
fprintf(['Lag за визначенням має полюс біля початку координат (мале p), тож\n' ...
         'усі три полюси мусять уміщатися в суму близько -4.03. Щоб зсунути\n' ...
         'їх вліво, потрібне велике p - а це вже lead.\n']);

%% 3. Розгортка по полюсу компенсатора
fprintf('\n--- Розгортка по p (zeta = 0.7, p3 = S/3, Tt = 0.1 с) ---\n');
fprintf('%8s%10s%10s%9s%8s%10s%8s%9s\n','p','Kc','z','z/p','тип','ts,с','OS,%','ess,%');
plist = [0.01 0.03 0.1 0.3 1 2 3 5 10 20 40];
SW = nan(numel(plist), 4);
for k = 1:numel(plist)
    Ck = design_compensator(p, m, plist(k));
    ok = simulate_compensator(p, Ck, struct('Tend', Tcmp, 'solver','rk4', 'dt',5e-4));
    Mk = performance_metrics(ok);
    SW(k,:) = [Ck.Kc, Ck.z/Ck.p, Mk.ts, 100*Ck.ess];
    tsstr = '     inf';  if isfinite(Mk.ts), tsstr = sprintf('%10.3f', Mk.ts); end
    fprintf('%8.2f%10.3f%10.4f%9.3f%8s%s%8.2f%9.3f\n', ...
            plist(k), Ck.Kc, Ck.z, Ck.z/Ck.p, Ck.type, tsstr, Mk.os, 100*Ck.ess);
end
fprintf(['Середина діапазону провалює вимогу не за швидкодією, а за точністю:\n' ...
         'статична похибка виходить за смугу 2%%, тому ts взагалі не визначений.\n']);

%% 4. Фінальні компенсатори проти ПІД
C_lag  = design_compensator(p, m,  0.03);
C_lead = design_compensator(p, m, 20.00);

fprintf('\n--- Синтезовані компенсатори ---\n');
for C = [C_lag, C_lead]
    fprintf('%s: C(s) = %.4f*(s + %.4f)/(s + %.4f),  z/p = %.3f\n', ...
            upper(C.type), C.Kc, C.z, C.p, C.z/C.p);
    fprintf('     полюси замкненої: %s\n', mat2str(round(C.poles', 4)));
    fprintf('     ess = a0*p/c0 = %.3f %%,  петльове підсилення = %.2f\n', ...
            100*C.ess, C.Kdc_loop);
    fprintf('     початкова команда Kc*w_ref = %.0f В (межа %.0f В)\n', C.u0, p.Vmax);
end

K_pid = [11.0456, 21.8900, 1.3288];
f3 = fullfile(resdir,'part3_results.mat');
if exist(f3,'file')
    S3 = load(f3,'K_opt');
    if isfield(S3,'K_opt'), K_pid = S3.K_opt; end
end

copt = struct('Tend', Tcmp, 'Tt', 0.1);
o_lag  = simulate_compensator(p, C_lag,  copt);
o_lead = simulate_compensator(p, C_lead, copt);
o_pid  = simulate_closed_loop(p, K_pid,  struct('Tend', Tcmp));

names = {'Lag-компенсатор','Lead-компенсатор','ПІД (2.3)'};
mets  = {performance_metrics(o_lag), performance_metrics(o_lead), performance_metrics(o_pid)};
report_metrics(names, mets, p, fullfile(resdir,'part6_metrics.csv'));

fprintf('\n--- Lag проти Lead: підсумок ---\n');
fprintf('%-26s%12s%12s\n','', 'Lag', 'Lead');
fprintf('%-26s%12.3f%12.3f\n','час перехід. процесу, с', mets{1}.ts, mets{2}.ts);
fprintf('%-26s%12.2f%12.2f\n','перерегулювання, %',       mets{1}.os, mets{2}.os);
fprintf('%-26s%12.4f%12.4f\n','статична похибка, рад/с',  mets{1}.ess, mets{2}.ess);
fprintf('%-26s%12.2f%12.2f\n','керуючий вплив, В*с',      mets{1}.effort, mets{2}.effort);
fprintf('%-26s%12.1f%12.1f\n','int V^2 dt',               mets{1}.effort2, mets{2}.effort2);
fprintf('%-26s%12.2f%12.2f\n','підсилення Kc',            C_lag.Kc, C_lead.Kc);
fprintf(['\nLead швидший (%.3f проти %.3f с) ціною підсилення у %.0f разів\n' ...
         'більшого і статичної похибки у %.1f разу гіршої. Жоден з них не дає\n' ...
         'нуля статичної похибки - на відміну від ПІД, у них немає інтегратора.\n'], ...
         mets{2}.ts, mets{1}.ts, C_lead.Kc/C_lag.Kc, mets{2}.ess/mets{1}.ess);

%% 5. Графіки
f1 = plot_response(p, {names{1}, o_lag; names{2}, o_lead; names{3}, o_pid}, ...
                   'Lag / Lead / ПІД', 6.0);
saveas(f1, fullfile(resdir,'part6_compensators.png'));

f2 = figure('Name','2.6 Розгортка по полюсу компенсатора','Position',[150 150 900 480]);
yyaxis left
semilogx(plist, SW(:,3), 'o-', 'LineWidth', 1.8); hold on; grid on;
yline(p.ts_spec, 'r:', 'LineWidth', 1.5);
ylabel('t_s, с'); ylim([0 6]);
yyaxis right
semilogx(plist, SW(:,4), 's--', 'LineWidth', 1.6);
yline(2, 'k:');
ylabel('статична похибка, %');
xlabel('полюс компенсатора p');
title('Перехід від lag до lead: швидкодія та точність');
legend({'t_s','вимога 2 с','ess','смуга 2%'}, 'Location','north');
saveas(f2, fullfile(resdir,'part6_sweep.png'));

save(fullfile(resdir,'part6_results.mat'), 'C_lag','C_lead','mets','names','SW','plist');
fprintf('\nГрафіки та дані збережено у %s\n', resdir);
if ~simscape_ok
    fprintf('\nНАГАДУВАННЯ: Simscape-модель треба зібрати вручну -\n');
    fprintf('покрокова інструкція у models/SIMSCAPE_BUILD.md\n');
end
