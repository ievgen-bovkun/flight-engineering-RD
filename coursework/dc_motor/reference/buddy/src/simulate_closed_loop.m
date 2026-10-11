function out = simulate_closed_loop(p, K, opt)
%SIMULATE_CLOSED_LOOP  Симуляція замкненої системи "ПІД + ДПС + навантаження".
%
%   out = SIMULATE_CLOSED_LOOP(p, K, opt)
%
%   Вхід:
%     p   - структура параметрів від MOTOR_PARAMS
%     K   - вектор коефіцієнтів [Kp, Ki, Kd]
%     opt - (необов'язково) структура налаштувань:
%             .Tend     тривалість симуляції, с          (за замовч. p.Tsim)
%             .dt       крок виводу, с                   (p.dt)
%             .N        коефіцієнт фільтра похідної      (20)
%             .sat      вмикати насичення напруги        (true)
%             .aw       вмикати anti-windup              (true)
%             .TL_step  амплітуда збурення, Нм           (0)
%             .TL_time  момент прикладання збурення, с   (Inf)
%             .beta     ваговий коеф. уставки для P      (1)
%             .gamma    ваговий коеф. уставки для D      (0)
%             .solver   'ode45' (точно) або 'rk4' (швидко) ('ode45')
%             .obs      матриця L спостерігача моменту, 3x1  ([] = вимкнено)
%             .ff       компенсація оціненого моменту        (false)
%
%   Вихід out: .t .w .i .u .e та поля-копії налаштувань.
%
%   РЕАЛІЗАЦІЯ РЕГУЛЯТОРА
%   ---------------------
%   Використано паралельну форму з трьома практичними доробками, без яких
%   регулятор нежиттєздатний на реальному приводі:
%
%   1) Похідна по ВИМІРЮВАННЮ, а не по похибці (gamma = 0). Ступінчаста
%      зміна уставки інакше дає нескінченний сплеск ("derivative kick"),
%      а в передавальній функції замкненої системи з'являється зайвий нуль.
%   2) Фільтр похідної Kd*s/(Tf*s+1), Tf = Kd/(N*Kp). Ідеальна ланка Kd*s
%      фізично нереалізовна і підсилює шум вимірювання.
%   3) Anti-windup методом зворотного перерахунку. Оскільки напруга
%      насичується протягом більшої частини розгону, інтегратор без цього
%      накопичує величезну помилку і дає багатократне перерегулювання.
%
%   Інтегральна складова живиться СПРАВЖНЬОЮ похибкою e = w_ref - w
%   (без вагового коефіцієнта), що гарантує нульову статичну похибку.

if nargin < 3, opt = struct(); end
dflt = struct('Tend', p.Tsim, 'dt', p.dt, 'N', 20, 'sat', true, 'aw', true, ...
              'Vmax', p.Vmax, 'Vmin', p.Vmin, 'TL_step', 0, 'TL_time', Inf, ...
              'w_ref', p.w_ref, 'beta', 1, 'gamma', 0, 'solver', 'ode45', ...
              'obs', [], 'ff', false);
fn = fieldnames(dflt);
for k = 1:numel(fn)
    if ~isfield(opt, fn{k}), opt.(fn{k}) = dflt.(fn{k}); end
end

Kp = K(1);  Ki = K(2);  Kd = K(3);

% Стала часу фільтра похідної. Знизу обмежена TF_MIN: фізично реалізовний
% фільтр не буває швидшим за ~1 кГц, і ця ж межа не дає задачі стати
% жорсткою під час оптимізації, коли Kd мале, а Kp велике.
TF_MIN = 1e-3;
if Kd > 0 && Kp > 0
    Tf = max(Kd/(opt.N*Kp), TF_MIN);
else
    Tf = TF_MIN;
end

% Коефіцієнт зворотного перерахунку anti-windup (рекомендація Astrom):
% Tt = sqrt(Ti*Td); за відсутності D-складової Tt = Ti.
if Ki > 0
    Ti = Kp/Ki;
    Td = Kd/max(Kp, eps);
    if Td > 0, Tt = sqrt(Ti*Td); else, Tt = Ti; end
else
    Tt = Inf;
end

% Розмір вектора станів: 4 без спостерігача, 7 зі спостерігачем.
% Без спостерігача зайві стани не інтегруються - це важливо для розділу 2.3,
% де цільова функція обчислюється тисячі разів.
useObs = ~isempty(opt.obs);
if opt.ff && ~useObs
    error('simulate_closed_loop:ff', 'opt.ff вимагає заданої матриці opt.obs');
end
nx = 4 + 3*useObs;

tgrid = (0:opt.dt:opt.Tend)';
x0    = zeros(nx, 1);              % [i; omega; I_int; xf; i_hat; w_hat; TL_hat]
f = @(tt, xx) rhs(tt, xx, p, Kp, Ki, Kd, Tf, Tt, opt);

switch lower(opt.solver)
    case 'ode45'
        % Точний змінний крок - для фінальних результатів і графіків.
        odeopt = odeset('RelTol', 1e-8, 'AbsTol', 1e-10, 'MaxStep', 10*opt.dt);
        [t, X] = ode45(f, tgrid, x0, odeopt);
    case 'rk4'
        % Фіксований крок RK4 - на порядок швидше, для циклу оптимізації
        % (розділ 2.3), де потрібні тисячі обчислень цільової функції.
        t = tgrid;
        X = zeros(numel(t), nx);
        x = x0;
        h = opt.dt;
        for k = 1:numel(t)
            X(k,:) = x';
            if k == numel(t), break; end
            k1 = f(t(k),     x);
            k2 = f(t(k)+h/2, x + h/2*k1);
            k3 = f(t(k)+h/2, x + h/2*k2);
            k4 = f(t(k)+h,   x + h  *k3);
            x = x + h/6*(k1 + 2*k2 + 2*k3 + k4);
            if ~all(isfinite(x)) || abs(x(2)) > 1e5   % розбіжність
                X(k+1:end,1:2) = 1e5;
                break;
            end
        end
    otherwise
        error('simulate_closed_loop:solver', 'Невідомий розв''язувач: %s', opt.solver);
end

% Відновлюємо керуючий сигнал на сітці виводу
u = zeros(size(t));
for k = 1:numel(t)
    [~, u(k)] = pid_output(X(k,:)', Kp, Ki, Kd, Tf, opt, p);
end

out.t    = t;
out.i    = X(:,1);
out.w    = X(:,2);
out.Iint = X(:,3);
out.u    = u;
out.e    = opt.w_ref - out.w;
out.K    = K(:)';
out.opt  = opt;
out.Tf   = Tf;
out.Tt   = Tt;
if useObs
    out.i_hat  = X(:,5);
    out.w_hat  = X(:,6);
    out.TL_hat = X(:,7);
end
out.TL = zeros(size(t));
out.TL(t >= opt.TL_time) = opt.TL_step;
end

% ======================================================================
function dx = rhs(t, x, p, Kp, Ki, Kd, Tf, Tt, opt)
%RHS  Права частина ОДУ: двигун (2 стани) + регулятор (2) + спостерігач (3).
[e, u, u_un, eD] = pid_output(x, Kp, Ki, Kd, Tf, opt, p);

TL = 0;
if t >= opt.TL_time, TL = opt.TL_step; end

di = (u - p.Ra*x(1) - p.Ke*x(2)) / p.La;          % електричне рівняння
dw = (p.Kt*x(1) - p.B*x(2) - TL) / p.J;           % механічне рівняння

dI = Ki*e;
if opt.aw && isfinite(Tt)
    dI = dI + (u - u_un)/Tt;                      % зворотний перерахунок
end

dxf = (eD - x(4)) / Tf;                           % стан фільтра похідної

dx = [di; dw; dI; dxf];

% ---- спостерігач розширеного стану (розділ 2.5) ----
% Модель: [i_hat; w_hat; TL_hat], причому момент вважається сталим
% (dTL/dt = 0). Корекція - за нев'язкою ЛИШЕ по вимірюваній швидкості.
if numel(x) >= 7
    L   = opt.obs(:);
    ih  = x(5);  wh = x(6);  TLh = x(7);
    err = x(2) - wh;                              % нев'язка спостерігача
    dx = [dx;
          (u - p.Ra*ih - p.Ke*wh)/p.La    + L(1)*err;
          (p.Kt*ih - p.B*wh - TLh)/p.J    + L(2)*err;
                                            L(3)*err];
end
end
