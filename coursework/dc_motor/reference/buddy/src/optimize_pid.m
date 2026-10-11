function R = optimize_pid(p, cfg, starts)
%OPTIMIZE_PID  Налаштування коефіцієнтів ПІД двома алгоритмами (розділ 2.3).
%
%   R = OPTIMIZE_PID(p, cfg, starts)
%
%   Оптимізація ведеться за log10(K), а не за самими коефіцієнтами. Причини:
%     * коефіцієнти відрізняються на порядки (Ki ~ 75, Kd ~ 4), і в лінійних
%       координатах симплекс Нелдера-Міда деформується;
%     * логарифм автоматично тримає K > 0 без жодних обмежень;
%     * крок стає відносним, тому однаково добре працює для великих і малих
%       значень.
%
%   Метод 1: Нелдер-Мід (fminsearch) з кількох стартових точок. Пряма
%   безградієнтна мінімізація - саме те, що треба, бо цільова функція
%   недиференційовна: насичення напруги та штрафи дають зломи.
%
%   Метод 2: власний генетичний алгоритм GA_SIMPLE - глобальний пошук,
%   не залежить від стартової точки.

if nargin < 2, cfg = struct(); end
if nargin < 3 || isempty(starts)
    starts = [ 33.63  75.00  3.895     % базовий з розділу 2.2
               10.00  20.00  1.300
               60.00 150.00  6.000
                5.00   6.00  0.700
              100.00 300.00 10.000 ];
end

fobj = @(x) pid_cost(10.^x, p, cfg);

% ---------- Метод 1: мультистартовий Нелдер-Мід ----------
fprintf('  Нелдер-Мід, %d стартових точок:\n', size(starts,1));
opt = optimset('Display','off','TolX',1e-5,'TolFun',1e-9, ...
               'MaxIter',800,'MaxFunEvals',1200);
bestF = Inf;  bestX = [];  nev = 0;
for k = 1:size(starts,1)
    t0 = tic;
    [xk, fk, ~, out] = fminsearch(fobj, log10(starts(k,:)), opt);
    nev = nev + out.funcCount;
    fprintf('    старт [%7.2f %7.2f %6.3f] -> J = %.6f  (%d обчисл., %.1f с)\n', ...
            starts(k,1), starts(k,2), starts(k,3), fk, out.funcCount, toc(t0));
    if fk < bestF, bestF = fk; bestX = xk; end
end
R.nm.K = 10.^bestX;  R.nm.J = bestF;  R.nm.nfev = nev;

% ---------- Метод 2: генетичний алгоритм ----------
fprintf('  Генетичний алгоритм:\n');
lb = log10([  2,   1, 0.10]);
ub = log10([300, 800, 40.0]);
t0 = tic;
[xg, fg, R.ga.hist] = ga_simple(fobj, lb, ub, ...
        struct('pop',40,'gen',50,'seed',7,'verbose',true));
R.ga.K = 10.^xg;  R.ga.J = fg;
fprintf('    готово за %.1f с\n', toc(t0));

% ---------- Кращий із двох ----------
if R.ga.J < R.nm.J
    R.K = R.ga.K;  R.J = R.ga.J;  R.method = 'генетичний алгоритм';
else
    R.K = R.nm.K;  R.J = R.nm.J;  R.method = 'Нелдер-Мід';
end
R.cfg = cfg;
end
