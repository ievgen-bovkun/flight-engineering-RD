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

Перевірені результати на цьому етапі: 30 перевірок MATLAB і 16 перевірок
Python. Проміжний PDF сформовано та візуально перевірено на всіх 11 сторінках; Simscape, FMU, фінальний PDF та ZIP ще не завершено.

## Відтворення перевіреного етапу та проміжний PDF

З кореня репозиторію:

```powershell
& '.\coursework\dc_motor\scripts\run_all.ps1' -Mode Core
```

Команда перевіряє MATLAB, перебудовує реалізовані моделі й результати,
запускає перевірки MATLAB, незалежні порівняння Python, створює проміжний
український PDF і запускає перевірки Python/звіту. Збережені коефіцієнти
оптимізації використовуються лише після перевірки SHA256. Для нового
пошуку додайте `-RegenerateOptimization`; відсутні чи застарілі дані
без цього прапорця завершують виконання помилкою.

Результат: `report/DC_Motor_Progress_UA.pdf`. Маніфест вхідних даних:
`results/run_manifest.json`. `report/report_uk.md` містить український
текст, а таблиці й рисунки підставляються з перевірених результатів.

Окреме повторне складання проміжного документа без симуляції:

```powershell
& '.\coursework\dc_motor\.venv\Scripts\python.exe' coursework/dc_motor/report/build_report.py --draft
```

Змінені чи відсутні файли маніфесту відхиляються. Відсутність `--draft`
означає фінальний режим, який зараз завершується помилкою через незавершені
обов'язкові Simscape/FMU та перевірку чистої копії. `-Mode Full` також
не може повідомити про успішну здачу за відсутності цих етапів.
## Lag/lead: перевірена референсна частина

Core також виконує `run_compensator_study()`: ПІД, lag та lead на рівняннях
двигуна за однакових меж напруги і горизонту 12 с. Дані:
`results/csv/compensator_reference_metrics.csv`.

Lag: час усталення 2.330 с, похибка 0.160 рад/с; lead: 1.781 с,
похибка 1.525 рад/с. Ці два налаштування не виконують усі обрані критерії
ПІД. У цьому випадку lead витрачає трохи менше абсолютного керуючого
впливу, тому загальне твердження «lead завжди потребує більше напруги»
не використовується. Поля `implementation` і `physicalValidated=false`
явно позначають відсутність фізичної Simscape-перевірки.