# Homework 2 Task 1 and Task 2 Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add nonlinear and Control System Toolbox validation for the inverted pendulum and a clearer unified NED rotation visualization.

**Architecture:** The existing analytical, RK4, and Simulink paths remain unchanged. New focused MATLAB helpers provide nonlinear `ode45` and Toolbox `ss`/`impulse` responses. The NED renderer reuses current rotation matrices, drawing all coordinate frames in one 3D axes.

**Tech Stack:** MATLAB R2026a, Simulink, Control System Toolbox.

## Global Constraints

- Keep `run_homework2` as the one-command entry point.
- Do not change physical parameters in `pendulum_params.m`.
- Use `ss`, `impulse`, and `ode45` only for validation and visualization.
- Preserve current NED matrix tests.

---

### Task 1: Nonlinear pendulum comparison

**Files:**
- Create: `homework2/inverted_pendulum/pendulum_nonlinear_solution.m`
- Create: `homework2/inverted_pendulum/tests/test_pendulum_nonlinear_solution.m`
- Modify: `homework2/inverted_pendulum/generate_task1_results.m`

**Interfaces:**
- Produces `response.time` and `response.state`, where state columns are `[x xDot phi phiDot]`.

- [ ] Write a failing test that requires `response.state` to have `numel(time)` rows and match the supplied initial state in the first row.
- [ ] Run `runtests('homework2/inverted_pendulum/tests/test_pendulum_nonlinear_solution.m')` and confirm it fails before the helper exists.
- [ ] Implement the two nonlinear equations with a 2-by-2 mass matrix, then integrate them with `ode45` on the supplied time grid.
- [ ] Extend the result generator with a free-response comparison beginning at `phi=0.05 rad`; export `assets/task1_linear_vs_nonlinear.png`.
- [ ] Re-run the test and commit this task.

### Task 2: Control System Toolbox impulse validation

**Files:**
- Create: `homework2/inverted_pendulum/pendulum_impulse_response.m`
- Create: `homework2/inverted_pendulum/tests/test_pendulum_impulse_response.m`
- Modify: `homework2/inverted_pendulum/generate_task1_results.m`

**Interfaces:**
- Produces `response.time`, `response.output`, and `response.maxErrorVsAnalytic`.

- [ ] Write a failing test that requires the impulse output to have two columns and agree with `expm(A*t)*B` within `1e-8`.
- [ ] Run `runtests('homework2/inverted_pendulum/tests/test_pendulum_impulse_response.m')` and confirm it fails before the helper exists.
- [ ] Implement `system = ss(P.A, P.B, P.C, P.D); [output,time] = impulse(system,time);` and compare it to the analytical impulse response.
- [ ] Extend the result generator and export `assets/task1_impulse_validation.png`.
- [ ] Re-run the test and commit this task.

### Task 3: Unified NED visualization

**Files:**
- Modify: `homework2/ned_rotations/plot_ned_rotations.m`
- Modify: `homework2/ned_rotations/generate_ned_figure.m`
- Modify: `homework2/report/Task2_NED_Rotations.md`

- [ ] Render initial NED, after-yaw, after-pitch, and final body frames in one axes with separate colors.
- [ ] Add angle arcs and `psi`, `theta`, `phi` labels, stating the `Z-Y-X` order in the plot title and Markdown report.
- [ ] Export `assets/ned_yaw_pitch_roll_sequence.png` and run `runtests('homework2/ned_rotations/tests/test_ned_rotation_matrices.m')`.
- [ ] Commit this task.

### Task 4: Documentation and full validation

**Files:**
- Modify: `homework2/report/Task1_Inverted_Pendulum.md`
- Modify: `homework2/report/Task2_NED_Rotations.md`
- Modify: `homework2/run_homework2.m`

- [ ] Add concise descriptions and captions for the new validation figures.
- [ ] Make `run_homework2` generate both Task 1 validation figures.
- [ ] Run `run_homework2`, `run_task2_ned_rotations`, and all pendulum and NED tests in MATLAB batch mode.
- [ ] Commit the complete implementation.
