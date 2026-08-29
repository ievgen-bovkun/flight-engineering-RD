%% ========================================================================
%  Лінеаризація ММ поздовжнього руху ЛА та опис у просторі станів
%  Вихідна система нелінійних рівнянь — (7) (V = const, P = const)
%  Коефіцієнти — за формулами (27)-(31), матриці A, B — за формулою (34)
%
%  Вектор стану:  X = [dTheta; dAlpha; dVartheta; dOmega_z; dH]
%  Керування:     u = dDelta_1  (рад)
%  ========================================================================
clear; clc; close all;

VAR = 1;          % <<< НОМЕР ВАШОГО ВАРІАНТА за табл. 1 (1...6) >>>
ZNAK = -1;        % знак стрибка руля: -1 -> delta1 = -delta1_zad ("на себе")
                  %                    +1 -> delta1 = +delta1_zad
                  % для нормальної схеми набір висоти дає ZNAK = -1,
                  % для схеми "утка" з mz_delta > 0  -> ZNAK = +1

g = 9.81;
k = 180/pi;       % переведення АДХ з 1/град у 1/рад

%% ------------------------------------------------------------------
%  1. ВИХІДНІ ДАНІ (таблиця 1). Стовпці: варіанти 1...6
%  ------------------------------------------------------------------
%              вар1        вар2       вар3       вар4      вар5      вар6
tip     = {'норм.','норм.','норм.','норм.','утка','утка'};
m_      = [ 44        33.5      41.4       38       15.9      17     ];  % кг
Iz_     = [ 13.46     12        7.872      7.45     0.968     1.114  ];  % кг*м^2
S_      = [ 0.022     0.022     0.0133     0.0133   0.011     0.011  ];  % м^2
L_      = [ 1.88      1.88      1.6        1.6      0.789     0.953  ];  % м
V_      = [ 476       306       680        476      170       197.2  ];  % м/с
theta_  = [ -9       -10        10.2       15      -34         5     ];  % град
alpha_  = [ 0.6       1.1       0.8        2.1      2.9        2     ];  % град
P_      = [ 8000      0         3500       0        0          1100  ];  % Н
cy_a_   = [ 0.273     0.368     0.2696     0.2896   0.191      0.218 ];  % 1/град
cy_d_   = [ 0.0821    0.1261    0.0476     0.0591   0.028      0.033 ];  % 1/град
mz_a_   = [-0.03628  -0.00697  -0.0591    -0.0715  -0.037     -0.046 ];  % 1/град
mz_d_   = [-0.042474 -0.00697  -0.02195   -0.0282  -0.009      0.01  ];  % 1/град
mz_wz_  = [-4.3      -2.29     -5.1       -5.3     -1.3       -1.48  ];  % безрозмірний
rho_    = [ 1.13      1.22      1.04       0.891    0.98       1.065 ];  % кг/м^3
d1zad_  = [ 4         5         10         12       20         15    ];  % град
tstr_   = [ 1         3         1          2        2          3     ];  % с

m     = m_(VAR);      Iz  = Iz_(VAR);     S   = S_(VAR);    L = L_(VAR);
V     = V_(VAR);      rho = rho_(VAR);    P   = P_(VAR);
theta = theta_(VAR)*pi/180;               alpha = alpha_(VAR)*pi/180;
d1zad = d1zad_(VAR);  tstr = tstr_(VAR);

% АДХ у 1/рад
cy_a  = cy_a_(VAR)*k;   cy_d  = cy_d_(VAR)*k;
mz_a  = mz_a_(VAR)*k;   mz_d  = mz_d_(VAR)*k;   mz_wz = mz_wz_(VAR);

fprintf('=== ВАРІАНТ %d (%s схема) ===\n', VAR, tip{VAR});
fprintf('АДХ у 1/рад: cy_a=%.5f  cy_d=%.5f  mz_a=%.5f  mz_d=%.5f\n\n', ...
        cy_a, cy_d, mz_a, mz_d);

%% ------------------------------------------------------------------
%  2. КОЕФІЦІЄНТИ ЛІНЕАРИЗОВАНОЇ МОДЕЛІ  (формули 27-31)
%  ------------------------------------------------------------------
% 1 рівняння (27)
Q1_teta = g*sin(theta)/V;
Q1_alfa = cy_a*rho*S*V/(2*m) + P*cos(alpha)/(m*V);
Q1_d1   = cy_d*rho*S*V/(2*m);
% 2 рівняння (28)
Q2_teta = -Q1_teta;
Q2_alfa = -Q1_alfa;
Q2_wz   = 1;
Q2_d1   = -Q1_d1;
% 3 рівняння (29)
Q3_wz   = 1;
% 4 рівняння (30)
Q4_alfa = mz_a *rho*V^2*S*L  /(2*Iz);
Q4_wz   = mz_wz*rho*V  *S*L^2/(2*Iz);
Q4_d1   = mz_d *rho*V^2*S*L  /(2*Iz);
% 5 рівняння (31)
Q5_teta = V*cos(theta);

fprintf('Q1_teta = %+.6f   Q1_alfa = %+.5f   Q1_d1 = %+.5f\n', Q1_teta, Q1_alfa, Q1_d1);
fprintf('Q2_teta = %+.6f   Q2_alfa = %+.5f   Q2_wz = 1   Q2_d1 = %+.5f\n', Q2_teta, Q2_alfa, Q2_d1);
fprintf('Q3_wz   = 1\n');
fprintf('Q4_alfa = %+.4f   Q4_wz   = %+.5f   Q4_d1 = %+.4f\n', Q4_alfa, Q4_wz, Q4_d1);
fprintf('Q5_teta = %+.5f\n\n', Q5_teta);

%% ------------------------------------------------------------------
%  3. МАТРИЦІ A, B, C, D  (формула 34)
%  ------------------------------------------------------------------
A = [Q1_teta  Q1_alfa  0   0        0;
     Q2_teta  Q2_alfa  0   Q2_wz    0;
     0        0        0   Q3_wz    0;
     0        Q4_alfa  0   Q4_wz    0;
     Q5_teta  0        0   0        0];

B = [Q1_d1;
     Q2_d1;
     0;
     Q4_d1;
     0];

C = eye(5);
D = [0;0;0;0;0];

disp('Матриця об''єкта A ='); disp(A);
disp('Матриця керування B ='); disp(B);

%% ------------------------------------------------------------------
%  4. АНАЛІЗ МОДЕЛІ
%  ------------------------------------------------------------------
fprintf('Власні значення матриці A:\n'); disp(eig(A));

% коротко-періодична мода (підсистема alpha - omega_z)
Asp = [Q2_alfa Q2_wz; Q4_alfa Q4_wz];
lam = eig(Asp);
w0  = abs(lam(1));  zeta = -real(lam(1))/w0;
fprintf('Коротко-періодична мода: w0 = %.3f рад/с, zeta = %.4f, T = %.3f с\n', ...
        w0, zeta, 2*pi/(w0*sqrt(max(1-zeta^2,eps))));

% усталені прирости при стрибку руля
u_ss  = ZNAK*d1zad*pi/180;
xss   = Asp\(-[Q2_d1; Q4_d1]*u_ss);
fprintf('Усталені значення при delta1 = %+g град:\n', ZNAK*d1zad);
fprintf('   d_alfa = %+.4f град;   d_wz = %+.4f град/с;   d_teta'' = %+.4f град/с\n', ...
        xss(1)*180/pi, xss(2)*180/pi, (Q1_alfa*xss(1)+Q1_d1*u_ss)*180/pi);

% нулі каналу "кут нахилу траєкторії <- руль": ознака неминімальної фазовості
z_teta = tzero(ss(A,B,C(1,:),0));
fprintf('Нулі передатної функції d_teta/d_delta1:\n'); disp(z_teta);
if any(real(z_teta) > 1e-6)
    fprintf(['--> Є нуль у правій півплощині: ланка НЕ мінімально-фазова,\n' ...
             '    на графіку висоти буде "просадка".\n\n']);
else
    fprintf('--> Нулів у правій півплощині немає: "просадки" не буде.\n\n');
end

%% ------------------------------------------------------------------
%  5. ПЕРЕХІДНІ ПРОЦЕСИ (для попереднього перегляду без Simulink)
%  ------------------------------------------------------------------
Tend = tstr + 5;
t = linspace(0, Tend, 20001)';
u = ZNAK*d1zad*pi/180 * (t >= tstr);          % стрибок на tstr
y = lsim(ss(A,B,C,D), u, t);

nm = {'\Delta\theta, град','\Delta\alpha, град','\Delta\vartheta, град', ...
      '\Delta\omega_z, град/с','\Delta H, м'};
sc = [180/pi 180/pi 180/pi 180/pi 1];
figure('Name','Перехідні процеси','Color','w','Position',[80 80 900 620]);
for i = 1:5
    subplot(3,2,i); plot(t, y(:,i)*sc(i), 'LineWidth', 1.3); grid on;
    xlabel('t, с'); ylabel(nm{i});
end
subplot(3,2,6);
idx = t <= tstr + 0.6;
plot(t(idx), y(idx,5), 'LineWidth', 1.3); grid on; hold on; yline(0,'k--');
xlabel('t, с'); ylabel('\Delta H, м'); title('Збільшений масштаб: "просадка"');

[Hmin, im] = min(y(:,5));
if Hmin < -1e-9
    fprintf('Глибина "просадки": %.4f м на t = %.3f с (стрибок подано на t = %g с)\n\n', ...
            Hmin, t(im), tstr);
end

%% ------------------------------------------------------------------
%  6. АВТОМАТИЧНЕ СКЛАДАННЯ SIMULINK-МОДЕЛІ (рис. 10)
%     Step -> Gain(pi/180) -> State-Space -> Demux -> Gain(180/pi) -> Scope
%  ------------------------------------------------------------------
mdl = 'SS_model';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl); open_system(mdl);

add_block('simulink/Sources/Step', [mdl '/Step'], 'Position',[30 190 70 230], ...
          'Time', num2str(tstr), 'Before','0', 'After', num2str(ZNAK*d1zad));
add_block('simulink/Math Operations/Gain', [mdl '/Gain 1'], ...
          'Position',[120 195 165 225], 'Gain','pi/180');
add_block('simulink/Continuous/State-Space', [mdl '/State-Space'], ...
          'Position',[220 175 330 245], 'A','A','B','B','C','C','D','D','X0','0');
add_block('simulink/Signal Routing/Demux', [mdl '/Demux'], ...
          'Position',[380 100 385 320], 'Outputs','5');

lbl = {'teta, deg','alfa, deg','tangaj, grad','wz, deg/s','H, m'};
for i = 1:5
    y0 = 60 + 55*i;
    if i < 5                                   % кутові величини -> у градуси
        gname = sprintf('%s/Gain %d', mdl, i+1);
        add_block('simulink/Math Operations/Gain', gname, ...
                  'Position',[440 y0-15 490 y0+15], 'Gain','180/pi');
        add_block('simulink/Sinks/Scope', [mdl '/' lbl{i}], ...
                  'Position',[550 y0-20 590 y0+20]);
        add_line(mdl, sprintf('Demux/%d',i), sprintf('Gain %d/1',i+1), 'autorouting','on');
        add_line(mdl, sprintf('Gain %d/1',i+1), [lbl{i} '/1'], 'autorouting','on');
    else                                       % висота — без перерахунку
        add_block('simulink/Sinks/Scope', [mdl '/' lbl{i}], ...
                  'Position',[550 y0-20 590 y0+20]);
        add_line(mdl, 'Demux/5', [lbl{i} '/1'], 'autorouting','on');
    end
end
add_line(mdl,'Step/1','Gain 1/1','autorouting','on');
add_line(mdl,'Gain 1/1','State-Space/1','autorouting','on');
add_line(mdl,'State-Space/1','Demux/1','autorouting','on');

set_param(mdl, 'StopTime', num2str(Tend), 'Solver','ode45');
save_system(mdl);
fprintf('Simulink-модель "%s.slx" створено (Stop time = %g с). Натисніть Run.\n', mdl, Tend);
