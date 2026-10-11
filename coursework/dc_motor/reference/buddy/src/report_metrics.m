function T = report_metrics(names, mets, p, csvfile)
%REPORT_METRICS  Друкує таблицю показників і зберігає її у CSV.
%
%   T = REPORT_METRICS(names, mets, p, csvfile)
%     names   - масив комірок з назвами регуляторів
%     mets    - масив комірок зі структурами від PERFORMANCE_METRICS
%     csvfile - (необов'язково) шлях для збереження CSV
%
%   Друкуються всі п'ять метрик з умови (ts, перерегулювання, статична
%   похибка, керуючий вплив, IAE) плюс службові величини, потрібні для
%   висновків: ITAE, піковий струм, час у насиченні, розклад керуючого
%   впливу на перехідну та сталу складові.

n = numel(names);
col = @(fld) cellfun(@(M) M.(fld), mets(:));

T = table(names(:), col('ts'), col('os'), col('ess'), col('effort'), col('iae'), ...
          col('t_first'), col('itae'), col('ise'), col('effort_tr'), col('effort_ss'), ...
          col('effort2'), col('umax'), col('umin'), col('imax'), col('tsat'), ...
   'VariableNames', {'Regulator','ts_s','OS_pct','ess_rad_s','effort_Vs','IAE_rad', ...
                     't_first_s','ITAE','ISE','effort_tr_Vs','effort_ss_Vs', ...
                     'effortV2','Umax_V','Umin_V','Imax_A','t_sat_s'});

fprintf('\n==== МЕТРИКИ З УМОВИ (Tsim = %.1f с, смуга 2%%) ====\n', mets{1}.Tsim);
fprintf('%-24s%10s%9s%12s%12s%10s\n', 'регулятор', 'ts, с', 'OS, %', ...
        'ess, рад/с', 'int|V|, В*с', 'IAE, рад');
fprintf('%s\n', repmat('-', 1, 77));
for k = 1:n
    M = mets{k};
    mark = '';
    if isfinite(M.ts) && M.ts <= p.ts_spec, mark = ' +'; else, mark = ' -'; end
    fprintf('%-24s%10.3f%9.2f%12.5f%12.2f%10.3f%s\n', names{k}, M.ts, M.os, ...
            M.ess, M.effort, M.iae, mark);
end
fprintf('%s\n', repmat('-', 1, 77));
fprintf('  "+" = вимога ts <= %.1f с виконана\n', p.ts_spec);

fprintf('\n==== ДОДАТКОВІ ВЕЛИЧИНИ ====\n');
fprintf('%-24s%10s%10s%12s%12s%9s%9s\n', 'регулятор', 'ITAE', '1-ше вх.', ...
        'int|V| пер.', 'int|V| уст.', 'Imax, А', 't нас., с');
fprintf('%s\n', repmat('-', 1, 86));
for k = 1:n
    M = mets{k};
    fprintf('%-24s%10.3f%10.3f%12.2f%12.2f%9.2f%9.3f\n', names{k}, M.itae, ...
            M.t_first, M.effort_tr, M.effort_ss, M.imax, M.tsat);
end

if nargin > 3 && ~isempty(csvfile)
    writetable(T, csvfile);
    fprintf('\nТаблицю збережено: %s\n', csvfile);
end
end
