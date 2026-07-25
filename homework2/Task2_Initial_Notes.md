# ДЗ 2: первинна записка

**Дисципліна:** Інженерія польоту  
**Виконали:** Dmytro Povolotskyi, Ievgen Bovkun  
**Дата старту:** 25.07.2026

## Що потрібно виконати

1. Побудувати MATLAB/Simulink-модель оберненого маятника на вагончику за CTMS.
2. Отримати аналітичний розв'язок лінеаризованої системи у просторі станів і побудувати `x(t)` та `phi(t)`.
3. Порівняти MATLAB `lsim` з виходами Simulink для одного й того самого тестового входу.
4. Намалювати послідовність поворотів `roll -> pitch -> yaw` у системі NED.
5. Символьно вивести рівняння руху лише для оберненого маятника та звірити їх із CTMS.

## Вихідні параметри CTMS

| Параметр | Значення |
|---|---:|
| Маса вагончика `M` | 0.5 kg |
| Маса маятника `m` | 0.2 kg |
| В'язке тертя `b` | 0.1 N s/m |
| Момент інерції `I` | 0.006 kg m^2 |
| Відстань до центра мас `l` | 0.3 m |
| Гравітація `g` | 9.8 m/s^2 |

## Центральна ідея моделі

Для лінеаризованої системи обирається стан:

```text
X = [x; x_dot; phi; phi_dot]
```

Вхід - горизонтальна сила `F` на вагончик. Виходи - положення вагончика `x` та кут відхилення маятника `phi`. Відкрита система нестійка, тому незатухаюче зростання кута після збурення є очікуваним.

Аналітичний розв'язок у просторі станів:

```text
X(t) = exp(A*t)X(0) + integral_0^t exp(A*(t-tau))*B*F(tau) d tau
```

## Символьна частина

Початкові нелінійні рівняння:

```text
(M+m)x_ddot + b*x_dot + m*l*phi_ddot*cos(phi) - m*l*phi_dot^2*sin(phi) = F
(I+m*l^2)phi_ddot + m*l*x_ddot*cos(phi) - m*g*l*sin(phi) = 0
```

У MATLAB потрібно отримати `x_ddot` і `phi_ddot` через `solve`, після чого виконати лінеаризацію біля `phi=0` (`sin(phi) approximately phi`, `cos(phi) approximately 1`).

## NED-повороти

Використовується NED: `x` - North, `y` - East, `z` - Down. Послідовність поворотів:

```text
R = Rz(psi) * Ry(theta) * Rx(phi)
```

На одному рисунку будуть базова NED-система та три послідовні орієнтації після roll, pitch, yaw.

## Джерела

- [CTMS: System Modeling](https://ctms.engin.umich.edu/CTMS/index.php?example=InvertedPendulum&section=SystemModeling)
- [CTMS: Simulink Modeling](https://ctms.engin.umich.edu/CTMS/index.php/Content/Animations/Content/Activities/Content/Extras/InvertedPendulum/Simulink/Modeling/Basics/?example=InvertedPendulum&section=SimulinkModeling)
- [Cureus: Modeling and Balancing Control of Inverted Pendulum](https://www.cureusjournals.com/articles/8517-modeling-and-balancing-control-of-inverted-pendulum)
- [YouTube: додатковий приклад](https://www.youtube.com/watch?v=fi54Hz5TiWI&t=252s)
- `Конспект заняття 5.pdf`
