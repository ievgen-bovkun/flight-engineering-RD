# Курсовий проєкт: керування двигуном постійного струму

Проєкт реалізує завдання з моделювання, ПІД-керування та оптимізації ДПС із
жорстко приєднаним інерційним навантаженням. Реалізація виконується поетапно;
поточний стан наведено у `docs/superpowers/dc-motor-progress.md` репозиторію.

## Поточний етап

Підготовлено конфігурацію та перевірку середовища через MATLAB CLI.
Повний проєкт потребує Simscape, Simscape Electrical, засобу експорту
самостійних FMU та сумісного налаштованого C/C++ компілятора.
Файл `results/json/environment.json` містить результати фактичної перевірки.

## Перевірка середовища

З кореня репозиторію у PowerShell:

```powershell
$matlabExe = 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe'
& $matlabExe -batch "addpath('coursework/dc_motor/matlab'); preflight(false)"
if ($LASTEXITCODE -ne 0) { throw 'Помилка MATLAB CLI' }
& $matlabExe -batch "addpath('coursework/dc_motor/matlab'); assertSuccess(runtests('coursework/dc_motor/matlab/tests/test_preflight.m'))"
if ($LASTEXITCODE -ne 0) { throw 'Перевірки не пройдено' }
```

`preflight(false)` дозволяє продовжити незалежну базову реалізацію.
`preflight(true)` є обов'язковою перевіркою повного середовища й завершується
помилкою за відсутності потрібних компонентів. Ручна взаємодія з інтерфейсом
MATLAB/Simulink для запуску, складання моделей і перевірок не потрібна.

## Джерела та припущення

- Незмінні файли колеги збережено у `reference/buddy/src/`; SHA256 наведено
  у `reference/source_manifest.json`.
- Фізичні параметри та припущення: `config/parameters.json`.
- Сценарії, початкові стани й часові сітки: `config/scenarios.json`.
- Напруга ±48 В, межа перерегулювання 5% і похибка 0,2 рад/с є явно
  позначеними інженерними припущеннями; завдання їх чисельно не задає.

Автори початкових спільних навчальних матеріалів: Dmytro Povolotskyi та
Ievgen Bovkun. Походження поточного коду колеги збережено у маніфесті;
підсумковий звіт має відокремлювати запозичений код від виправлень і нових
перевірених результатів.

## Незалежна реалізація Python

Після створення `.venv` встановіть зафіксовані залежності й виконайте:

```powershell
$pythonExe = '.\coursework\dc_motor\.venv\Scripts\python.exe'
& $pythonExe -m pip install -r coursework/dc_motor/requirements.txt
& $pythonExe -m pytest coursework/dc_motor/python/tests -q
& $pythonExe coursework/dc_motor/python/run_comparisons.py
```

Python обчислює власні траєкторії з рівнянь ДПС за допомогою SciPy DOP853.
Порівняння з MATLAB наведено у `results/csv/python_matlab_comparison.csv`.
Відсутні або застарілі коефіцієнти оптимізації не замінюються прихованими
значеннями: перевіряються SHA256 конфігурації та MATLAB-коду.

## Встановлення потрібних продуктів через CLI

У PowerShell з правами адміністратора:

```powershell
& '.\coursework\dc_motor\scripts\install_matlab_prerequisites.ps1'
```

Скрипт використовує офіційний MathWorks Package Manager, перевіряє підпис
і додає Simscape, Simscape Electrical та Simulink FMU Builder до
`C:\Program Files\MATLAB\R2026a` із рівнем оновлення 4. Режим `-CheckOnly`
лише показує потрібні продукти та права процесу. Інсталятор ще не запускався.
Після встановлення необхідна повторна перевірка середовища; компілятор
для FMU може потребувати окремого налаштування.

Перевірені результати на цьому етапі: 26 перевірок MATLAB і 11 перевірок
Python. Simscape, FMU, фінальний PDF та ZIP ще не завершено.
