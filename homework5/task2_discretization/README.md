# ДЗ №5, завдання 2 — дискретизація передатної функції

Неперервна модель:

```matlab
Tff = tf([0.3333], [1 1 33.33]);
```

Реалізовано `zoh`, `foh`, Tustin через `c2d` та окрему функцію `exact_zoh_discretize.m`. Власний метод використовує матричну експоненту розширеної матриці й не викликає `c2d`.

Запуск:

```matlab
addpath('homework5/task2_discretization/src');
addpath('homework5/task2_discretization/scripts');
result = run_task2_discretization_study();
tests = runtests('homework5/task2_discretization/tests');
assertSuccess(tests);
```

Порівнюються частоти дискретизації 10, 100 і 1000 Гц. Для девіації такту залишаються номінальні коефіцієнти дискретної моделі, а фактичні частоти дорівнюють `0.9*Fs`, `Fs`, `1.1*Fs`.
