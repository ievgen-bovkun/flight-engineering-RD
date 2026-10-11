function [xbest, fbest, hist] = ga_simple(fun, lb, ub, opts)
%GA_SIMPLE  Дійсно-кодований генетичний алгоритм (без Global Optimization Toolbox).
%
%   [xbest, fbest, hist] = GA_SIMPLE(fun, lb, ub, opts)
%
%   Реалізовано самостійно, щоб проєкт не залежав від наявності тулбокса і
%   щоб вимога "реалізувати алгоритм оптимізації" була виконана буквально.
%
%   Схема алгоритму:
%     1) популяція ініціалізується латинським гіперкубом (рівномірніше
%        покриття простору, ніж чистий rand);
%     2) селекція - турнір розміром 3;
%     3) схрещування BLX-alpha: нащадок береться з розширеного інтервалу
%        між батьками, що дає помірну розвідку за межами відрізка;
%     4) мутація - гаусів шум із сигмою, що спадає з поколіннями
%        (широкий пошук на початку, тонке доведення в кінці);
%     5) елітизм: найкращі особини переходять у наступне покоління без змін.
%
%   Вхід:
%     fun      - цільова функція, f(x) для вектора-рядка x
%     lb, ub   - нижні/верхні межі (вектори)
%     opts     - .pop (40) .gen (60) .elite (2) .pcross (0.9) .pmut (0.2)
%                .sigma0 (0.15) .verbose (true) .seed ([])

if nargin < 4, opts = struct(); end
d = struct('pop',40,'gen',60,'elite',2,'pcross',0.9,'pmut',0.2, ...
           'sigma0',0.15,'verbose',true,'seed',[]);
fn = fieldnames(d);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = d.(fn{k}); end
end
if ~isempty(opts.seed), rng(opts.seed); end

lb = lb(:)';  ub = ub(:)';  n = numel(lb);
P  = opts.pop;

% --- ініціалізація латинським гіперкубом ---
X = zeros(P, n);
for j = 1:n
    X(:,j) = lb(j) + (ub(j)-lb(j)) * ((randperm(P)' - rand(P,1))/P);
end

F = arrayfun(@(k) fun(X(k,:)), (1:P)');
[fbest, ib] = min(F);
xbest = X(ib,:);
hist = zeros(opts.gen, 2);

for g = 1:opts.gen
    sigma = opts.sigma0 * (1 - 0.9*(g-1)/max(1,opts.gen-1));   % спадна мутація

    [~, ord] = sort(F);
    Xnew = X(ord(1:opts.elite), :);                            % еліта

    while size(Xnew,1) < P
        p1 = X(tournament(F), :);
        p2 = X(tournament(F), :);

        if rand < opts.pcross                                  % BLX-alpha
            a  = 0.5;
            lo = min(p1,p2) - a*abs(p1-p2);
            hi = max(p1,p2) + a*abs(p1-p2);
            c  = lo + rand(1,n).*(hi-lo);
        else
            c = p1;
        end

        mask = rand(1,n) < opts.pmut;                          % гаусова мутація
        c(mask) = c(mask) + sigma*(ub(mask)-lb(mask)).*randn(1,sum(mask));

        c = min(max(c, lb), ub);
        Xnew(end+1,:) = c; %#ok<AGROW>
    end

    X = Xnew(1:P, :);
    F = arrayfun(@(k) fun(X(k,:)), (1:P)');

    [fg, ig] = min(F);
    if fg < fbest, fbest = fg; xbest = X(ig,:); end
    hist(g,:) = [fbest, mean(F)];

    if opts.verbose && (mod(g,10) == 0 || g == 1)
        fprintf('    покоління %3d: найкраще J = %.6f, середнє = %.6f\n', g, fbest, mean(F));
    end
end
end

% ----------------------------------------------------------------------
function idx = tournament(F)
%TOURNAMENT  Турнірна селекція розміром 3.
c = randi(numel(F), 1, 3);
[~, k] = min(F(c));
idx = c(k);
end
