function [mdl, ok] = build_model_simscape(p, outdir)
%BUILD_MODEL_SIMSCAPE  Фізична модель ДПС на блоках Simscape (розділ 2.6).
%
%   [mdl, ok] = BUILD_MODEL_SIMSCAPE(p, outdir)
%
%   ТОПОЛОГІЯ
%   ---------
%     Vin (Simulink) -> Simulink-PS Converter -> Controlled Voltage Source
%        -> Current Sensor -> DC Motor (+/-)  ...  Electrical Reference
%     Вал DC Motor (порт R) -> Inertia (JL) + Ideal Rotational Motion Sensor
%                            + Ideal Torque Source (збурення TL)
%     Корпус двигуна (порт C) -> Mechanical Rotational Reference
%     Датчики -> PS-Simulink Converter -> To Workspace
%
%   ВАЖЛИВО ПРО ПАРАМЕТРИ
%   ---------------------
%   Блок DC Motor вже МІСТИТЬ власні інерцію ротора та в'язке тертя, тому:
%     * Jm = 0.01 та Bm = 0.001 задаються ВСЕРЕДИНІ блока DC Motor;
%     * зовні додається ЛИШЕ інерція навантаження JL = 0.02 (блок Inertia);
%     * окремий Rotational Damper НЕ ставиться - це подвоїло б тертя.
%   Саме тому скриптова модель розділу 2.1 з J = 0.03 і B = 0.001 має
%   збігтися з цією моделлю точно, а не приблизно.
%
%   ПРО НАДІЙНІСТЬ ЦЬОГО СКРИПТА
%   ----------------------------
%   Шляхи та імена параметрів блоків Simscape змінюються між релізами
%   MATLAB, тому програмна побудова тут принципово менш надійна, ніж для
%   звичайних блоків Simulink. Скрипт перебирає кілька варіантів шляхів
%   (ADD_BLOCK_ANY) та кілька варіантів імен параметрів. Якщо щось не
%   вдалося - він друкує, що саме, і не падає: модель треба буде зібрати
%   вручну за покроковою інструкцією models/SIMSCAPE_BUILD.md, а решта
%   проєкту від цього не залежить.

if nargin < 2, outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'models'); end
if ~exist(outdir, 'dir'), mkdir(outdir); end

mdl = 'motor_simscape';
push_params(p);
ok = true;
problems = {};

if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

% ---------- бібліотечні шляхи (кілька варіантів на блок) ----------
LIB.dcmotor = {'ee_lib/Electromechanical/Brushed Motors/DC Motor', ...
               'ee_lib/Electromechanical/DC Motor', ...
               'elec_lib/Electromechanical/DC Motor'};
LIB.cvs     = {'ee_lib/Sources/Controlled Voltage Source', ...
               'fl_lib/Electrical/Electrical Sources/Controlled Voltage Source', ...
               'elec_lib/Sources/Controlled Voltage Source'};
LIB.isens   = {'ee_lib/Sensors & Transducers/Current Sensor', ...
               'fl_lib/Electrical/Electrical Sensors/Current Sensor'};
LIB.eref    = {'ee_lib/Connectors & References/Electrical Reference', ...
               'fl_lib/Electrical/Electrical Elements/Electrical Reference'};
LIB.wsens   = {'fl_lib/Mechanical/Mechanical Sensors/Ideal Rotational Motion Sensor', ...
               'ee_lib/Sensors & Transducers/Ideal Rotational Motion Sensor'};
LIB.inertia = {'fl_lib/Mechanical/Rotational Elements/Inertia'};
LIB.mref    = {'fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference'};
LIB.tsrc    = {'fl_lib/Mechanical/Rotational Sources/Ideal Torque Source'};
LIB.solver  = {'nesl_utility/Solver Configuration'};
LIB.s2ps    = {'nesl_utility/Simulink-PS Converter'};
LIB.ps2s    = {'nesl_utility/PS-Simulink Converter'};

sub = [mdl '/Motor Model Subsystem'];
add_block('simulink/Ports & Subsystems/Subsystem', sub, 'Position', [260 90 440 230]);
delete_line(sub, 'In1/1', 'Out1/1');
delete_block([sub '/In1']);  delete_block([sub '/Out1']);

B = @(n) [sub '/' n];
place = @(x, y, w, h) [x y x+w y+h];

% ---------- блоки підсистеми ----------
add_block('simulink/Sources/In1',  B('Vin'), 'Port','1', 'Position', place(30,  95, 30, 14));
add_block('simulink/Sources/In1',  B('TL'),  'Port','2', 'Position', place(30, 305, 30, 14));
add_block('simulink/Sinks/Out1',   B('omega_out'), 'Port','1', 'Position', place(640, 195, 30, 14));
add_block('simulink/Sinks/Out1',   B('i_out'),     'Port','2', 'Position', place(640,  95, 30, 14));

add_here(LIB.s2ps,   B('V2PS'),   place(90,   90, 45, 30), {});
add_here(LIB.s2ps,   B('T2PS'),   place(90,  300, 45, 30), {});
add_here(LIB.cvs,    B('Vsrc'),   place(170,  90, 50, 60), {});
add_here(LIB.isens,  B('Isens'),  place(250,  70, 50, 50), {});
add_here(LIB.eref,   B('Eref'),   place(180, 200, 30, 25), {});
add_here(LIB.dcmotor,B('Motor'),  place(350,  90, 70, 70), {});
add_here(LIB.inertia,B('Load'),   place(470,  80, 50, 40), {});
add_here(LIB.tsrc,   B('Tsrc'),   place(350, 290, 50, 50), {});
add_here(LIB.wsens,  B('Wsens'),  place(470, 190, 50, 50), {});
add_here(LIB.mref,   B('Mref'),   place(370, 380, 30, 25), {});
add_here(LIB.ps2s,   B('PS2w'),   place(560, 190, 45, 30), {});
add_here(LIB.ps2s,   B('PS2i'),   place(560,  90, 45, 30), {});
add_here(LIB.solver, B('Solver'), place(250, 400, 45, 35), ...
         {'SimscapeSolverType','daessc'});

% ---------- параметри двигуна та навантаження ----------
% Імена параметрів різняться між версіями, тому пробуємо кілька варіантів.
set_any(B('Motor'), {'R','Rarm','armature_resistance'},  'Ra',  'опір якоря');
set_any(B('Motor'), {'L','Larm','armature_inductance'},  'La',  'індуктивність якоря');
set_any(B('Motor'), {'back_emf_constant','Kv','kv','Ke'},'Ke',  'стала протиЕРС');
set_any(B('Motor'), {'J','inertia','rotor_inertia'},     'Jm',  'інерція ротора');
set_any(B('Motor'), {'b','lam','rotor_damping','Bv'},    'Bm',  'тертя ротора');
set_any(B('Load'),  {'inertia','J'},                     'JL',  'інерція навантаження');

% ---------- з'єднання ----------
% Фізичні порти адресуються як LConn1/RConn1; їх нумерація теж версійна,
% тому кожне з'єднання обгорнуте try/catch із діагностикою.
cn(sub, 'Vin/1',   'V2PS/1');
cn(sub, 'TL/1',    'T2PS/1');
cn(sub, 'V2PS/RConn1', 'Vsrc/LConn1');
cn(sub, 'Vsrc/RConn1', 'Isens/LConn1');
cn(sub, 'Isens/RConn1','Motor/LConn1');
cn(sub, 'Motor/LConn2','Eref/LConn1');
cn(sub, 'Vsrc/LConn2', 'Eref/LConn1');
cn(sub, 'Motor/RConn1','Load/LConn1');
cn(sub, 'Motor/RConn1','Wsens/LConn1');
cn(sub, 'Motor/RConn1','Tsrc/RConn1');
cn(sub, 'Motor/RConn2','Mref/LConn1');
cn(sub, 'Wsens/RConn1','Mref/LConn1');
cn(sub, 'Tsrc/LConn1', 'Mref/LConn1');
cn(sub, 'T2PS/RConn1', 'Tsrc/RConn2');
cn(sub, 'Wsens/RConn2','PS2w/LConn1');
cn(sub, 'Isens/RConn2','PS2i/LConn1');
cn(sub, 'PS2w/1',  'omega_out/1');
cn(sub, 'PS2i/1',  'i_out/1');
cn(sub, 'Solver/RConn1', 'Eref/LConn1');

% ---------- верхній рівень ----------
add_block('simulink/Sources/Step', [mdl '/Vin'], 'Time','0', 'Before','0', ...
          'After','V_step', 'Position', place(80, 105, 30, 30));
add_block('simulink/Sources/Step', [mdl '/TL'], 'Time','TL_time', 'Before','0', ...
          'After','TL_step', 'Position', place(80, 185, 30, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/omega_log'], ...
          'VariableName','omega_ss_phys', 'SaveFormat','Structure With Time', ...
          'SampleTime','-1', 'Position', place(520, 105, 60, 30));
add_block('simulink/Sinks/To Workspace', [mdl '/i_log'], ...
          'VariableName','i_phys', 'SaveFormat','Structure With Time', ...
          'SampleTime','-1', 'Position', place(520, 185, 60, 30));
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'Position', place(520, 265, 30, 30));

cn(mdl, 'Vin/1', 'Motor Model Subsystem/1');
cn(mdl, 'TL/1',  'Motor Model Subsystem/2');
cn(mdl, 'Motor Model Subsystem/1', 'omega_log/1');
cn(mdl, 'Motor Model Subsystem/2', 'i_log/1');
cn(mdl, 'Motor Model Subsystem/1', 'Scope/1');

set_param(mdl, 'Solver','ode23t', 'StopTime','30', ...
               'RelTol','1e-8', 'AbsTol','1e-10');

if isempty(problems)
    fprintf('  [OK] Simscape-модель зібрано повністю.\n');
else
    ok = false;
    fprintf('  [!] Не вдалося виконати %d кроків побудови:\n', numel(problems));
    for k = 1:numel(problems), fprintf('      - %s\n', problems{k}); end
    fprintf(['      Зберіть модель вручну за інструкцією\n' ...
             '      models/SIMSCAPE_BUILD.md - решта проєкту від цього не залежить.\n']);
end

try
    save_system(mdl, fullfile(outdir, [mdl '.slx']));
    fprintf('  [OK] Збережено: %s\n', fullfile(outdir, [mdl '.slx']));
catch ME
    ok = false;
    fprintf('  [!] Не вдалося зберегти модель: %s\n', ME.message);
end

% ================= вкладені функції =================
    function add_here(cands, dest, pos, extra)
        args = [{'Position', pos}, extra];
        [good, ~] = add_block_any(cands, dest, args{:});
        if ~good
            problems{end+1} = sprintf('не знайдено блок для %s', dest); %#ok<AGROW>
        end
    end

    function set_any(blk, names, valexpr, descr)
        for q = 1:numel(names)
            try
                set_param(blk, names{q}, valexpr);
                return;
            catch
            end
        end
        problems{end+1} = sprintf('параметр "%s" блока %s (спробуйте вручну)', ...
                                  descr, blk); %#ok<AGROW>
    end

    function cn(where, a, bq)
        try
            add_line(where, a, bq, 'autorouting', 'on');
        catch
            problems{end+1} = sprintf('з''єднання %s -> %s', a, bq); %#ok<AGROW>
        end
    end
end
