# Homework 2 Inverted Pendulum Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and validate a MATLAB/Simulink homework project for the CTMS inverted pendulum, NED rotations, and symbolic pendulum equations.

**Architecture:** A single parameter source supplies the CTMS constants and the linear state-space matrices. MATLAB scripts generate analytical/`lsim` results and NED graphics. A build script creates a self-contained Simulink model from the same matrices, while MATLAB unit tests verify numerical consistency.

**Tech Stack:** MATLAB R2026a, Simulink, Symbolic Math Toolbox, MATLAB Unit Test Framework.

## Global Constraints

- Use CTMS constants `M=0.5`, `m=0.2`, `b=0.1`, `I=0.006`, `l=0.3`, `g=9.8` in SI units.
- Use upright deviation `phi=0` and state order `[x; x_dot; phi; phi_dot]`.
- Treat open-loop divergence as expected physical behavior.
- Keep every graph, model, and report source under `homework2/`.

---

### Task 1: Linear model and MATLAB reference response

**Files:**
- Create: `homework2/inverted_pendulum/pendulum_params.m`
- Create: `homework2/inverted_pendulum/pendulum_state_space.m`
- Create: `homework2/inverted_pendulum/pendulum_analytic_solution.m`
- Create: `homework2/inverted_pendulum/run_pendulum_comparison.m`
- Test: `homework2/inverted_pendulum/tests/test_pendulum_state_space.m`

**Interfaces:**
- Produces: `P = pendulum_params()` with scalar fields `M,m,b,I,l,g,p,A,B,C,D`.
- Produces: `[sys,P] = pendulum_state_space()` as a continuous-time `ss` model.
- Produces: `result = pendulum_analytic_solution(t,F,x0,P)` with fields `time,state,cartPosition,pendulumAngle`.

- [ ] **Step 1: Write the failing state-space test**

```matlab
function tests = test_pendulum_state_space
tests = functiontests(localfunctions);
end

function testZeroInputEquilibrium(testCase)
[sys, P] = pendulum_state_space();
y = lsim(sys, zeros(11,1), linspace(0,1,11), zeros(4,1));
verifyEqual(testCase, y, zeros(11,2), 'AbsTol', 1e-12);
verifyEqual(testCase, size(P.A), [4 4]);
end
```

- [ ] **Step 2: Run the test and confirm it fails because `pendulum_state_space` is absent.**

```matlab
results = runtests('tests/test_pendulum_state_space.m');
```

- [ ] **Step 3: Implement the parameter and state-space functions.**

```matlab
P.p = P.I*(P.M + P.m) + P.M*P.m*P.l^2;
P.A = [0 1 0 0; 0 -(P.I+P.m*P.l^2)*P.b/P.p -(P.m^2*P.g*P.l^2)/P.p 0; ...
       0 0 0 1; 0 -(P.m*P.l*P.b)/P.p P.m*P.g*P.l*(P.M+P.m)/P.p 0];
P.B = [0; (P.I+P.m*P.l^2)/P.p; 0; P.m*P.l/P.p];
```

- [ ] **Step 4: Implement the state-transition response and comparison runner.**

Use numerical quadrature of the state-transition integral for arbitrary sampled `F(t)`, and use a unit force step at `t=0.5 s` for the report plots.

- [ ] **Step 5: Run the reference tests and save `assets/pendulum_response.png`.**

```matlab
results = runtests('tests/test_pendulum_state_space.m');
assert(all([results.Passed]));
run_pendulum_comparison;
```

- [ ] **Step 6: Commit the linear MATLAB model.**

### Task 2: Simulink model and MATLAB comparison

**Files:**
- Create: `homework2/inverted_pendulum/build_pendulum_simulink.m`
- Create: `homework2/inverted_pendulum/run_simulink_pendulum.m`
- Create: `homework2/inverted_pendulum/inverted_pendulum_linear.slx`
- Test: `homework2/inverted_pendulum/tests/test_simulink_pendulum.m`

**Interfaces:**
- Consumes: `P = pendulum_params()`.
- Produces: Simulink model `inverted_pendulum_linear` with a Step force input and workspace output `simout`.
- Produces: `comparison` with MATLAB and Simulink response arrays.

- [ ] **Step 1: Write the failing comparison test.**

```matlab
function testSimulinkMatchesLsim(testCase)
comparison = run_simulink_pendulum(false);
verifyLessThan(testCase, max(abs(comparison.simulink(:) - comparison.lsim(:))), 1e-6);
end
```

- [ ] **Step 2: Run the test and confirm it fails because the model does not exist.**

```matlab
results = runtests('tests/test_simulink_pendulum.m');
```

- [ ] **Step 3: Build the model using `Step -> State-Space -> Demux -> Scope / To Workspace`.**

Set `A=P.A`, `B=P.B`, `C=P.C`, `D=P.D`, initial state `[0;0;0;0]`, step time `0.5`, final value `1`, stop time `5`.

- [ ] **Step 4: Implement sampled interpolation and compare the two response arrays.**

Use `interp1` to put `lsim` outputs on the Simulink time base before computing the maximum error.

- [ ] **Step 5: Run the tests and save `assets/simulink_pendulum_model.png`.**

```matlab
results = runtests('tests');
assert(all([results.Passed]));
```

- [ ] **Step 6: Commit the Simulink model and tests.**

### Task 3: NED rotations and symbolic pendulum derivation

**Files:**
- Create: `homework2/ned_rotations/plot_ned_rotations.m`
- Create: `homework2/symbolic_pendulum/derive_pendulum_symbolic.m`
- Test: `homework2/ned_rotations/tests/test_ned_rotations.m`
- Test: `homework2/symbolic_pendulum/tests/test_symbolic_pendulum.m`

**Interfaces:**
- Produces: `R = plot_ned_rotations(phi,theta,psi)` and `assets/ned_rotations.png`.
- Produces: `derivation` with symbolic `xdd`, `phidd`, `xddLinear`, `phiddLinear`.

- [ ] **Step 1: Write the failing NED orthonormality test.**

```matlab
function testRotationIsOrthonormal(testCase)
R = plot_ned_rotations(deg2rad(20), deg2rad(-15), deg2rad(30), false);
verifyEqual(testCase, R.'*R, eye(3), 'AbsTol', 1e-12);
end
```

- [ ] **Step 2: Implement `Rz(psi)*Ry(theta)*Rx(phi)` and save one axes figure.**

Draw NED as dashed axes and three successive body frames in distinct colors with `quiver3`.

- [ ] **Step 3: Write and run the symbolic equivalence test.**

```matlab
derivation = derive_pendulum_symbolic();
verifyEqual(testCase, simplify(derivation.xddLinear - derivation.xddCtms), sym(0));
verifyEqual(testCase, simplify(derivation.phiddLinear - derivation.phiddCtms), sym(0));
```

- [ ] **Step 4: Implement `solve` and small-angle substitution for the two cart-pendulum equations.**

- [ ] **Step 5: Run all tests and commit.**

### Task 4: Report source and delivery checks

**Files:**
- Create: `homework2/report/Task2_Report.md`
- Create: `homework2/README_ua.md`
- Modify: `homework2/Task2_Initial_Notes.md`

**Interfaces:**
- Consumes all generated assets and run instructions.
- Produces a concise Ukrainian report source with source links and Google Drive placeholder.

- [ ] **Step 1: Add equations, analytical solution, validation path, figures, NED convention, and symbolic comparison.**
- [ ] **Step 2: Link the GitHub repository and add an explicit `[посилання на Google Drive]` placeholder for LMS submission.**
- [ ] **Step 3: Run all MATLAB tests and check all referenced image paths.**
- [ ] **Step 4: Commit the report source.**

## Self-Review

- Spec coverage: Tasks 1-4 cover the three assigned tasks, source links, validation, Simulink, and report artifacts.
- Placeholder scan: the only placeholder is the Google Drive URL required only after upload.
- Interface consistency: all tasks consume `pendulum_params`, state order `[x;x_dot;phi;phi_dot]`, and the shared `assets/` folder.
