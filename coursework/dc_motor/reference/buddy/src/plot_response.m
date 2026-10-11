function f = plot_response(p, runs, ttl, xmax)
%PLOT_RESPONSE  Два обов'язкові графіки розділу 2.4.
%
%   f = PLOT_RESPONSE(p, runs, ttl, xmax)
%     runs - масив комірок Nx2: {назва, out}, де out - від SIMULATE_CLOSED_LOOP
%     ttl  - заголовок фігури
%     xmax - верхня межа осі часу (за замовч. min(3, Tsim))
%
%   Верхня панель: кутова швидкість omega(t) з уставкою та смугою +-2%,
%   позначками ts та піку перерегулювання.
%   Нижня панель: вхідна напруга Vin(t) з межами насичення та рівнем
%   усталеної напруги 12 В.

if nargin < 3 || isempty(ttl),  ttl  = 'Оцінка ефективності'; end
if nargin < 4 || isempty(xmax), xmax = min(3, p.Tsim);        end

n = size(runs, 1);
cols = lines(max(n,3));
f = figure('Name', ttl, 'Position', [100 100 980 720]);

% ================= omega(t) =================
ax1 = subplot(2,1,1); hold on; grid on; box on;

yl = [p.w_ref*0.98, p.w_ref*1.02];
fill([0 xmax xmax 0], [yl(1) yl(1) yl(2) yl(2)], [0.9 0.9 0.9], ...
     'EdgeColor','none', 'FaceAlpha', 0.5, 'HandleVisibility','off');
yline(p.w_ref, 'k--', 'LineWidth', 1.2, 'DisplayName', ...
      sprintf('уставка %.0f рад/с', p.w_ref));

h = gobjects(n,1);
for k = 1:n
    o = runs{k,2};
    M = performance_metrics(o);
    h(k) = plot(o.t, o.w, 'LineWidth', 2, 'Color', cols(k,:), ...
        'DisplayName', sprintf('%s: t_s=%.2f с, OS=%.2f%%', runs{k,1}, M.ts, M.os));
    if isfinite(M.ts) && M.ts <= xmax
        plot(M.ts, interp1(o.t, o.w, M.ts), 'o', 'Color', cols(k,:), ...
             'MarkerFaceColor','w', 'MarkerSize', 7, 'HandleVisibility','off');
    end
    if M.os > 0.5
        [~, ip] = max(o.w);
        plot(o.t(ip), o.w(ip), '^', 'Color', cols(k,:), ...
             'MarkerFaceColor', cols(k,:), 'MarkerSize', 7, 'HandleVisibility','off');
    end
end
xline(p.ts_spec, 'r:', 'LineWidth', 1.4, 'DisplayName', ...
      sprintf('вимога %.0f с', p.ts_spec));
xlabel('Час, с'); ylabel('\omega, рад/с');
title(sprintf('%s: кутова швидкість (сіра смуга = \\pm2%%)', ttl));
legend('Location','southeast'); xlim([0 xmax]);
ylim([0, max(p.w_ref*1.15, max(cellfun(@(o) max(o.w), runs(:,2)))*1.05)]);

% ================= Vin(t) =================
ax2 = subplot(2,1,2); hold on; grid on; box on;
for k = 1:n
    o = runs{k,2};
    plot(o.t, o.u, 'LineWidth', 2, 'Color', cols(k,:), 'DisplayName', runs{k,1});
end
yline(p.Vmax, 'k--', 'LineWidth', 1.2, 'DisplayName','межа насичення');
yline(p.Vmin, 'k--', 'LineWidth', 1.2, 'HandleVisibility','off');
yline(p.w_ref*p.Ra*p.B/p.Kt + p.Ke*p.w_ref, 'g:', 'LineWidth', 1.4, ...
      'DisplayName','V_{уст} = 12 В');
yline(0, 'k-', 'LineWidth', 0.5, 'HandleVisibility','off');
xlabel('Час, с'); ylabel('V_{in}, В');
title('Керуючий вплив: напруга якоря');
legend('Location','northeast'); xlim([0 xmax]);
ylim([min(p.Vmin, min(cellfun(@(o) min(o.u), runs(:,2))))*1.1, p.Vmax*1.15]);

linkaxes([ax1 ax2], 'x');
end
