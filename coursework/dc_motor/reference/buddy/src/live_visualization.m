function live_visualization(p, K, opt)
%LIVE_VISUALIZATION  Відображення швидкості та керуючого впливу в реальному часі.
%
%   LIVE_VISUALIZATION(p, K, opt)
%     opt.speed  - множник швидкості відтворення (1 = реальний час, 2 = вдвічі
%                  швидше, Inf = без затримки)          (за замовч. 1)
%     решта полів - як у SIMULATE_CLOSED_LOOP
%
%   ЯК ЦЕ ПРАЦЮЄ
%   ------------
%   Не "прорахувати, потім анімувати", а саме відображення по ходу
%   інтегрування. ODE45 викликає функцію OutputFcn після кожного успішного
%   кроку; там ми домальовуємо точки до ANIMATEDLINE і при потребі чекаємо,
%   щоб модельний час збігався з реальним. Тому картинка з'являється поступово
%   і з тією самою швидкістю, з якою рухався б справжній двигун.
%
%   DRAWNOW LIMITRATE обмежує частоту перемальовування (~20 кадрів/с) - без
%   нього перемальовування кожного кроку розв'язувача сповільнило б симуляцію
%   у десятки разів.

if nargin < 3, opt = struct(); end
dflt = struct('Tend', p.Tsim, 'dt', p.dt, 'N', 20, 'sat', true, 'aw', true, ...
              'Vmax', p.Vmax, 'Vmin', p.Vmin, 'TL_step', 0, 'TL_time', Inf, ...
              'w_ref', p.w_ref, 'beta', 1, 'gamma', 0, 'obs', [], 'ff', false, ...
              'speed', 1);
fn = fieldnames(dflt);
for k = 1:numel(fn)
    if ~isfield(opt, fn{k}), opt.(fn{k}) = dflt.(fn{k}); end
end

Kp = K(1); Ki = K(2); Kd = K(3);
TF_MIN = 1e-3;
Tf = max(Kd/(opt.N*Kp), TF_MIN);
Ti = Kp/Ki;  Td = Kd/Kp;  Tt = sqrt(Ti*Td);
useObs = ~isempty(opt.obs);
nx = 4 + 3*useObs;

% ---------------- інтерфейс ----------------
fig = figure('Name','Робота приводу в реальному часі','Position',[120 80 980 720], ...
             'Color','w');

ax1 = subplot(3,1,[1 2]); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
fill(ax1, [0 opt.Tend opt.Tend 0], opt.w_ref*[0.98 0.98 1.02 1.02], ...
     [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha',0.5);
yline(ax1, opt.w_ref, 'k--', 'LineWidth', 1.2);
hw = animatedline(ax1, 'LineWidth', 2.2, 'Color', [0.00 0.45 0.74]);
xlim(ax1, [0 opt.Tend]);
ylim(ax1, [0 opt.w_ref*1.2]);
ylabel(ax1, '\omega, рад/с');
title(ax1, 'Кутова швидкість');
txt = text(ax1, 0.02*opt.Tend, opt.w_ref*1.12, '', 'FontSize', 11, ...
           'FontName','Courier New', 'VerticalAlignment','top');

ax2 = subplot(3,1,3); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
yline(ax2, opt.Vmax, 'k--'); yline(ax2, opt.Vmin, 'k--'); yline(ax2, 0, 'k-');
hu = animatedline(ax2, 'LineWidth', 2.0, 'Color', [0.85 0.33 0.10]);
xlim(ax2, [0 opt.Tend]);
ylim(ax2, [opt.Vmin*1.1 opt.Vmax*1.15]);
xlabel(ax2, 'Час, с'); ylabel(ax2, 'V_{in}, В');
title(ax2, 'Керуючий вплив');

if isfinite(opt.TL_time) && opt.TL_time <= opt.Tend
    xline(ax1, opt.TL_time, 'r:', 'LineWidth', 1.5);
    xline(ax2, opt.TL_time, 'r:', 'LineWidth', 1.5);
    text(ax1, opt.TL_time, opt.w_ref*0.35, ...
         sprintf('  збурення %.2f Нм', opt.TL_step), 'Color','r', 'FontSize', 10);
end
linkaxes([ax1 ax2], 'x');

% ---------------- інтегрування з анімацією ----------------
wall0 = tic;
odeopt = odeset('RelTol',1e-7, 'AbsTol',1e-9, 'MaxStep', 0.01, ...
                'OutputFcn', @animate, 'Refine', 1);
ode45(@(tt,xx) rhs(tt, xx, p, Kp, Ki, Kd, Tf, Tt, opt), ...
      [0 opt.Tend], zeros(nx,1), odeopt);

fprintf('Анімацію завершено за %.1f с реального часу (модельних %.1f с).\n', ...
        toc(wall0), opt.Tend);

% ================= вкладені функції =================
    function status = animate(tt, xx, flag)
        status = 0;
        if strcmp(flag, 'init') || strcmp(flag, 'done')
            if strcmp(flag,'init') && ~isempty(tt)
                tt = tt(1);  xx = xx(:,1);
            else
                return;
            end
        end
        if ~ishandle(fig), status = 1; return; end     % вікно закрили

        for j = 1:numel(tt)
            xj = xx(:, j);
            [~, uj] = pid_output(xj, Kp, Ki, Kd, Tf, opt, p);
            addpoints(hw, tt(j), xj(2));
            addpoints(hu, tt(j), uj);
        end

        s = sprintf('t = %5.2f с\n\\omega = %6.2f рад/с\nV = %6.2f В\ni = %5.2f А', ...
                    tt(end), xx(2,end), uj, xx(1,end));
        if useObs
            s = sprintf('%s\nT_L оцінка = %.4f Нм', s, xx(7,end));
        end
        set(txt, 'String', s);

        % синхронізація з реальним часом
        if isfinite(opt.speed) && opt.speed > 0
            lag = tt(end)/opt.speed - toc(wall0);
            if lag > 0, pause(lag); end
        end
        drawnow limitrate;
    end
end

% ======================================================================
function dx = rhs(t, x, p, Kp, Ki, Kd, Tf, Tt, opt)
%RHS  Та сама динаміка, що й у SIMULATE_CLOSED_LOOP.
[e, u, u_un, eD] = pid_output(x, Kp, Ki, Kd, Tf, opt, p);

TL = 0;
if t >= opt.TL_time, TL = opt.TL_step; end

di = (u - p.Ra*x(1) - p.Ke*x(2)) / p.La;
dw = (p.Kt*x(1) - p.B*x(2) - TL) / p.J;
dI = Ki*e;
if opt.aw && isfinite(Tt), dI = dI + (u - u_un)/Tt; end
dxf = (eD - x(4)) / Tf;
dx = [di; dw; dI; dxf];

if numel(x) >= 7
    L = opt.obs(:);
    ih = x(5);  wh = x(6);  TLh = x(7);
    err = x(2) - wh;
    dx = [dx;
          (u - p.Ra*ih - p.Ke*wh)/p.La  + L(1)*err;
          (p.Kt*ih - p.B*wh - TLh)/p.J  + L(2)*err;
                                          L(3)*err];
end
end
