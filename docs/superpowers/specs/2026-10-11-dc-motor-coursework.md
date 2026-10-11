# DC motor coursework: authoritative requirements and review

Date: 2026-10-11. Prepared for SOL. This is a review and implementation specification, not a claim that the coursework is complete.

## Authority and scope

The Ukrainian assignment pasted by the user in this chat is authoritative. It requires **all three MATLAB/Simulink implementations, an independent Python simulation, MATLAB FMU export and comparison in Python**, controller design, optimization, metrics, documentation, and a submission ZIP. The closing sentence permitting MATLAB or Python does not remove the explicit cross-platform comparison requirements; implement both. Include the optional disturbance and live-visualization work already attempted by the buddy.

User constraints:

- MATLAB must be operated through CLI, not UI interaction.
- The final report must be in Ukrainian, including captions, legends, tables and conclusions.
- Push all implementation code and the final PDF report to Git.
- Review and reuse the six earlier homeworks where useful.
- Read Obsidian Markdown directly; do not use Obsidian UI.

This turn prepares the review and plan for SOL; it does not implement the coursework or dispatch a new chat.

## Required physical model

| Quantity | Required value |
|---|---:|
| Armature resistance Ra | 2 ohm |
| Armature inductance La | 0.5 H |
| Torque constant Kt | 0.1 N m/A |
| Back EMF constant Ke | 0.1 V/(rad/s) |
| Rotor inertia Jm | 0.01 kg m^2 |
| Rotor damping Bm | 0.001 N m s/rad |
| Load inertia JL | 0.02 kg m^2 |
| Total inertia J | 0.03 kg m^2 |
| Total damping B | 0.001 N m s/rad |
| Speed reference | 100 rad/s |
| Required response time | within 2 seconds |
| Settling band | 2% of reference |
| Bonus load torque | 0.05 N m applied at t=1 s |

Use state order `x=[i;omega]`, inputs `[Vin;TL]`, and a positive TL opposing positive rotation:

```text
La*di/dt = Vin - Ra*i - Ke*omega
J*domega/dt = Kt*i - B*omega - TL
G(s)  = Omega/Vin = 0.1 / (0.015*s^2 + 0.0605*s + 0.012)
Gd(s) = Omega/TL  = -(0.5*s + 2) / (0.015*s^2 + 0.0605*s + 0.012)
A  = [-4, -0.2; 10/3, -1/30]
Bu = [2;0]; Bd = [0;-100/3]
C_omega = [0,1]; D = [0,0]
```

Analytical anchors: voltage-to-speed DC gain `25/3`, unloaded equilibrium at 100 rad/s is `i=1 A, Vin=12 V`; with TL=0.05 N m it is `i=1.5 A, Vin=13 V`. These are coursework values, not CTMS tutorial defaults.

## Requirement-to-deliverable map

| Requirement | Required evidence | Plan task |
|---|---|---:|
| 2.1 equations and transfer function | Derivation, unit checks, independent analytical tests | 2 |
| Three MATLAB implementations | Differential-equation blocks, State-Space, actual physical Simscape subsystem; numerical comparison | 2, 6 |
| 2.2 PID design | At least one justified tuning method, step response and exact implementation details | 3 |
| 2.3 optimization | Reproducible optimization using error and voltage effort; baseline versus optimized results | 4 |
| 2.4 evaluation | Speed/reference and voltage plots; settling, overshoot, static error, voltage effort and IAE | 3, 4, 8 |
| 2.5 disturbance bonus | 0.05 N m at 1 s, compensation evidence and optional observer | 5 |
| 2.5 real-time visualization | Programmatically generated visualization updated during integration, callable from CLI | 5 |
| 2.6 physical subsystem | DC Motor, load inertia, sensors, sources, references, converters and solver; same parameters | 6 |
| 2.6 lag/lead | Closed-loop physical-model simulations and fair PID/lag/lead comparison | 6 |
| Independent Python | SciPy model and controller, comparisons against MATLAB traces | 7 |
| MATLAB-exported FMU | Real .fmu exported from Simulink, executed in Python, matched comparison | 7 |
| Ukrainian report and documentation | Rebuildable PDF with generated figures, metrics, provenance and README | 8 |
| Submission | ZIP with code/results/README plus PDF, models and FMU; Git push verified | 9 |

## Explicit engineering choices, not instructor requirements

1. Retain the buddy's bipolar voltage limit `[-48,+48] V` as a documented assumption. The assignment does not supply a voltage or current limit. Compare 24/48 V feasibility without claiming 48 V is prescribed.
2. Report both first entry into the 2% band and sustained settling (last exit plus next sample); use sustained settling <=2 s as the stronger acceptance criterion.
3. The brief says minimal overshoot and static error without numerical ceilings. Adopt provisional engineering gates `OS<=5%` and `abs(steady error)<=0.2 rad/s`, explicitly labeled as chosen targets. Do not attribute them to the assignment.
4. Primary optimization: normalized `IAE + lambda*integral(abs(Vin))`, lambda sweep and explicit feasibility constraints. Report the requested voltage integral. An additional squared-voltage objective is a sensitivity study, not a silent substitution. `integral(Vin^2)` has units V^2 s; it is not energy in joules. If discussing energy, also compute `integral(Vin*i)` and copper loss `integral(Ra*i^2)` with clear sign conventions.
5. Nominal PID run: 0-5 s. Open-loop: 0-30 s, with analytical DC gain rather than the final sample used as the true equilibrium. PID/lag/lead comparison: all controllers on 0-12 s. Disturbance study: 0-6 s. No cross-horizon effort ranking.
6. Record seed, solver tolerances, controller structure, initial states, output grid and source hash. Fresh results replace the buddy's claimed results only after successful simulation.

## Inputs actually reviewed

Buddy project root:
`C:\Users\ievge\Downloads\Курсовий проект\dc_motor_project\dc_motor_project`

Read both READMEs, all main modeling/controller/optimization/observer/Simscape code, the outer `Пояснювальна_записка.docx` text and tables, and the supplied result inventory; visually inspected `results/part3_optimized.png`. Original source remains unchanged. The DOCX layout was not fully rendered/reviewed; this review concerns its technical claims.

The supplied package has MATLAB source, a DOCX and reference PNGs, but no generated SLX, numerical CSV/MAT evidence, PDF, Python implementation, FMU or automated test suite. `results/README.txt` explicitly describes its PNGs as reference figures to be overwritten on MATLAB execution.

Obsidian: the literal path in the request did not exist. Directly read the available related notes under:
`C:\Users\ievge\iCloudDrive\iCloud~md~obsidian\Hanuman\Flight Engineering`

- `Task 1/Task1_Report.md`, `Task 1/Simulink_README_ua.md`;
- `Task 2/Task2_Initial_Notes.md`, `Task 2/Design_Notes.md`, `Task 2/Implementation_Plan.md`, `Task 2/Inverted_Pendulum_README_ua.md`.

These identify the shared authors and earlier CTMS workflows, but do not contain the current coursework brief. The original overall course note was not located; the user's pasted assignment resolves the requirements gap. Some notes contain obsolete manual Run instructions and obsolete local paths. They are historical context, not execution instructions for SOL.

## Earlier homework review and reuse

Repository: `C:\Users\ievge\Documents\Flight Engineering`
Remote: `https://github.com/ievgen-bovkun/flight-engineering-RD.git`
Main checkout at review: `4fc465c` on `main`; many pre-existing untracked review/temp directories. Do not bulk-stage them.

| Homework | Evidence read/inspected | Reuse decision |
|---|---|---|
| 1 | Quadrotor source/model inventory, shared Ukrainian report/notes, 7-page PDF presence | Programmatic model-builder and reporting pattern; motor dynamics/parameters are different |
| 2 | CTMS state-space/analytic/Simulink comparison sources and test inventory; direct Obsidian notes | Reuse comparison and test pattern; not pendulum equations or UI launchers |
| 3 | `scripts/build_dz3_6dof_model.m`, README, tests, 5-page PDF; saved `TOTAL=10 PASS=10 FAIL=0 INCOMPLETE=0` | Builder, logged-signal comparison and model-structure checks |
| 4 | Buddy's earlier `source_from_colleague/DZ_4_colleague.m`, production scripts/README/CSV, report generator, 5-page PDF | Proven source-preservation and MATLAB/Simulink cross-check pattern; saved max error 4.184e-9, not rerun this turn |
| 5 | Integrator/discretization source/test/CSV inventory, READMEs, report builder, 8-page PDF | RK4 verification/convergence practices and generated CSV-to-PDF approach |
| 6 | Separate `.worktrees/codex-homework6-report/homework6`, README, Python analysis/tests, MATLAB builder, JSON results, 9-page PDF | Python/report organization; keep its pendulum assumptions and branch independent |

Homework 6 exists on `codex/homework6-report` (local HEAD `5469090`, matching remote-tracking ref at review), not in main. Do not merge or rerun all homework as a prerequisite for this course project. Their historical success is useful evidence of workflow, not a fresh certification by this review.

## Buddy review findings

### F1 — P1: optimization cannot run from the supplied source

`performance_metrics.m:66` returns `effort2`, but `pid_cost.m:70` requests `M.eff2`; `part3_optimization.m:55` also requests `M0.eff2` before calling the optimizer. More occurrences exist throughout part 3. Actual CLI execution of `pid_cost([11.0456,21.89,1.3288],p)` produced `MATLAB:nonExistentField: Unrecognized field name "eff2".` Standardize the schema and test the real optimizer entrypoint. Do not mask this programming error with a generic optimization penalty.

### F2 — P1: MATLAB and Simulink use different PID filters and scenarios

The ODE simulator uses `Tf=max(Kd/(20*Kp),0.001)`; `build_model_pid.m:47,96` configures a parallel PID block with `N=20`, corresponding to `Tf=0.05 s`. For the supplied gains, the ODE Tf is `0.006015065 s`, requiring block `N=1/Tf`, about 166.25/s.

`part4_evaluation.m:77-78` disables TL in base workspace, then `build_model_pid` calls `push_params`, restoring `TL=0.05` at `t=1`. Actual copied-source CLI results:

| Comparison | Maximum speed difference |
|---|---:|
| Original Simulink vs nominal ODE | 0.843367302 rad/s |
| Same zero disturbance, original block filter | 0.642684704 rad/s |
| Same zero disturbance and matched filter, diagnostic in-memory change only | 0.000031444 rad/s |

`part4_evaluation.m:95` prints numerical-equivalence success without checking a tolerance. Fix shared controller definitions, use model workspaces/SimulationInput, and enforce assertions. Builders must not change scenario inputs.

### F3 — P1: Python and FMU requirements are absent

No Python source or FMU export/import exists in the supplied project. Add both independent SciPy simulation and genuine MATLAB-exported FMU execution, with common input timing and tolerances. Renaming a ZIP, implementing only a Python FMU, or comparing MATLAB data to itself does not meet this requirement.

### F4 — P1: physical modeling is not proven and can report false success

The package contains no SLX or measured Simscape comparison. The builder guesses block paths, mask parameters and physical port identifiers, catches failures, and points to manual assembly. `part6_simscape.m:71` sets `simscape_ok=true` even when `err>=1e-3`. Part 6 runs lag/lead/PID comparisons using custom ODE code, not closed-loop Simscape models. The final DOCX claims all three models agree and section 2.6 is complete without included supporting run evidence.

Replace guesses with release-specific introspection, configure units and torque sign explicitly, compile and simulate physical models from CLI, and fail the final build when required Simscape checks fail. Verify `Jm+JL` once and `Bm` once.

### F5 — P2: report overstates optimization/physical conclusions

- The integral identity uses **signed** voltage and signed tracking error, terminal states and zero load. In general:
  `integral(V) = La*(i(T)-i(0)) + Ra*J/Kt*(w(T)-w(0)) + (Ra*B/Kt+Ke)*integral(w) + Ra/Kt*integral(TL)`.
  Reducing it to `120.5-0.12*IAE` requires zero initial state, exact final equilibrium, T=5 s, zero load, no overshoot and nonnegative voltage. The project uses negative braking and overshooting responses, so the formula is not universally exact for `integral(abs(V))`.
- A two-switch-time calculation reaching an exact terminal state does not prove a global minimum of IAE or time to enter/stay in a 2% band. Relabel the bang-bang calculation as a benchmark unless separate proofs are supplied. Apply its off-grid switching times exactly before measuring it.
- `part3_optimization.m:110` scales PID gains by +/-20%; it does not perturb motor parameters. Report this as gain sensitivity and add separate plant-parameter sensitivity if discussing physical robustness.
- Lag means pole closer to the origin than zero (`p<z`), not necessarily an absolutely small pole. Restrict conclusions about lag speed to the tested designs; do not claim all lag controllers must fail.
- The table shows optimized overshoot 0.14% vs baseline 0.02%, and effort 109.70 vs 109.66 V s. Avoid an unqualified claim that every metric improves.

### F6 — P2: edge cases and evidence handling

`part5_disturbance.m:81` accesses `r.t(k1+bad)` beyond the array when recovery has not occurred by the last sample; return Inf and an explicit not-recovered status. `performance_metrics` calls the endpoint error a static error without a tail-equilibrium check. In R2026a, the Step block rejected `Time=Inf` during the audit; disable a disturbance with zero amplitude and a finite time or a Constant block. Cached gains have no source/configuration provenance and silently substitute for optimization. A final submission must reject missing/stale result manifests.

## What was confirmed numerically

Isolated copies were exercised through MATLAB R2026a Update 4 CLI. The original gains reproduce `ts=1.717 s`, `OS=0.137008%`, `IAE=90.088244 rad`, `integral(abs(V))=109.697285 V s`, and `integral(V^2)=3771.110711 V^2 s` over 5 s. This supports the usefulness of the supplied controller; it does not prove the optimizer generated it from this source version.

Audit evidence: `tmp/motor_buddy_audit/audit_buddy.m`, `audit.log`, `environment.log`. These are diagnostic scratch files, not final coursework implementation or submission assets.

## Environment constraints for SOL

Verified CLI executable: `C:\Program Files\MATLAB\R2026a\bin\matlab.exe`.
Available products printed by `ver`: MATLAB, Simulink, Control System Toolbox, Aerospace Blockset, Aerospace Toolbox, Symbolic Math Toolbox.

`ver('simscape')`, `which('fl_lib')`, `which('ee_lib')`, and `which('exportToFMU')` returned empty. No selected C MEX compiler was returned. Simscape/Simscape Electrical and standalone FMU export capability must be installed/licensed/configured before declaring the whole project complete. An empty selected-compiler result does not prove no compiler is installed.

Sandbox execution first failed because the normal preferences folder was not writable; a redirected preference folder then produced licensing error -9.2. **The identical normal-permission CLI preflight succeeded.** Do not diagnose the user's license as broken or replace MATLAB with Python because of that sandbox artifact. Use the established normal-user CLI permission path.

## External technical references

- [CTMS motor Simscape reference](https://ctms.engin.umich.edu/CTMS/index.php?example=MotorSpeed&section=SimulinkSimscape): physical model and lag/lead workflow. Its default constants and tutorial gains must not replace assignment values. Direct fetch returned 403; the official-domain indexed content was available for review.
- [MathWorks standalone FMU export](https://www.mathworks.com/help/fmuexport/ug/export-simulink-models-to-functional-mock-up-units.html): product requirement and programmatic export. Current web docs describe R2026b; verify applicable options against local R2026a help.
- [MathWorks exportToFMU](https://www.mathworks.com/help/fmuexport/ref/exporttofmu.html): `exportToFMU(model,'FMIVersion','2.0','FMUType','CS')` and fixed-step configuration.
- [FMPy tutorial](https://fmpy.readthedocs.io/en/latest/tutorial/): Python execution and inspecting FMU metadata.

The brief lists voluntary defense on 24.09 and submission on 1.10 without a year. Preserve that text only as course context; do not invent a new deadline.

## User scope amendment: available trial products (2026-10-11)

The user instructed: "try to workaround and solve task for course work only with products available in trial". Simulink FMU Builder is absent from the trial entitlement. The assignment requires MATLAB FMU export and Python comparison but does not specify standalone execution. Use the documented Simulink tool-coupling exporter with genuine FMI2 CoSimulation FMUs and FMPy, requiring a dedicated local licensed MATLAB/Simulink R2026a session. This amendment supersedes earlier standalone/MATLAB-closed delivery choices; do not bypass licenses or claim autonomous portability. Preserve all original numerical and physical validation gates and Ukrainian reporting.
