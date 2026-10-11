function M = performance_metrics(out, w_ref, band)
%PERFORMANCE_METRICS  Показники якості за розділом 2.4.
%
%   M = PERFORMANCE_METRICS(out, w_ref, band)
%     out   - результат SIMULATE_CLOSED_LOOP
%     w_ref - цільова швидкість, рад/с        (за замовч. out.opt.w_ref)
%     band  - відносна смуга для ts           (за замовч. 0.02, тобто 2%)
%
%   ВИЗНАЧЕННЯ МЕТРИК (важливо для звіту)
%   -------------------------------------
%   ts   Час перехідного процесу - момент, після якого відгук БІЛЬШЕ НЕ
%        ВИХОДИТЬ зі смуги +-2%. Береться саме ОСТАННІЙ вихід зі смуги, а не
%        перше входження. Різниця принципова: регулятор ЗН вперше заходить у
%        смугу на 1.623 с, потім вискакує до 106.4 рад/с і повертається лише
%        на 2.853 с. За визначенням "перше входження" він формально пройшов
%        би вимогу 2 с, фактично її провалюючи. Обидві величини рахуються,
%        щоб різницю було видно у звіті (M.ts та M.t_first).
%
%   os   Перерегулювання відносно УСТАВКИ, а не кінцевого значення. Для
%        системи з нульовою статичною похибкою це те саме, але прив'язка до
%        уставки коректна й тоді, коли ess не нульова.
%
%   ess  Статична похибка - на кінці вікна симуляції.
%
%   iae  Інтеграл абсолютної похибки. Для цієї системи слабко розрізняє
%        регулятори (94.1 / 90.4 / 90.1), бо здебільшого визначається
%        ділянкою насичення, спільною для всіх. ITAE зважує пізні похибки і
%        розрізняє набагато краще (60.4 / 50.9 / 50.4), тому рахується теж.
%
%   effort  Керуючий вплив int|V|dt - метрика з умови. ЗАЛЕЖИТЬ ВІД
%        ГОРИЗОНТУ: після виходу на уставку додається рівно 12 В за секунду.
%        Тому окремо виділено effort_tr (внесок перехідного процесу, який і
%        характеризує регулятор) та effort_ss (стала складова). Для цієї
%        системи effort_tr = 70.3 В*с незалежно від Tsim.

if nargin < 2 || isempty(w_ref), w_ref = out.opt.w_ref; end
if nargin < 3 || isempty(band),  band  = 0.02;          end

t = out.t(:);  w = out.w(:);  u = out.u(:);
e = w_ref - w;

% --- час перехідного процесу: останній вихід зі смуги ---
outside = abs(e) > band*w_ref;
idx = find(outside, 1, 'last');
if isempty(idx)
    M.ts = 0;
elseif idx == numel(t)
    M.ts = Inf;                     % так і не увійшла до кінця симуляції
else
    M.ts = t(idx+1);
end

% --- перше входження у смугу (для контрасту) ---
kf = find(~outside, 1, 'first');
if isempty(kf), M.t_first = Inf; else, M.t_first = t(kf); end

M.os      = max(0, 100*(max(w) - w_ref)/w_ref);
M.w_peak  = max(w);
M.ess     = abs(w(end) - w_ref);

M.iae     = trapz(t, abs(e));
M.ise     = trapz(t, e.^2);
M.itae    = trapz(t, t.*abs(e));

M.effort  = trapz(t, abs(u));
M.effort2 = trapz(t, u.^2);

% --- розклад керуючого впливу на перехідну та сталу складові ---
if isfinite(M.ts) && M.ts > 0 && M.ts < t(end)
    kt = find(t >= M.ts, 1, 'first');
    M.effort_tr = trapz(t(1:kt),   abs(u(1:kt)));
    M.effort_ss = trapz(t(kt:end), abs(u(kt:end)));
else
    M.effort_tr = M.effort;
    M.effort_ss = 0;
end

M.umax = max(u);
M.umin = min(u);
M.imax = max(abs(out.i));
M.tsat = trapz(t, double(abs(u) >= out.opt.Vmax - 1e-6));
M.Tsim = t(end);
end
