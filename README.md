# flight-engineering-RD

Практичне завдання з моделювання нелінійної динаміки квадрокоптера за магістерською роботою Томаша Їрінеца.

## Швидкий запуск

1. Відкрийте MATLAB і перейдіть до папки `task1`.
2. Запустіть `run_simulink_demo.m` зеленою кнопкою **Run**.
3. Для окремого каналу у Command Window виконайте, наприклад:
   ```matlab
   cd simulink
   run_simulink_channel('roll')
   ```

Доступні канали: `vertical`, `roll`, `pitch`, `yaw`.

## Вміст

- `simulink/` - нелінійна Simulink-модель, параметри, запуск та тести.
- `report/Task1_Report.md` - звіт українською у Markdown.
- `report/Preview_Sections_2_2_2_3.pdf` - перевірка оформлення формул і таблиці параметрів у PDF.
- `def.m`, `quad_nonlinear.m`, `run_sim.m` - попередня ODE45-реалізація для порівняння.
