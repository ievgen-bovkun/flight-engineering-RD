function info = check_feasibility(p, m, Vlist)
%CHECK_FEASIBILITY  Чи взагалі досяжна вимога "100 рад/с за 2 с"?
%
%   info = CHECK_FEASIBILITY(p, m, Vlist)
%
%   ІДЕЯ
%   ----
%   Жоден регулятор не змусить двигун розігнатися швидше, ніж це дозволяє
%   максимальна напруга. Оскільки об'єкт лінійний і монотонний за входом,
%   найшвидший можливий розгін до заданої швидкості дає ПОСТІЙНА напруга
%   Vmax (стратегія "повний газ"). Час, за який відгук на ступінь Vmax
%   вперше досягає w_ref, є нижньою межею часу перехідного процесу для
%   БУДЬ-ЯКОГО закону керування.
%
%   Якщо ця нижня межа більша за вимогу - задача нерозв'язна, і питання не
%   в налаштуванні регулятора, а у виборі джерела живлення.

if nargin < 3 || isempty(Vlist), Vlist = [12 24 36 40 48 60 72]; end

t  = (0:1e-4:20)';
y1 = step(m.G, t);                       % відгук на 1 В

info.V = Vlist(:);
info.t_reach = nan(numel(Vlist), 1);
for k = 1:numel(Vlist)
    y = Vlist(k)*y1;
    idx = find(y >= p.w_ref, 1, 'first');
    if isempty(idx), info.t_reach(k) = Inf; else, info.t_reach(k) = t(idx); end
end

% Напруга, потрібна щоб ДОСЯГТИ w_ref рівно за ts_spec (без запасу на
% гальмування та входження у смугу 2%)
y_at_spec = interp1(t, y1, p.ts_spec);
info.V_min_touch = p.w_ref / y_at_spec;
info.V_ss        = p.w_ref / dcgain(m.G);
info.t_spec      = p.ts_spec;
end
