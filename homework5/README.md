# ДЗ №5 — чисельні методи та дискретизація

Робота має дві незалежні частини:

- `task1_integrators` — власні RK4 і RKF45, перевірені на синусоїдах 10–10000 Гц;
- `task2_discretization` — дискретизація `0.3333/(s^2+s+33.33)` методами `zoh`, `foh`, Tustin і власним точним ZOH.

## Запуск

У MATLAB з кореня репозиторію:

```matlab
addpath('hw5_numerical_methods/task1_integrators/src');
addpath('hw5_numerical_methods/task1_integrators/scripts');
task1 = run_task1_integrator_study();

addpath('hw5_numerical_methods/task2_discretization/src');
addpath('hw5_numerical_methods/task2_discretization/scripts');
task2 = run_task2_discretization_study();

tests = runtests({'hw5_numerical_methods/task1_integrators/tests', ...
                  'hw5_numerical_methods/task2_discretization/tests'});
assertSuccess(tests);
```

`task1_integrators/results` і `task2_discretization/results` містять CSV, MAT та PNG, які відтворюються цими командами.
