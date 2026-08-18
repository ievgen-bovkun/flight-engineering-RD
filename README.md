# Flight Engineering — MATLAB/Simulink

Навчальний репозиторій із моделювання динамічних систем і літальних апаратів у
MATLAB/Simulink. Роботи охоплюють нелінійну модель квадрокоптера, аналітичне й
числове дослідження перевернутого маятника, повороти в системі координат NED та
власну реалізацію рівнянь руху твердого тіла з шістьма степенями свободи.

## Домашні роботи

| Папка | Зміст | Основний запуск | Звіт |
|---|---|---|---|
| [`homework1/`](homework1/) | Нелінійна 6DOF-модель квадрокоптера, модель двигунів і тест-кейси `vertical`, `roll`, `pitch`, `yaw` | [`homework1/run_sim.m`](homework1/run_sim.m) або [`homework1/run_simulink_demo.m`](homework1/run_simulink_demo.m) | [PDF](homework1/report/Task1_Report.pdf), [Markdown](homework1/report/Task1_Report.md) |
| [`homework2/`](homework2/) | Перевернутий маятник, порівняння числових методів, матриці поворотів NED і символьне виведення рівнянь | [`homework2/run_homework2.m`](homework2/run_homework2.m) | [Маятник](homework2/report/Task1_Inverted_Pendulum.md), [NED-повороти](homework2/report/Task2_NED_Rotations.md), [символьна задача](homework2/report/Task3_Symbolic_Pendulum.md) |
| [`homework3/`](homework3/) | Власна система рівнянь 6DOF у NED та порівняння зі стандартним Aerospace Block на 11 сценаріях | [`homework3/scripts/run_dz3_comparison.m`](homework3/scripts/run_dz3_comparison.m) | [Фінальний PDF](homework3/report/DZ3_6DOF_NED_Report_Final.pdf), [DOCX](homework3/report/DZ3_6DOF_NED_Report.docx) |

## Структура репозиторію

```text
flight-engineering-RD/
├── homework1/   # нелінійна модель квадрокоптера
├── homework2/   # маятник, NED-повороти та символьні розрахунки
└── homework3/   # власна 6DOF NED-модель і порівняння з Aerospace Block
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

## Репозиторій

- GitHub: <https://github.com/ievgen-bovkun/flight-engineering-RD>
- Гілка ДЗ 3: [`codex/homework3-ned`](https://github.com/ievgen-bovkun/flight-engineering-RD/tree/codex/homework3-ned)
