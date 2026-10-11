function push_params(p, m)
%PUSH_PARAMS  Вивантажує параметри у базовий робочий простір для Simulink.
%
%   Блоки Simulink обчислюють свої параметри у базовому workspace, тому
%   поля структури треба зробити окремими змінними з простими іменами.
%   Виклик: PUSH_PARAMS(p) або PUSH_PARAMS(p, m).

flat = {'Ra','La','Kt','Ke','Jm','Bm','JL','J','B', ...
        'w_ref','Vmax','Vmin','TL_step','TL_time'};
for k = 1:numel(flat)
    assignin('base', flat{k}, p.(flat{k}));
end

% Напруга ступінчастого сигналу розімкненої системи: рівно стільки,
% скільки потрібно для 100 рад/с у сталому режимі.
assignin('base', 'V_step', 12);

if nargin > 1
    assignin('base', 'A_m',  m.A);
    assignin('base', 'B_m',  [m.Bu m.Bd]);   % два входи: Vin та TL
    assignin('base', 'C_m',  m.C);
    assignin('base', 'D_m',  [0 0]);
    assignin('base', 'X0_m', [0; 0]);
end
end
