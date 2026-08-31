# Flight Engineering — MATLAB/Simulink

Навчальний репозиторій із моделювання динамічних систем і літальних апаратів у
MATLAB/Simulink. Роботи охоплюють нелінійну модель квадрокоптера, аналітичне й
числове дослідження перевернутого маятника, повороти в системі координат NED та
власну реалізацію рівнянь руху твердого тіла з шістьма степенями свободи.
Додатково репозиторій містить лінеаризовану модель поздовжнього руху ЛА та
дослідження чисельних інтеграторів і дискретизації передатної функції.

## Домашні роботи

| Папка | Зміст | Основний запуск | Звіт |
|---|---|---|---|
| [`homework1/`](homework1/) | Нелінійна 6DOF-модель квадрокоптера, модель двигунів і тест-кейси `vertical`, `roll`, `pitch`, `yaw` | [`homework1/run_sim.m`](homework1/run_sim.m) або [`homework1/run_simulink_demo.m`](homework1/run_simulink_demo.m) | [PDF](homework1/report/Task1_Report.pdf), [Markdown](homework1/report/Task1_Report.md) |
| [`homework2/`](homework2/) | Перевернутий маятник, порівняння числових методів, матриці поворотів NED і символьне виведення рівнянь | [`homework2/run_homework2.m`](homework2/run_homework2.m) | [Маятник](homework2/report/Task1_Inverted_Pendulum.md), [NED-повороти](homework2/report/Task2_NED_Rotations.md), [символьна задача](homework2/report/Task3_Symbolic_Pendulum.md) |
| [`homework3/`](homework3/) | Власна система рівнянь 6DOF у NED та порівняння зі стандартним Aerospace Block на 11 сценаріях | [`homework3/scripts/run_dz3_comparison.m`](homework3/scripts/run_dz3_comparison.m) | [Фінальний PDF](homework3/report/DZ3_6DOF_NED_Report_Final.pdf), [DOCX](homework3/report/DZ3_6DOF_NED_Report.docx) |
| [`homework4/`](homework4/) | Лінеаризація поздовжнього руху ЛА, простір станів і порівняння MATLAB `lsim` / Simulink | [`homework4/scripts/run_dz4_variant1.m`](homework4/scripts/run_dz4_variant1.m) | [PDF](homework4/report/DZ4_Longitudinal_Linearization_Report.pdf) |
| [`homework5/`](homework5/) | Власні RK4 та RKF45, точна ZOH-дискретизація, порівняння ZOH / FOH / Tustin і девіація частоти | Скрипти в [`task1_integrators`](homework5/task1_integrators/) та [`task2_discretization`](homework5/task2_discretization/) | [PDF](homework5/report/DZ5_Numerical_Methods_Report.pdf) |

## Структура репозиторію

```text
flight-engineering-RD/
├── homework1/   # нелінійна модель квадрокоптера
├── homework2/   # маятник, NED-повороти та символьні розрахунки
├── homework3/   # власна 6DOF NED-модель і порівняння з Aerospace Block
├── homework4/   # лінеаризована поздовжня модель ЛА
└── homework5/   # RK4/RKF45 та дискретизація передатної функції
```

Кожна домашня робота зберігає вихідний MATLAB-код, Simulink-моделі, тести,
графіки та звітні матеріали у власній папці.

## Вимоги

- MATLAB R2026a або сумісна версія;
- Simulink;
- Aerospace Blockset для порівняльної моделі ДЗ 3;
- Symbolic Math Toolbox для символьної частини ДЗ 2.

## Швидкий запуск

Клонуйте репозиторій та відкрийте його кореневу папку в MATLAB:

```matlab
% Домашня робота 1
cd homework1
run_sim

% Домашня робота 2
cd ../homework2
run_homework2

% Домашня робота 3
cd ../homework3/scripts
run_dz3_comparison

% Домашня робота 4
cd ../../homework4/scripts
run_dz4_variant1

% Домашня робота 5
cd ../../homework5
addpath('task1_integrators/src'); addpath('task1_integrators/scripts');
run_task1_integrator_study
addpath('task2_discretization/src'); addpath('task2_discretization/scripts');
run_task2_discretization_study
```

Simulink-модель ДЗ 3 можна також відкрити безпосередньо:
[`homework3/models/dz3_6dof_ned_compare.slx`](homework3/models/dz3_6dof_ned_compare.slx).
Її `InitFcn` створює безпечні нульові сили та моменти, якщо сценарні входи не
були підготовлені заздалегідь.

## Перевірки

Для ДЗ 3 реалізовано 10 автоматичних перевірок: математичні unit-тести,
контроль структури Simulink-моделі, прямий запуск без підготовки workspace та
наскрізне порівняння Custom NED/Aerospace. Зафіксований результат:
`10/10 PASS`.

```matlab
cd homework3/scripts
runtests('../tests')
```

Для ДЗ 5 реалізовано 14 автоматичних перевірок RK4, RKF45, власної
ZOH-дискретизації та сформованих результатів:

```matlab
runtests({'homework5/task1_integrators/tests', ...
          'homework5/task2_discretization/tests'})
```

## Репозиторій

- GitHub: <https://github.com/ievgen-bovkun/flight-engineering-RD>
- ДЗ 1-5: [`main`](https://github.com/ievgen-bovkun/flight-engineering-RD/tree/main)
