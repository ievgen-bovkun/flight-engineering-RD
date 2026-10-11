# DC Motor Coursework Implementation Plan for SOL

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Execute in the SOL session; do not create another chat or delegate unless the user requests it.

**Goal:** Complete the six-part DC motor coursework with three validated MATLAB implementations, independent Python and MATLAB-exported FMU comparisons, a Ukrainian PDF report, submission ZIP, and verified Git push.

**Architecture:** Preserve the buddy's source as reference and adapt its working motor/controller routines into a reproducible project. One versioned parameter/scenario contract drives MATLAB, Simulink, Python and FMU runs; independent equations and analytical checks detect shared mistakes. Generate all report numbers and plots from successful, traceable runs.

**Tech Stack:** MATLAB R2026a Update 4 CLI, Simulink, Control System Toolbox, Simscape, Simscape Electrical, compatible standalone FMU exporter and C compiler; Python with NumPy, SciPy, matplotlib, FMPy, pytest, ReportLab and pypdf.

**Spec:** `docs/superpowers/specs/2026-10-11-dc-motor-coursework.md`. Read it first: it contains the user requirements, reviewed source paths, confirmed defects F1-F6, environment evidence and homework reuse map.

**Progress tracker:** `docs/superpowers/dc-motor-progress.md`. Before execution, set the current focus and active row IDs; after each task, update status, artifact/test evidence and commit SHA. A selected next focus is not an implementation already in progress. Keep required work and optional bonus distinct.

## Global Constraints

- MATLAB CLI only: no MATLAB/Simulink GUI interaction, manual block wiring, PID Tuner or manual Run steps.
- Final PDF, chart labels, captions, explanations and conclusions must be Ukrainian. Code identifiers and third-party block names may remain English.
- Assignment constants: `Ra=2, La=0.5, Kt=Ke=0.1, Jm=0.01, Bm=0.001, JL=0.02`; SI units. `J=Jm+JL=0.03`, `B=Bm=0.001`.
- State order `[i;omega]`; positive external torque opposes rotation. All plant subsystems have inputs `[Vin,TL]` and outputs `[omega,i]` in that order.
- Reference 100 rad/s; report first entry and sustained 2% settling; sustained settling <=2 s is the acceptance gate.
- Keep explicitly labeled design assumptions from the spec: +/-48 V, OS<=5%, steady error<=0.2 rad/s. Do not pass these off as instructor-specified numbers.
- Optimize both IAE and voltage effort. Preserve `integral(abs(Vin))` as a required reported metric; keep squared-voltage studies separate.
- Python implementation and a genuine MATLAB-generated FMU are required, not optional alternatives.
- Original buddy files and previous homework remain unchanged. Do not import all untracked files or change homework 6's branch.
- Code, `.slx`, `.fmu`, machine-readable evidence, report source, PDF, README and ZIP must be versioned and pushed; no silent skipping of required validation.

## Review Focus

1. Missing products/exporter/compiler: clear capability report; final build cannot succeed when Simscape or FMU work is skipped (tasks 1, 6, 7, 9).
2. Hidden workspace state and mismatched controller filters: clean-session model runs match the ODE for the same scenario, including disabled TL (tasks 2, 3).
3. Non-settling, negative/zero reference, nonfinite trajectory and end-of-run disturbance: metrics return explicit status without bogus finite settling or array errors (tasks 3, 5).
4. Cached gains, synthetic/reference figures, or differing solver/input grids: invalidate stale results and compare measured traces on declared common time grids (tasks 4, 7, 8).
5. Windows paths/Cyrillic and publication packaging: quoted CLI commands, embedded Ukrainian fonts, inspectable model diagrams, clean-extraction run and remote artifact verification (tasks 1, 8, 9).

## Project and file responsibilities

Create `coursework/dc_motor/` on `codex/dc-motor-coursework`, using a suitable isolated worktree at implementation time. Base it on current main unless repository instructions say otherwise. Inspect the active worktree attachments and working-tree status first. The review occurred in the primary checkout on main at `4fc465c`; do not assume that state is unchanged.

```text
coursework/dc_motor/
  README.md                          Ukrainian setup, exact commands and results index
  config/parameters.json             Physical parameters, controller conventions, chosen limits
  config/scenarios.json              Inputs, event times, initial states, horizons and grids
  reference/buddy_review.md           Provenance, hashes and disposition of F1-F6
  reference/buddy/src/*.m             Unmodified source snapshot with attribution
  matlab/src/*.m                      Adapted model, simulator, metrics and design routines
  matlab/models/*.slx                 Generated plant and closed-loop models
  matlab/tests/test_*.m               Numerical and integration checks
  matlab/preflight.m                  Product/API/compiler report
  matlab/run_coursework.m             Ordered parts 1-6, results manifest and validation
  matlab/export_coursework_fmu.m      CLI-only standalone FMU export
  python/dc_motor/*.py                Independent SciPy simulation, comparisons and FMU runner
  python/tests/test_*.py              Analytic, cross-language and FMU tests
  requirements.txt                    Pinned tested Python versions
  results/{csv,json,figures}/         Measured trajectories, metrics and generated charts
  results/run_manifest.json           Config/source hashes, versions, seed, statuses
  fmu/{dc_motor_plant,dc_motor_pid}.fmu
  report/report_uk.md                 Editable Ukrainian narrative
  report/build_report.py              Rebuildable PDF assembly from current results
  report/DC_Motor_Coursework_UA.pdf
  scripts/run_all.ps1                 Fail-fast CLI orchestration
  scripts/package_submission.py      ZIP manifest/checksums and packaging
  delivery/DC_Motor_Coursework.zip
```

Keep MATLAB scratch/cache and virtual environments ignored. Root `.gitignore` currently ignores all `*.mat`; choose JSON/CSV for exchange and add only narrowly scoped exceptions if a required MAT result is retained. Do not put the delivery ZIP inside itself.

## CLI convention

Commands below run from the implementation repository root. Create directories before using logfile paths. Use normal user permissions for MATLAB when the sandbox cannot access preferences/licensing; the review verified this path works. Do not change license files or global MATLAB preferences.

```powershell
$matlabExe = 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe'
$project = Join-Path (Get-Location) 'coursework\dc_motor'
& $matlabExe -batch "addpath('coursework/dc_motor/matlab'); preflight" -logfile "$project\results\preflight.log"
if ($LASTEXITCODE -ne 0) { throw 'MATLAB preflight failed' }
```

`run_all.ps1` must check every external process exit code. Paths inside MATLAB functions derive from `mfilename('fullpath')`, not the caller's current directory. `set(groot,'defaultFigureVisible','off')`; use `new_system`, `load_system`, `add_block`, `set_param`, `add_line`, `save_system`, `sim` and programmatic diagram export. Do not require `open_system`.

### Task 1: Preserve provenance and establish a runnable environment

**Files:** project README, both config files, `reference/buddy_review.md`, unmodified reference source, `matlab/preflight.m`, `scripts/run_all.ps1`, `requirements.txt`, project ignore rules.

**Interfaces:** `env=preflight()` returns release, installed/usable products, FMU API availability and selected compiler; `p=motor_params(configPath)` will consume the JSON in task 2. Scenario objects contain `id,reference,voltage,loadTorque,eventTimes,x0,tEnd,outputStep` with signal types and SI units explicit.

- [x] Inspect repository/worktree instructions; create or reuse an isolated `codex/dc-motor-coursework` workspace without altering existing homework worktrees.
- [x] Copy only the buddy's source into `reference/buddy/src`, record SHA256 and original paths, and bring the spec/plan into this branch. Record the missing Python/FMUs and F1-F6 as issues to close. Do not copy reference PNGs into final results.
- [x] Write the exact constants and choices from the spec into config. Record clean-start zero states and controller `beta=1`, derivative-on-measurement `gamma=0`, `Tf=max(Kd/(20*Kp),0.001)`, back-calculation anti-windup.
- [x] Implement and run CLI preflight. Check actual product availability and library loads, `which('exportToFMU')`, supported compiler selection, and a minimal new_system/sim smoke model. Check Python dependencies separately.
- [ ] Resolve required Simscape, Simscape Electrical and FMU export/compiler availability through the supported installation/licensing path. Never claim completion using only ODE substitutes. If unavailable, continue independent tasks and record exactly which required validation remains blocked.
- [ ] Verify the runner reports required missing capabilities as failure, then commit this setup/provenance increment.

**Evidence from this review:** normal-user MATLAB works; Simscape libraries/exportToFMU were unavailable, and `mex.getCompilerConfigurations('C','Selected')` returned empty. Recheck rather than treating this as permanently fixed or permanently impossible.

### Task 2: Validate the motor equations and two Simulink realizations

**Files:** `matlab/src/motor_params.m`, `motor_models.m`, `build_model_diffeq.m`, `build_model_statespace.m`, `run_plant_comparison.m`; `matlab/tests/test_motor_models.m`, `test_model_structure.m`; generated plant SLX and comparison CSV.

**Interfaces:** `m=motor_models(p)` returns `A,Bu,Bd,C,G,Gd` using state `[i;omega]`; `[mdl,path]=build_model_diffeq(p,modelDir)` and `build_model_statespace(p,modelDir)` produce interchangeable plant subsystems with two input and two output ports; `r=run_plant_comparison(p,scenario)` returns normalized traces and errors.

- [x] Write failing model tests with anchors `den=[0.015,0.0605,0.012]`, `dcgain(G)=25/3`, `dcgain(Gd)=-500/3`, the spec's exact A/B matrices, and both 12 V/zero-load and 13 V/0.05 N m equilibria. Test zero input and torque sign.
- [x] Adapt the buddy's correct equations; validate positive physical parameters and recompute J/B from primitive constants. Use analytical transfer-function coefficients and equilibrium as independent checks, not another call to the same implementation.
- [x] Adapt both builders so model parameters are saved in model workspace or a versioned data dictionary. Use `Simulink.SimulationInput` for scenario changes; eliminate `push_params` overwrites. State-space output matrix is `[0 1;1 0]` to expose omega and current. Load/run saved models in a fresh batch session.
- [x] Run zero-input, 12 V step at t=0, 12 V with load step at t=1, and nonzero initial-state cases. Align discontinuities exactly. Request solver outputs at the comparison grid instead of extrapolating beyond coverage. Start with ODE `RelTol=1e-8`, `AbsTol=1e-10`, output step 1 ms.
- [x] Assert same-grid maximum error <=1e-4 rad/s for speed and <=1e-5 A for current between ODE and the two Simulink implementations. Halve maximum integration step when investigating a failure; do not silently loosen gates. Confirm equations obey the load sign and zero equilibrium.
- [x] Export trajectories, parameter manifest and actual model diagrams; commit passing models/tests.

**Run:** `matlab -batch "addpath(genpath('coursework/dc_motor/matlab')); assertSuccess(runtests('coursework/dc_motor/matlab/tests/test_motor_models.m')); assertSuccess(runtests('coursework/dc_motor/matlab/tests/test_model_structure.m'));"` using the full executable path above. Expected: all tests passed, no skipped required test.

### Task 3: Make PID implementation and metrics consistent

**Files:** adapted `simulate_closed_loop.m`, `pid_output.m`, `build_model_pid.m`, `performance_metrics.m`, `tune_ziegler_nichols.m`, `tune_pole_placement.m`, `check_feasibility.m`; `test_pid_equivalence.m`, `test_metrics.m`.

**Interfaces:** `out=simulate_closed_loop(p,K,opt)` returns `t,i,w,u,e,TL,opt,Tf,Tt`; `M=performance_metrics(out)` returns `t_first,ts,os,ess,iae,itae,effort,effort2,energy_net,copper_loss,settled,status,horizon`. `ess` is an equilibrium-validated tail estimate; also expose endpoint error. `build_model_pid(p,K,kind,scenario,modelDir)` returns a model with the same controller law.

- [ ] Write regressions for F2: setting TL=0 remains zero after build, and the Simulink filtered derivative equals `Kd*s/(Tf*s+1)` by using block `N=1/Tf`. Cover ideal/no-saturation and saturated cases separately.
- [ ] Write metrics fixtures: a response that enters, exits and later settles; a never-settling response; an end-of-run excursion; a zero/negative reference with documented absolute-band handling; NaN/Inf trajectories; constant-voltage integration. Nonfinite data must fail clearly, and a trace outside the band at its end must return `ts=Inf`.
- [ ] Standardize `effort2` and remove all `M.eff2/M0.eff2/Mo.eff2/Mk.eff2` consumers. Benchmark structures may have a different schema only if deliberately mapped. Preserve required `effort=trapz(t,abs(u))` and IAE.
- [ ] Port the Ziegler-Nichols reaction-curve and pole-placement baselines. Explain why ultimate-gain ZN is unsuitable for this particular stable second-order delay-free plant. Label ideal pole placement as nominal; the derivative filter adds a state and saturation changes the actual response.
- [ ] Validate the supplied `[11.0456,21.89,1.3288]` gains as a **buddy baseline**, not newly optimized output. Reproduce approximately `ts=1.717 s, OS=0.137%, IAE=90.088 rad` over 5 s. No tolerance is to be derived solely from rounded report numbers.
- [ ] Assert ODE versus both closed-loop Simulink models within `1e-4 rad/s` speed and `1e-3 V` voltage on a common grid, with a solver refinement check. Compare current too, using `1e-5 A`. Disable TL with zero amplitude/finite time; never set a Step time to Inf.
- [ ] Compute 24/48 V feasibility and distinguish first reach of 100 from settling in 98-102 rad/s. Save measured baseline metrics and commit.

**Run:** MATLAB `assertSuccess(runtests(.../test_pid_equivalence.m))` and `test_metrics.m`; runner must return nonzero if either fails.

### Task 4: Reproduce optimization and generate fair comparisons

**Files:** `pid_cost.m`, `optimize_pid.m`, `ga_simple.m`, `run_optimization.m`, `test_optimization.m`; `results/json/optimization.json`, `results/csv/controller_metrics.csv`, Pareto/sensitivity data.

**Interfaces:** `[cost,M]=pid_cost(K,p,cfg)` has explicit fields `lambda,IAE_ref,effort_ref,penalty,simopt`; `R=optimize_pid(p,cfg,starts)` returns gains, score, feasibility, seed, evaluations, convergence history and independent final validation. Alternate squared-voltage objective uses a different named configuration.

- [ ] Write a regression that calls the real objective with finite positive gains and verifies a finite score using the documented metric schema. Reject nonfinite gains/data. Verify the primary objective changes when either IAE or absolute-voltage effort changes; do not catch coding errors as infeasibility.
- [ ] Implement the normalized two-objective cost with declared engineering feasibility penalties. Use a fixed common horizon. Run multistart `fminsearch` and the existing seeded GA (seed 7); bound gains to a documented domain for both methods. Do not require Global Optimization Toolbox.
- [ ] Run a small optimizer smoke case before the full search. Save full configs and source hashes, not just hard-coded optimal gains. A stale or missing result must trigger regeneration or an explicit error in final mode.
- [ ] Run the full search and a lambda sweep. Re-evaluate candidates with tight ode45 and Simulink using the same controller, then filter feasible/nondominated points before drawing a Pareto plot. Label it an empirical frontier.
- [ ] Require selected gains to satisfy sustained settling <=2 s, chosen OS<=5% and steady error<=0.2 rad/s; report tradeoffs if voltage effort and IAE do not both improve. Do not manufacture a claim of dominance.
- [ ] Keep gain sensitivity separate from motor-parameter sensitivity: test gains at 0.8/1/1.2, and separately perturb Ra/JL/Bm by +/-20% with gains fixed. Report failures as results rather than concealing them.
- [ ] If retaining the bang-bang benchmark, align switching events exactly and call it a benchmark for terminal-state transfer. Remove universal claims about minimal IAE or 2% settling unless independently established. Correct the signed-integral identity and energy units in all narrative.
- [ ] Export data/plots and commit after objective/optimizer tests and final cross-checks pass.

### Task 5: Disturbance rejection and CLI-driven live visualization

**Files:** `design_observer.m`, `run_disturbance_study.m`, `live_visualization.m`, `test_disturbance.m`; disturbance CSV and evolving preview assets.

**Interfaces:** `R=run_disturbance_study(p,K)` returns clean/PID/observer paired traces and recovery metrics. `live_visualization(p,K,opt)` consumes the exact same RHS/controller, with `opt.realTime=false` by default.

- [ ] Write tests for TL=0.05 at t=1, a larger post-settling load, and a load that does not recover by the end of the run. Recovery must return Inf/status instead of indexing past the final sample (F6).
- [ ] Run required disturbance using the selected optimized gains; compare with the no-load run. Validate sustained speed criteria and the loaded equilibrium `i=1.5 A, V=13 V`. Split integration at the load discontinuity.
- [ ] Retain the optional augmented-state observer only with observability rank 3, stable error poles and correctly signed feedforward. Compare it to PID alone at t=1 and t=3; explicitly report when saturation prevents benefit.
- [ ] Implement live updates through an ODE OutputFcn/shared simulation loop launched from CLI. Automated runs update a hidden plot and write speed/voltage preview PNG plus progress data during integration. A separate CLI demo flag may show the updating figure automatically with real-time pacing; it must need no clicks, menus or MATLAB desktop interaction. Keep visibility and pacing off for automated validation. Also produce a recorded animation if useful for submission.
- [ ] Verify more than one preview update occurs before completion and its terminal state matches the nonvisual run within solver tolerance. Save the actual required-scenario plots and commit.

### Task 6: Complete physical Simscape and lag/lead comparisons

**Files:** `build_model_simscape.m`, `build_compensated_model.m`, `design_compensator.m`, `simulate_compensator.m`, `run_simscape_comparison.m`; `test_simscape.m`, `test_compensators.m`; generated physical/open/closed-loop SLX and figures.

**Interfaces:** physical `Motor Model Subsystem` implements task 2's exact ports and units. `build_compensated_model(p,controller,scenario,modelDir)` wraps this plant with the chosen PID or `C(s)=Kc*(s+z)/(s+p)` and the same declared voltage limits.

- [ ] Confirm physical libraries load and can compile a minimal physical network. If missing, mark this required task blocked; do not replace it with a transfer-function block named Simscape.
- [ ] Inspect actual R2026a library paths, DialogParameters/MaskNames and port handles. Configure DC Motor Jm/Bm internally, external inertia JL only, current and rotational speed sensors, controlled voltage and opposing torque sources, references and solver. Set converter units explicitly to V, N m, rad/s and A. Use supported physical-port handles/connections and validate each parameter; remove manual assembly fallback.
- [ ] Compile and simulate open-loop zero-input, 12 V step, and opposing-load cases; assert Simscape/ODE speed error <=1e-3 rad/s and current error <=1e-4 A. Refine solver tolerances to diagnose discrepancies. Save actual physical model diagram and comparison CSV.
- [ ] Design lag and lead for the assignment plant; do not copy CTMS's numerical gains for a different plant. Validate `p>0,z>0,Kc>0`, lag `z>p`, lead `z<p`, stable nominal closed-loop poles and predicted DC error.
- [ ] Run PID, lag and lead **on the Simscape plant** and the reference ODE for 12 s with identical scenarios, initial states and voltage limits. Implement the same compensator anti-windup law in both. Compare trace errors at the open-loop physical tolerances, allowing `1e-3 V` for controller voltage after a convergence study.
- [ ] Measure settling, OS, steady error, IAE and voltage effort for all three. Explain observed tradeoffs even if lead does not spend more effort for this particular tuning. A large loop gain alone is not evidence of higher realized effort under saturation.
- [ ] Add tests proving missing blocks, failed parameter configuration and comparison error above threshold cause a failed task; `simscape_ok` must depend on measured acceptance. Export SLX/figures and commit.

### Task 7: Implement independent Python and real MATLAB FMU exchange

**Files:** `python/dc_motor/{model,controller,metrics,run_comparison,run_fmu}.py`, Python tests, `matlab/export_coursework_fmu.m`, two export harness SLX files, two generated FMUs, cross-platform CSV.

**Interfaces:** Python `simulate(config,scenario,gains)` returns the same named arrays as MATLAB. `run_fmu(fmu_path,scenario)` reads metadata rather than assuming value references. Plant FMU has scalar inputs `Vin,TL`, outputs `omega,i`. Closed-loop FMU has inputs `omega_ref,TL`, outputs `omega,i,Vin`, fixed final gains and documented zero initial states.

- [ ] Write independent Python analytical tests for the transfer-function constants, equilibria, load sign, PID filter/anti-windup and metric edge cases. Implement the ODE directly from the equations using `scipy.integrate.solve_ivp`; do not replay MATLAB output as a simulation.
- [ ] Compare Python and MATLAB plant/PID traces for all required scenarios on identical grids with event-aligned integration. Require max speed error <=1e-3 rad/s, current <=1e-4 A, voltage <=1e-2 V, settling difference <=2 ms; diagnose rather than conceal discrepancies.
- [ ] Confirm a licensed compatible standalone exporter and compiler, using local R2026a help. First export a trivial supported model and run it in Python. A tool-coupling FMU that requires a running MATLAB session is not the selected standalone delivery path.
- [ ] Build clean export harnesses from the validated equation/state-space plant and matched controller, with root scalar ports, embedded parameters and no plotting/file I/O/observer callbacks. Use fixed-step ode4 initially at 1e-4 s. Export through `exportToFMU(model,'FMIVersion','2.0','FMUType','CS')` and supported no-UI options. The assignment does not require exporting the physical Simscape network itself.
- [ ] Check FMU ZIP integrity, `modelDescription.xml`, FMI 2.0 CoSimulation declaration, units/causality, named I/O and executable win64 binary. Inspect generation-tool metadata and record SHA256. Test both exports with FMPy in a Python process with MATLAB closed.
- [ ] Use FMPy on open-loop and closed-loop scenarios, including TL at t=1. Define input zero-order holds and event-side semantics explicitly, align all events to communication steps, and compare FMPy results to both MATLAB and independent Python. Use initial communication step 1 ms and a 0.5 ms refinement; no interpolation across a discontinuity.
- [ ] Apply the cross-platform tolerances above; if communication error exceeds them, refine and document the accepted interval. Validate a fresh FMU instance per scenario. Save comparison error tables/plots and commit source plus actual FMUs.

**Run:** `python -m pytest coursework/dc_motor/python/tests -q` with the project's pinned environment, then the CLI FMU comparison runner. Expected: no skipped required Python/FMU checks and all comparison gates passed.

### Task 8: Build and visually verify the Ukrainian PDF

**Files:** `report/report_uk.md`, `report/build_report.py`, `report/DC_Motor_Coursework_UA.pdf`, generated result charts and diagrams, `results/run_manifest.json`.

**Interfaces:** report builder consumes only the successful run manifest, recorded configuration, CSV/JSON metrics and generated figure paths. It must reject stale/missing/failed required results. Report generation may use Python; the motor calculations remain MATLAB and independent Python as required.

- [ ] Finish `matlab/run_coursework.m` as a single deterministic orchestration entrypoint for parts 1-6 and MATLAB tests; emit config/source hashes and per-section completion statuses. Close models/figures and clear temporary paths on exit.
- [ ] Create the Ukrainian narrative: постановка задачі; припущення; виведення; три моделі; ПІД; оптимізація; оцінка; збурення; Simscape/lag/lead; Python і FMU; відтворення; висновки; джерела. Attribute reused buddy code and CTMS guidance, distinguishing new measured results.
- [ ] Use existing homework 4/5 ReportLab builders as a starting pattern, adapting paths and removing stale hard-coded numbers. Use embedded Cyrillic-capable fonts, A4 pages, readable equations, numbered figures/tables, units and real model diagrams. No unfilled table-of-contents fields or manual F9 instructions.
- [ ] Populate every performance table from machine-readable outputs. Include solver/version/seed/horizon, all numerical discrepancies, failed baseline specifications, actuator assumptions and actual optimization tradeoffs. Avoid claiming that every method meets the specification.
- [ ] Build PDF via CLI. Render every page with Poppler, inspect full-size pages, fix clipping/overflow/missing glyphs and rebuild. Extract PDF text to confirm Ukrainian text, citations, expected section coverage and current numbers. Do not substitute DOCX for requested PDF.
- [ ] Confirm all required source/SLX/FMU/CSV/PDF paths exist and that the report's success claims match the manifest; commit source and final PDF.

### Task 9: Package, verify from a clean copy and push to Git

**Files:** `scripts/package_submission.py`, `scripts/run_all.ps1`, final README, `delivery/DC_Motor_Coursework.zip`, submission checksums, narrowly scoped root README change linking coursework.

**Interfaces:** `run_all.ps1` runs preflight, MATLAB computation/tests, FMU export, Python/FMU checks, report generation and package validation; `package_submission.py` creates a deterministic manifest with hashes and an allowlisted archive excluding caches, reference-only screenshots, venv, secrets and the delivery directory itself.

- [ ] Document exact setup and commands for MATLAB, Python/FMPy, PDF regeneration and full run. State the MATLAB release, required products/compiler and FMU platform compatibility. Include a fast verification path using shipped outputs plus full regeneration instructions.
- [ ] Run the full pipeline and record its exit code, check counts and acceptance metrics. Missing Simscape or exporter cannot be converted to a passing skipped test. Finish independent parts if a prerequisite remains unavailable, but clearly mark the submission incomplete.
- [ ] Build the ZIP with code, config, MATLAB models, Python modules/tests, real FMUs, results, Ukrainian PDF, report generator, README and checksums. Verify it excludes itself and scratch folders.
- [ ] Extract to a fresh path, verify every hash, run the documented verification and regenerate the report there. Validate no dependency on the Downloads source, Obsidian vault, prior base workspace or an ignored MAT cache. Run the full pipeline from clean source before declaring reproducibility.
- [ ] Render the final extracted PDF and inspect it; check ZIP CRC/inventory and all model/FMU filenames. Ensure no handwritten metrics have diverged from the run manifest.
- [ ] Review the final diff and required source list. Stage only this project's files and the explicit README/spec/plan updates. Use `git check-ignore -v` to detect accidentally excluded deliverables and `git diff --cached --check` to validate the staged change.
- [ ] Commit and push to `origin codex/dc-motor-coursework` using ordinary push, never force push. The user's request already authorizes delivery of the code and PDF to Git. Do not merge existing homework branches as part of delivery.
- [ ] Verify remote SHA with `git ls-remote origin refs/heads/codex/dc-motor-coursework`, compare with local HEAD, and inspect committed paths for all `.m`, `.py`, `.slx`, `.fmu`, report source, PDF and ZIP. Observe host file-size limits; use the repository's supported artifact/LFS strategy if needed, preserving downloadable deliverables.
- [ ] Return the branch/commit link, PDF link, ZIP link, final test counts, main performance metrics and any remaining limitations. Never report push success without a matching remote commit. If a PR is created, attach it to this chat using the app tool.

## Completion gate and handoff prompt

The work is complete only when every required row in the spec's coverage table has real evidence, all three MATLAB implementations and Python/FMU comparisons pass, the Ukrainian PDF has been visually verified, the ZIP works from a clean extraction, and all code/PDF/deliverables are confirmed on the remote branch.

Paste into SOL to start implementation:

> Implement `docs/superpowers/plans/2026-10-11-dc-motor-coursework-sol.md` using its companion specification. Work through the nine tasks using MATLAB CLI only. Reuse the reviewed buddy project without modifying the original Downloads files. Fix confirmed defects before trusting existing figures. Include independent Python and genuine MATLAB FMU export/comparison. Produce a fully Ukrainian PDF, README and submission ZIP, then push all source, models, FMUs, results and PDF to the repository. Verify products/compiler first: the prior review found Simscape/Simscape Electrical and exportToFMU unavailable. Continue independent work if those dependencies block physical/FMU tests and state the remaining requirement precisely; do not declare a partial implementation complete.