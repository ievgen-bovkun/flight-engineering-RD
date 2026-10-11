function [K, info] = tune_pole_placement(p, m, zeta, wn, p3)
%TUNE_POLE_PLACEMENT  Аналітичний синтез ПІД методом розміщення полюсів.
%
%   [K, info] = TUNE_POLE_PLACEMENT(p, m, zeta, wn, p3)
%
%   ВИВЕДЕННЯ
%   ---------
%   Об'єкт:     G(s) = b / (s^2 + a1*s + a0)
%   Регулятор:  C(s) = (Kd*s^2 + Kp*s + Ki)/s
%
%   Характеристичний поліном замкненої системи:
%       s*(s^2 + a1*s + a0) + b*(Kd*s^2 + Kp*s + Ki)
%     = s^3 + (a1 + b*Kd)*s^2 + (a0 + b*Kp)*s + b*Ki
%
%   Три коефіцієнти - три невідомі, тому полюси розміщуються ТОЧНО.
%   Бажаний поліном: (s^2 + 2*zeta*wn*s + wn^2)*(s + p3)
%     = s^3 + (2*zeta*wn + p3)*s^2 + (wn^2 + 2*zeta*wn*p3)*s + wn^2*p3
%
%   Прирівнюючи коефіцієнти:
%       Kd = (2*zeta*wn + p3 - a1)/b
%       Kp = (wn^2 + 2*zeta*wn*p3 - a0)/b
%       Ki = wn^2*p3/b
%
%   Вибір параметрів: ts(2%) ~ 4/(zeta*wn), тож для запасу відносно вимоги
%   у 2 с беремо zeta*wn = 5. Третій полюс p3 відносимо у 4 рази далі, щоб
%   домінувала спроєктована пара.

if nargin < 3 || isempty(zeta), zeta = 1.0; end
if nargin < 4 || isempty(wn),   wn   = 5.0; end
if nargin < 5 || isempty(p3),   p3   = 4*zeta*wn; end

b  = p.Kt/(p.La*p.J);
a1 = (p.La*p.B + p.Ra*p.J)/(p.La*p.J);
a0 = (p.Ra*p.B + p.Kt*p.Ke)/(p.La*p.J);

Kd = (2*zeta*wn + p3 - a1)/b;
Kp = (wn^2 + 2*zeta*wn*p3 - a0)/b;
Ki = wn^2*p3/b;

K = [Kp, Ki, Kd];

info.zeta = zeta;  info.wn = wn;  info.p3 = p3;
info.b = b;  info.a1 = a1;  info.a0 = a0;
info.desired_poles = [roots([1, 2*zeta*wn, wn^2]); -p3];
info.den_cl = [1, a1 + b*Kd, a0 + b*Kp, b*Ki];
info.actual_poles = roots(info.den_cl);
info.ts_linear = 4/(zeta*wn);

% Лінійна замкнена система з похідною по виходу (gamma = 0):
% чисельник містить лише нуль від PI-складової: b*(Kp*s + Ki)
info.sys_cl = tf(b*[Kp, Ki], info.den_cl);
info.zero_pi = -Ki/Kp;
end
