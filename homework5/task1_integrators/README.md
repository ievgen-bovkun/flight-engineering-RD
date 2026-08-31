# ДЗ №5, завдання 1 — RK4 і RKF45

Реалізовані функції:

- `src/rk4_step.m`, `src/rk4_integrate.m` — RK4 з фіксованим кроком;
- `src/rkf45_step.m`, `src/rkf45_integrate.m` — класичний Fehlberg 4(5), оцінка похибки та адаптація кроку;
- `scripts/run_task1_integrator_study.m` — відтворюваний частотний експеримент.

Запуск:

```matlab
addpath('hw5_numerical_methods/task1_integrators/src');
addpath('hw5_numerical_methods/task1_integrators/scripts');
summary = run_task1_integrator_study();
results = runtests('hw5_numerical_methods/task1_integrators/tests');
assertSuccess(results);
```

Точний еталон: `y(t)=sin(2*pi*f*t)` для рівняння `y'=2*pi*f*cos(2*pi*f*t)`. Результати зберігаються у `results/task1_metrics.csv`.
