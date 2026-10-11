function [Jcost, M] = pid_cost(K, p, cfg)
%PID_COST  Цільова функція оптимізації ПІД-регулятора (розділ 2.3).
%
%   [Jcost, M] = PID_COST(K, p, cfg)
%     K   - [Kp Ki Kd]
%     cfg - структура налаштувань (див. нижче)
%
%   ЧОМУ ЦІЛЬОВА ФУНКЦІЯ САМЕ ТАКА
%   ------------------------------
%   В умові просять мінімізувати одночасно (а) IAE і (б) керуючий вплив.
%   Якщо взяти керуючий вплив як int|V|dt, ці критерії НЕ є незалежними.
%   Проінтегруємо рівняння якоря від 0 до T:
%
%       int V dt = La*i(T) + Ra*int i dt + Ke*int w dt
%
%   З балансу моментів Kt*int i dt = J*w(T) + B*int w dt, а за відсутності
%   перерегулювання int w dt = w_ref*T - IAE. Підстановка дає точну лінійну
%   залежність (для параметрів цього проєкту, T = 5 с):
%
%       int|V| dt = 120.5 - 0.12 * IAE
%
%   Тобто будь-яке зменшення IAE АВТОМАТИЧНО збільшує витрачену напругу:
%   критерії строго антагоністичні, фронт Парето вироджується у пряму, і
%   зважена сума J = IAE + lam*int|V| просто зісковзує в один із кінців.
%
%   Тому в цільовій функції керуючий вплив береться як int V^2 dt. Ця
%   метрика не пов'язана з IAE лінійно, має сенс енергії, що розсіюється, і
%   штрафує саме тривале перебування у насиченні. Метрика int|V|dt з умови
%   при цьому обчислюється й виводиться у звіт (див. PERFORMANCE_METRICS).
%
%   Вимоги з умови (ts, перерегулювання, статична похибка) внесені як
%   зовнішні штрафи, бо це саме ОБМЕЖЕННЯ, а не те, що варто мінімізувати
%   нескінченно: сенсу робити ts = 1.2 с ціною втричі більшої енергії немає.
%
%   Поля cfg (усі необов'язкові):
%     .lambda    вага енергетичного доданка               (0.2)
%     .ts_target цільовий ts для штрафу, с                (1.8 = запас 10%)
%     .os_target допустиме перерегулювання, %             (1.0)
%     .ess_max   допустима статична похибка, рад/с        (0.2)
%     .IAE_ref   нормувальник IAE                         (обов'язково)
%     .E2_ref    нормувальник int V^2 dt                  (обов'язково)
%     .penalty   масштаб штрафу                           (100)
%     .simopt    налаштування для SIMULATE_CLOSED_LOOP

if nargin < 3, cfg = struct(); end
dflt = struct('lambda', 0.2, 'ts_target', 0.9*p.ts_spec, 'os_target', 1.0, ...
              'ess_max', 0.2, 'penalty', 100, 'IAE_ref', 1, 'E2_ref', 1, ...
              'simopt', struct('solver','rk4','dt',5e-4));
fn = fieldnames(dflt);
for k = 1:numel(fn)
    if ~isfield(cfg, fn{k}), cfg.(fn{k}) = dflt.(fn{k}); end
end

K = K(:)';
if any(~isfinite(K)) || any(K <= 0)
    Jcost = 1e6;  M = struct();  return;
end

try
    out = simulate_closed_loop(p, K, cfg.simopt);
    M   = performance_metrics(out);
catch
    Jcost = 1e6;  M = struct();  return;
end

ts = M.ts;
if ~isfinite(ts), ts = 2*out.opt.Tend; end     % так і не увійшла у смугу

% Основна частина: нормовані IAE та енергія
Jmain = M.iae/cfg.IAE_ref + cfg.lambda * M.eff2/cfg.E2_ref;

% Штрафи за порушення вимог (односторонні, лінійні)
Jpen = cfg.penalty * ( max(0, ts/cfg.ts_target      - 1) ...
                     + max(0, M.os/cfg.os_target    - 1) ...
                     + max(0, M.ess/cfg.ess_max     - 1) );

Jcost = Jmain + Jpen;
if ~isfinite(Jcost), Jcost = 1e6; end
end
