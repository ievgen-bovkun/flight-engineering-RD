# DC motor coursework — progress and acceptance tracker

**Last reviewed:** 2026-10-11, Europe/Paris.
**Overall state:** implementation started on `codex/dc-motor-coursework`; project setup verified, task T1 still has external prerequisites unresolved.
**Implementation owner:** SOL; executing the approved plan in this chat.
**Current focus:** pause for the user decision on missing physical/FMU dependencies after verified project setup. Next implementation work is T2/T3 motor validation and F1/F2 corrections.
**Next focus:** validated optimization, then physical-model and cross-platform completion.
**Dependency focus:** provision/verify Simscape, Simscape Electrical, standalone FMU exporter and C compiler; these need not stop the core MATLAB/Python work.

This is a manually maintained review table. Update it after actual implementation and verification milestones, not automatically with elapsed time. Do not mark the selected focus “In progress” until execution begins.

## Sources and evidence

- [Authoritative requirements and detailed buddy review](specs/2026-10-11-dc-motor-coursework.md).
- [SOL implementation plan](plans/2026-10-11-dc-motor-coursework-sol.md), tasks T1–T9.
- Buddy source: `C:\Users\ievge\Downloads\Курсовий проект\dc_motor_project\dc_motor_project` (30 MATLAB files, DOCX, 10 reference PNGs; no Python, FMU, generated SLX, PDF or numerical CSV/MAT files in that package).
- MATLAB numerical audit: `../../tmp/motor_buddy_audit/audit.log`; environment evidence: `../../tmp/motor_buddy_audit/environment.log`.
- Current file check: `coursework/dc_motor/` now exists in the app-managed worktree `C:\Users\ievge\.codex\worktrees\dc-motor-coursework\Flight Engineering` on `codex/dc-motor-coursework`; all 30 reference source hashes match originals. No remote coursework push yet.
- Fresh CLI preflight and two regression tests passed in this implementation milestone. Required external capabilities remain unavailable; see `coursework/dc_motor/results/json/environment.json` in the implementation branch.

## Status rules

| Status | Meaning |
|---|---|
| Complete | This row's stated acceptance criterion has supporting evidence. Does not imply the whole project is complete. |
| Partial | Useful code/artifact exists, but required integration, correction or acceptance evidence is missing. |
| Failing | An identified defect or failed check prevents acceptance. |
| Blocked | A required external capability is unavailable in the checked environment. |
| Not started | No implementation/deliverable found for this row. |
| Unverified | A claim or code exists, but the required test/run/publication evidence is absent. |
| In progress | Implementation has actually begun; record its owner and current action. Use this only while the corresponding work is being executed. |

**Scope:** Required = assignment or explicit user request. Bonus = optional assignment work included in the agreed plan. Enabler = implementation/quality prerequisite chosen to make required deliverables reproducible. Observer and robustness studies are enhancements, not extra grading requirements.

## Preparation and execution environment

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| P01 | Required | Requirements and buddy review | Complete | User's full brief captured; code and DOCX technical claims reviewed; defects F1–F6 documented | Keep coverage aligned with any user changes | — |
| P02 | Required | Prior coursework and direct Obsidian review | Partial | Six homework projects inspected; six relevant MD notes read directly; requested overall course note not located | Preserve limitation; user's pasted brief is sufficient to proceed, so this is not an implementation blocker | — |
| P03 | Enabler | SOL implementation plan | Complete | Nine-task plan with file responsibilities and checks exists | Keep plan and this tracker synchronized | — |
| E01 | Required | MATLAB CLI execution | Complete | Normal-user R2026a Update 4 batch audit succeeded; Simulink and Control System Toolbox available | Use CLI throughout; no manual UI dependency | T1 |
| E02 | Enabler | Isolated project, source provenance and shared configuration | Complete | App-managed branch created; physical/scenario JSON, 30-file source snapshot and SHA256 manifest verified | Commit milestone evidence; final source delivery follows T9 | T1 |
| E03 | Required | Simscape and Simscape Electrical available | Blocked | Recorded `ver('simscape')`, `which('fl_lib')`, `which('ee_lib')` empty | Install/license as needed; library load and physical-network compilation pass | T1, T6 |
| E04 | Required | MATLAB standalone FMU export capability | Blocked | Recorded `which('exportToFMU')` empty | Supported exporter available; trivial model exports successfully from CLI | T1, T7 |
| E05 | Enabler | FMU build compiler configured | Blocked | No selected C compiler returned; this does not establish whether a compiler is installed | Configure supported compiler and compile/export smoke model | T1, T7 |
| E06 | Enabler | Python/FMPy and report dependencies reproducible | Not started | No coursework requirements file or verified environment | Pin tested versions; imports and smoke checks pass | T1, T7, T8 |

## Required modeling, control and evaluation

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| M01 | Required · 2.1 | Physical constants, load inertia, governing equations and transfer function | Partial | Buddy equations/parameters reviewed and algebraically consistent; not packaged with automated checks | Verify J=0.03, B=0.001, transfer denominator `[0.015,0.0605,0.012]`, units and load sign in project tests | T2 |
| M02 | Required · 2.1 | Differential-equation Simulink blocks | Partial | Builder exists; generated/ran successfully inside diagnostic copy, not final project | Saved self-contained SLX, clean-session run, measured speed/current validation | T2 |
| M03 | Required · 2.1 | State-space implementation | Partial | Analytical model and builder exist; final independent acceptance not run | Correct A/B and both outputs; generated SLX passes same scenarios as M02 | T2 |
| M04 | Required · 2.1 / 2.6 | Physical Simscape motor and load | Blocked | Candidate builder exists but is unvalidated; physical libraries unavailable | Actual DC Motor + JL, sources/sensors/references/converters/solver; correct units and torque direction | T6 |
| M05 | Required · 2.6 | Reusable Motor Model Subsystem | Partial | Equation subsystem exists; common two-input/two-output contract not consistent across implementations | All three plant versions expose Vin/TL inputs and omega/i outputs with matching units | T2, T6 |
| M06 | Required · 2.1 / 2.6 | Numerical comparison of all three MATLAB models | Blocked | No verified three-way physical comparison; buddy report overstates agreement | Same scenarios/grid/initial conditions; measured error tables and passing tolerance checks including Simscape | T2, T6 |
| C01 | Required · 2.2 | Justified PID tuning method | Partial | ZN reaction-curve and pole-placement routines exist; gains usable | Reproduce chosen method, document ideal versus implemented filtered/saturated controller | T3 |
| C02 | Required · 2.2 | Identical PID behavior in MATLAB and Simulink | Failing | Original speed mismatch 0.843367302 rad/s; filter convention and TL overwrite defects confirmed | Shared Tf/anti-windup law, scenario isolation, automated equivalence checks pass | T3 |
| C03 | Required · 2.2 | 100 rad/s within 2 s; low overshoot and steady error | Partial | Supplied-gain ODE audit: sustained settling 1.717 s, overshoot 0.137%; final multi-model validation missing | Selected controller passes declared gates on validated implementations; report assumptions explicitly | T3, T4 |
| O01 | Required · 2.3 | Executable PID optimizer | Failing | `pid_cost` raises missing `eff2`; actual metric field is `effort2` | Fix schema, objective regression and optimizer smoke/full runs pass | T4 |
| O02 | Required · 2.3 | Joint optimization of IAE and voltage effort | Partial | Buddy optimizes squared voltage and makes overbroad integral claims | Explicit primary IAE/absolute-voltage objective, normalized weights, feasibility constraints and measured tradeoffs | T4 |
| O03 | Required · 2.3 | Reproducible selected gains and before/after comparison | Unverified | Hard-coded supplied gains work; source cannot regenerate claimed optimization | Successful run history, seed/config/source hashes, selected-gain artifact and independent reevaluation | T4 |
| V01 | Required · 2.4 | Speed versus reference and applied-voltage plots | Partial | Reference PNGs and plotting code exist; no final provenance-controlled plots | Regenerate from successful runs; Ukrainian labels, units and reference/band markers | T4, T8 |
| V02 | Required · 2.4 | Settling time, overshoot and static error | Partial | Nominal metrics run; endpoint error treated as static error; edge cases unresolved | Define first-entry/sustained settling and equilibrium-tail error; edge-case tests and output table | T3 |
| V03 | Required · 2.4 | Total voltage effort and IAE | Partial | Audit calculated effort=109.697285 V s, IAE=90.088244 rad over 5 s | Consistent fields, units, horizon and generated metrics for every compared controller | T3, T4 |
| V04 | Required · 2.4 | Quantitative conclusions backed by results | Failing | Unconditional equivalence message and unsupported optimization/energy claims | Fail on exceeded tolerance; regenerate conclusions from valid comparisons; correct claims F4/F5 | T4, T8 |
| L01 | Required · 2.6 | Closed-loop lag compensator versus PID | Partial | Custom ODE compensator code exists; physical closed-loop comparison absent | Lag and PID run on actual Simscape with identical limits, inputs and horizon | T6 |
| L02 | Required · 2.6 | Lead design and lag/lead tradeoff comparison | Partial | Candidate lead and ODE sweep exist; physical comparison unverified | Compare settling, overshoot and realized voltage effort; report observed rather than assumed tradeoffs | T6 |

## Python and FMU requirements

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| X01 | Required | Independent Python motor/control simulation | Not started | No Python implementation in buddy package or final project | Independent SciPy equations, matched controller, analytical tests and scenario runs | T7 |
| X02 | Required | Python versus MATLAB comparison | Not started | No cross-language numerical data | Same event timing, parameters and states; trajectory/metric error tables and plots pass | T7 |
| X03 | Required | Export actual FMU from MATLAB | Blocked | No FMU supplied; exporter unavailable in checked environment | CLI-generated executable FMU, metadata/I/O validation and checksum; plan includes plant and PID exports | T7 |
| X04 | Required | Run FMU in Python and compare to Python model | Blocked | Depends on X03; no FMPy runner/results | FMPy executes real FMU with MATLAB closed; event/step refinement and comparison tolerances pass | T7 |

## Optional bonus and chosen enhancements

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| B01 | Bonus · 2.5 | 0.05 N m disturbance at t=1 s and rejection | Partial | Load/observer routines exist; not accepted as a final scenario | Required load run, speed/voltage metrics, loaded equilibrium and preserved performance | T5 |
| B02 | Bonus · 2.5 | Live speed/voltage visualization | Unverified | `live_visualization.m` exists; runtime behavior not verified | Launch from CLI without interactions; show updates during integration and verify trajectory agreement | T5 |
| B03 | Enhancement | Disturbance observer and recovery edge cases | Partial | Observer code exists; non-recovery indexing defect identified | Observer/sign checks and return Inf/status when recovery never occurs | T5 |
| B04 | Enhancement | Gain/plant sensitivity and optional benchmark | Partial | Existing gain sweep mislabeled as plant robustness; benchmark claims too broad | Separate gain and plant perturbations; bounded, evidence-based conclusions | T4 |

## Documentation, reproducibility and delivery

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| D01 | Required | Readable documented code and README instructions | Partial | Buddy README/comments useful but include manual fallback and unsupported completion claims | Exact end-to-end CLI commands, dependencies, model conventions and results index | T1–T9 |
| D02 | Required | Final report in Ukrainian as PDF | Not started | Ukrainian DOCX exists, but no final PDF or corrected report generator | Ukrainian narrative/tables/captions/plots, source-based values, citations, reproducible PDF build | T8 |
| D03 | Enabler | Report accuracy and visual verification | Not started | Current DOCX technical defects reviewed; final PDF absent | Render/inspect every final page; no clipping or missing Cyrillic; numbers match run manifest | T8 |
| D04 | Enabler | Regression tests and honest failure statuses | Not started | Diagnostic audit exists, not a deliverable test suite | Tests cover F1–F6 and numerical acceptance; missing required capabilities cannot be silent skips | T2–T7 |
| D05 | Enabler | One-command pipeline and clean-copy reproduction | Not started | No final runner; dependencies and cached-gain provenance unresolved | Fail-fast MATLAB/Python/FMU/report pipeline works outside Downloads and previous workspace state | T8, T9 |
| D06 | Required | Submission ZIP: code, results and README | Not started | Buddy folder is source material, not validated final submission | ZIP contains final code/results/README/PDF/models/FMUs; checksums and clean-extraction checks pass | T9 |
| D07 | Required | All code and PDF pushed to Git | Unverified | No local coursework branch/commit; no matching remote delivery verified | Commit allowlisted deliverables, push, verify remote SHA and downloadable code/PDF/ZIP paths | T9 |

## Current focus and review order

| Order | Focus | Status now | Exit condition |
|---|---|---|---|
| 1 | E02: isolated project and shared parameter/scenario contract | Verified milestone | Source snapshot/configuration saved; 30/30 hashes match originals |
| 2 | O01 + C02: optimizer field defect, PID filter and load overwrite | Queued | Regressions fail on original defects and pass on corrected code |
| 3 | M01–M03 + C01–C03 + V02–V03: trusted core model/controller/metrics | Queued | Clean CLI run passes model/controller numerical checks |
| 4 | O02–O03: actual optimization and comparison data | Queued | Reproducible selected gains and honest objective tradeoffs |
| Dependency track | E03–E05: physical modeling and FMU tools | Freshly confirmed blocked; awaiting user decision | Libraries/exporter/compiler smoke tests pass; core work can proceed meanwhile |
| 5 | M04–M06 + L01–L02 + X01–X04 | Queued; physical/FMU portions blocked | Three MATLAB models, Python and FMU all compared successfully |
| 6 | B01–B04, then D01–D07 | Queued | Bonus outcomes recorded; report/ZIP verified; remote delivery confirmed |

No overall completion percentage is shown: these rows have unequal effort, and a functioning borrowed baseline is not the same as a complete, verified submission.

## How SOL should update this table

1. Before working, set the current focus to the relevant IDs and mark only actively worked rows “In progress.” Note owner and action.
2. After each milestone, update affected rows with the exact artifact path, command/result, review date and commit SHA. Preserve failures instead of replacing them with planned outcomes.
3. Mark a row Complete only after its acceptance evidence exists. Source code, a screenshot or a printed success message alone is insufficient for a numerical comparison.
4. Recheck environment blockers when the environment changes. Do not carry an old missing-product result forward as if freshly tested.
5. For each review, report completed-since-last-review IDs, current focus, blockers, and the next acceptance gate. Keep optional bonus separate from required completion.
6. Before final delivery, require every Required row except the nonblocking historical-note limitation P02 to be Complete, plus the reproducibility/QA enablers used by the final pipeline. Record P02's source-location limitation explicitly; never claim the missing original note was reviewed. Required physics/Python/FMU/report/Git rows cannot be waived by calling them optional.

## Review log

| Date | Evidence checked | Outcome / change |
|---|---|---|
| 2026-10-11 | User assignment, spec/plan, local branch/worktree and artifact inventory, buddy source hashes, prior same-day CLI logs | Initial tracker created; source unchanged; no local coursework implementation yet; recorded current focus and prerequisite gaps |

| 2026-10-11 | Setup milestone: managed worktree/branch, 30 source hashes, configuration, MATLAB/Simulink smoke, preflight tests | 2/2 tests PASS after RED; missing required capabilities fail clearly; pause requested for prerequisite decision |
