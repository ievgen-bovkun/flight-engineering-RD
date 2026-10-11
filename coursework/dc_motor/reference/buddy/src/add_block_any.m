function [ok, used] = add_block_any(candidates, dest, varargin)
%ADD_BLOCK_ANY  Додає блок, перебираючи кілька можливих шляхів у бібліотеці.
%
%   [ok, used] = ADD_BLOCK_ANY({'шлях1','шлях2',...}, dest, 'Param', val, ...)
%
%   НАВІЩО
%   ------
%   Шляхи до блоків Simscape відрізняються між релізами MATLAB: те, що в
%   одній версії лежить у 'ee_lib/...', в іншій знаходиться у 'fl_lib/...'
%   або 'elec_lib/...'. Жорстко прописаний шлях зробив би скрипт непрацездатним
%   на будь-якій версії, крім тієї, де його писали. Ця обгортка пробує
%   варіанти по черзі й повідомляє, який спрацював.
%
%   Повертає ok = false, якщо не підійшов жоден шлях - тоді скрипт-виклик
%   має повідомити користувача і запропонувати зібрати блок вручну
%   (див. models/SIMSCAPE_BUILD.md).

ok = false;  used = '';
if ischar(candidates), candidates = {candidates}; end

for k = 1:numel(candidates)
    try
        add_block(candidates{k}, dest, varargin{:});
        ok = true;  used = candidates{k};
        return;
    catch
        % пробуємо наступний шлях
    end
end

% Остання спроба: пошук за іменем блока по всіх завантажених бібліотеках
[~, nm] = fileparts(candidates{1});
try
    load_system('simscape');
catch
end
hits = find_system(find_system('SearchDepth', 0, 'BlockDiagramType', 'library'), ...
                   'LookUnderMasks','all', 'Name', nm);
if ~isempty(hits)
    try
        add_block(getfullname(hits{1}), dest, varargin{:});
        ok = true;  used = getfullname(hits{1});
    catch
    end
end
end
