function bb = time_optimal_benchmark(p, m)
%TIME_OPTIMAL_BENCHMARK  Фізична межа швидкодії при заданій напрузі.
%
%   bb = TIME_OPTIMAL_BENCHMARK(p, m)
%
%   НАВІЩО ЦЕ ПОТРІБНО
%   ------------------
%   Без орієнтира неможливо сказати, чи 1.77 с - це добре. Для лінійного
%   об'єкта 2-го порядку з обмеженим входом оптимальне за швидкодією
%   керування є релейним і має рівно одну точку перемикання (принцип
%   максимуму Понтрягіна). Це дає ТЕОРЕТИЧНУ МЕЖУ, якої не перевершить
%   жоден регулятор при тій самій напрузі.
%
%   Ставимо задачу як перевід стану з (i=0, w=0) у (i = i_ss, w = w_ref),
%   де i_ss = B*w_ref/Kt - той єдиний стан, у якому система може ЗАЛИШИТИСЯ
%   при сталій напрузі 12 В. Керування: +Vmax протягом t1, -Vmax протягом t2.
%   Дві невідомі, дві умови - шукаємо t1, t2 через FMINSEARCH за нев'язкою.

A  = m.A;  Bu = m.Bu;
i_ss  = p.B*p.w_ref/p.Kt;
x_tgt = [i_ss; p.w_ref];

% Точний перехід лінійної системи за час dt при сталому вході u
prop = @(x, u, dt) expm(A*dt)*x + (A\(expm(A*dt) - eye(2)))*Bu*u;

resid = @(v) prop(prop([0;0], p.Vmax, abs(v(1))), p.Vmin, abs(v(2))) - x_tgt;
obj   = @(v) sum(resid(v).^2);

v = fminsearch(obj, [1.5; 0.1], optimset('Display','off','TolX',1e-12,'TolFun',1e-16));
bb.t1 = abs(v(1));
bb.t2 = abs(v(2));
bb.T_star = bb.t1 + bb.t2;
bb.resid  = max(abs(resid(v)));

% Відтворюємо траєкторію: +Vmax -> -Vmax -> V_ss
dt = p.dt;
t  = (0:dt:p.Tsim)';
Ad = expm(A*dt);
Bd = (A\(Ad - eye(2)))*Bu;
x  = [0; 0];
w  = zeros(size(t));  u = zeros(size(t));  ia = zeros(size(t));
for k = 1:numel(t)
    if     t(k) <  bb.t1,          u(k) = p.Vmax;
    elseif t(k) <  bb.t1 + bb.t2,  u(k) = p.Vmin;
    else,                          u(k) = p.w_ref/dcgain(m.G);
    end
    w(k) = x(2);  ia(k) = x(1);
    if k < numel(t), x = Ad*x + Bd*u(k); end
end

bb.t = t;  bb.w = w;  bb.u = u;  bb.i = ia;

outside = abs(w - p.w_ref) > 0.02*p.w_ref;
idx = find(outside, 1, 'last');
bb.ts     = t(min(idx+1, numel(t)));
bb.iae    = trapz(t, abs(p.w_ref - w));
bb.effort = trapz(t, abs(u));
bb.eff2   = trapz(t, u.^2);
bb.imax   = max(abs(ia));
end
