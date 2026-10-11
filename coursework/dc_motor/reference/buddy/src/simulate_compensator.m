function out = simulate_compensator(p, C, opt)
%SIMULATE_COMPENSATOR  Замкнений контур з lag/lead-компенсатором.
%
%   out = SIMULATE_COMPENSATOR(p, C, opt)
%     C   - структура від DESIGN_COMPENSATOR
%     opt - як у SIMULATE_CLOSED_LOOP, плюс .Tt (стала anti-windup, 0.1 с)
%
%   РЕАЛІЗАЦІЯ
%   ----------
%   Компенсатор розкладається на пряму та динамічну частини:
%       C(s) = Kc*(s+z)/(s+p) = Kc*[1 + (z-p)/(s+p)]
%   Стан xc задовольняє dxc/dt = -p*xc + e, а вихід u = Kc*e + Kc*(z-p)*xc.
%   Такий вигляд зручний тим, що прямий шлях Kc*e відокремлений від
%   динамічного, а сам блок чисельно стійкий навіть при дуже малому p.
%
%   ANTI-WINDUP ДЛЯ КОМПЕНСАТОРА
%   ----------------------------
%   У lag-компенсатора полюс стоїть біля початку координат (p = 0.03), тобто
%   стан xc поводиться майже як інтегратор і насичується так само погано.
%   Без корекції перерегулювання сягає 38%, з нею падає до нуля:
%
%       Tt = 1/p (33 с)  ->  ts = 4.72 с, перерегулювання 37.5%
%       Tt = 0.10 с      ->  ts = 2.37 с, перерегулювання 0.0%
%
%   Тому Tt задається окремим параметром, а не виводиться з p. Значення
%   0.1 с підібране розгорткою і використовується для обох компенсаторів,
%   щоб порівняння з ПІД було чесним (у ПІД anti-windup теж увімкнено).

if nargin < 3, opt = struct(); end
dflt = struct('Tend', p.Tsim, 'dt', p.dt, 'sat', true, 'aw', true, ...
              'Vmax', p.Vmax, 'Vmin', p.Vmin, 'TL_step', 0, 'TL_time', Inf, ...
              'w_ref', p.w_ref, 'Tt', 0.1, 'solver', 'ode45');
fn = fieldnames(dflt);
for k = 1:numel(fn)
    if ~isfield(opt, fn{k}), opt.(fn{k}) = dflt.(fn{k}); end
end

Kc = C.Kc;  z = C.z;  pc = C.p;
g2 = Kc*(z - pc);                      % підсилення динамічної гілки

tgrid = (0:opt.dt:opt.Tend)';
x0 = [0; 0; 0];                        % [i; omega; xc]
f  = @(tt, xx) rhs(tt, xx, p, Kc, g2, pc, opt);

switch lower(opt.solver)
    case 'ode45'
        odeopt = odeset('RelTol',1e-8, 'AbsTol',1e-10, 'MaxStep', 10*opt.dt);
        [t, X] = ode45(f, tgrid, x0, odeopt);
    case 'rk4'
        t = tgrid;  X = zeros(numel(t),3);  x = x0;  h = opt.dt;
        for k = 1:numel(t)
            X(k,:) = x';
            if k == numel(t), break; end
            k1 = f(t(k), x);        k2 = f(t(k)+h/2, x+h/2*k1);
            k3 = f(t(k)+h/2, x+h/2*k2);  k4 = f(t(k)+h, x+h*k3);
            x = x + h/6*(k1+2*k2+2*k3+k4);
        end
    otherwise
        error('simulate_compensator:solver', 'Невідомий розв''язувач');
end

u = zeros(size(t));
for k = 1:numel(t)
    [~, u(k)] = comp_out(X(k,:)', Kc, g2, opt);
end

out.t = t;  out.i = X(:,1);  out.w = X(:,2);  out.xc = X(:,3);
out.u = u;  out.e = opt.w_ref - out.w;
out.C = C;  out.opt = opt;
out.TL = zeros(size(t));
out.TL(t >= opt.TL_time) = opt.TL_step;
end

% ======================================================================
function dx = rhs(t, x, p, Kc, g2, pc, opt)
[e, u, u_un] = comp_out(x, Kc, g2, opt);

TL = 0;
if t >= opt.TL_time, TL = opt.TL_step; end

di = (u - p.Ra*x(1) - p.Ke*x(2)) / p.La;
dw = (p.Kt*x(1) - p.B*x(2) - TL) / p.J;

dxc = -pc*x(3) + e;
if opt.aw && abs(g2) > 1e-12
    dxc = dxc + (u - u_un)/(g2*opt.Tt);       % зворотний перерахунок
end

dx = [di; dw; dxc];
end

% ======================================================================
function [e, u, u_un] = comp_out(x, Kc, g2, opt)
e    = opt.w_ref - x(2);
u_un = Kc*e + g2*x(3);
if opt.sat
    u = min(max(u_un, opt.Vmin), opt.Vmax);
else
    u = u_un;
end
end
