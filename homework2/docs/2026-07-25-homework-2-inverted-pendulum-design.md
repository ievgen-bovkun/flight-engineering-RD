# Homework 2: Inverted Pendulum Design

## Objective

Create a reproducible MATLAB/Simulink project for Homework 2 in the same repository that contains Homework 1. The work covers an inverted pendulum on a cart, NED rotation visualization, and a symbolic derivation limited to the inverted pendulum equations.

## Scope

### Task 1: Inverted pendulum

- Use the cart-pendulum parameters and linearized equations (10), (11) from the [CTMS system-modeling tutorial](https://ctms.engin.umich.edu/CTMS/index.php?example=InvertedPendulum&section=SystemModeling).
- Use the CTMS parameter set: `M=0.5 kg`, `m=0.2 kg`, `b=0.1 N s/m`, `I=0.006 kg m^2`, `l=0.3 m`, `g=9.8 m/s^2`.
- Build the linear state-space model with state vector `X=[x; x_dot; phi; phi_dot]` and input cart force `F`.
- Express the analytical state solution as `X(t)=exp(A t)X(0)+integral_0^t exp(A(t-tau))B F(tau) d tau`.
- Plot cart position `x(t)` and pendulum angle `phi(t)` for a documented test force.
- Implement a Simulink model with the same state-space matrices and compare its outputs with MATLAB `lsim`.

### Task 2: NED rotations

- Plot the sequence of aerospace 3-2-1 rotations in the NED frame: roll `phi`, pitch `theta`, yaw `psi`.
- Show the original NED axes and all three successive body-axis orientations in one figure.
- State the selected convention explicitly: right-handed NED (`x=North`, `y=East`, `z=Down`) and `R=Rz(psi)*Ry(theta)*Rx(phi)`.

### Task 3: Symbolic derivation for the inverted pendulum only

- Define the nonlinear cart-pendulum equations symbolically.
- Use MATLAB Symbolic Math Toolbox `solve` to obtain `x_ddot` and `phi_ddot`.
- Apply `sin(phi) approximately phi`, `cos(phi) approximately 1` around the upright equilibrium.
- Compare the resulting linear expressions and state-space coefficients with the CTMS model.

## Model

The nonlinear equations used as the symbolic starting point are:

```text
(M+m)x_ddot + b*x_dot + m*l*phi_ddot*cos(phi) - m*l*phi_dot^2*sin(phi) = F
(I+m*l^2)phi_ddot + m*l*x_ddot*cos(phi) - m*g*l*sin(phi) = 0
```

After linearization, with `p=I(M+m)+M*m*l^2`, the state matrices are:

```text
A = [0, 1, 0, 0;
     0, -(I+m*l^2)*b/p, -(m^2*g*l^2)/p, 0;
     0, 0, 0, 1;
     0, -(m*l*b)/p, m*g*l*(M+m)/p, 0]

B = [0;
     (I+m*l^2)/p;
     0;
     m*l/p]

C = [1, 0, 0, 0;
     0, 0, 1, 0]

D = [0; 0]
```

The open-loop upright pendulum is unstable. Growth of `phi` after a force disturbance is an expected physical result, not a model defect.

## Repository Layout

```text
homework2/
  Task2_Initial_Notes.md
  inverted_pendulum/
    pendulum_params.m
    pendulum_state_space.m
    pendulum_analytic_solution.m
    build_pendulum_simulink.m
    run_pendulum_comparison.m
    inverted_pendulum_linear.slx
  ned_rotations/
    plot_ned_rotations.m
  symbolic_pendulum/
    derive_pendulum_symbolic.m
  report/
    assets/
    Task2_Report.md
```

## Validation

1. Verify dimensions and values of `A`, `B`, `C`, `D` against the symbolic linearized equations.
2. Run the same force input through `lsim` and Simulink; compare time samples of `x` and `phi` within numerical tolerance.
3. Confirm that `F=0` and zero initial state produce zero outputs.
4. Confirm that the NED rotation matrices remain orthonormal and preserve vector lengths.
5. Save plots and a Simulink diagram for the final PDF report.

## Sources

- [CTMS: Inverted Pendulum - System Modeling](https://ctms.engin.umich.edu/CTMS/index.php?example=InvertedPendulum&section=SystemModeling)
- [CTMS: Inverted Pendulum - Simulink Modeling](https://ctms.engin.umich.edu/CTMS/index.php/Content/Animations/Content/Activities/Content/Extras/InvertedPendulum/Simulink/Modeling/Basics/?example=InvertedPendulum&section=SimulinkModeling)
- [Cureus: Modeling and Balancing Control of Inverted Pendulum](https://www.cureusjournals.com/articles/8517-modeling-and-balancing-control-of-inverted-pendulum)
- [YouTube supplementary video](https://www.youtube.com/watch?v=fi54Hz5TiWI&t=252s)
- `Конспект заняття 5.pdf`, supplied by the team.
