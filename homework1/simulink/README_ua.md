# Нелінійна модель квадрокоптера у Simulink

## Перший запуск

1. У MATLAB відкрийте папку `C:\Users\ievge\MatLabProjects\task1\simulink`.
2. У Command Window введіть `build_quadrotor_simulink`.
3. Відкриється та збережеться модель `quadrotor_nonlinear.slx`.
4. Натисніть зелений трикутник **Run** у Simulink для вертикального тесту.

Модель використовує NED-координати: від'ємне `z` означає набір висоти.

## Тести каналів

У Command Window по черзі виконайте:

```matlab
vertical = run_simulink_channel('vertical');
roll = run_simulink_channel('roll');
pitch = run_simulink_channel('pitch');
yaw = run_simulink_channel('yaw');
```

Кожна команда задає Step амплітудою `1` після `t = 1 s`, запускає модель протягом 4 с і будує один рисунок. Короткий інтервал обрано свідомо: відкритий контур без регулятора швидко входить у великі кути.

| Канал | Step для двигунів 1-4 | Основна реакція |
|---|---|---|
| `vertical` | `[1 1 1 1]` | Зміна висоти `z` |
| `roll` | `[0 1 0 -1]` | Кут крену `phi` |
| `pitch` | `[1 0 -1 0]` | Кут тангажу `theta` |
| `yaw` | `[-1 1 -1 1]` | Кут рискання `psi` |

Відсутність усталеного значення у відкритому контурі очікувана: у цій частині моделі ще немає регулятора.

## Файли

- `quadrotor_params.m` - параметри з роботи та явно позначене припущення для довжини плеча `l`.
- `quadrotor_core.m` - нелінійні рівняння руху та динаміка двигунів.
- `build_quadrotor_simulink.m` - один раз створює `.slx`-модель зі Step, MATLAB Function, Integrator, Scope і To Workspace блоками.
- `run_simulink_channel.m` - обирає канал, запускає симуляцію та повертає дані.
- `plot_simulink_results.m` - формує чотири графіки для звіту.

Після зміни `quadrotor_params.m` виконайте `build_quadrotor_simulink(false, true)`, щоб оновити числові параметри, вбудовані у блок **Nonlinear plant**.
