# DC motor coursework — progress and acceptance tracker

**Last reviewed:** 2026-10-12, Europe/Paris.
**Overall state:** required modeling, control, optimization, physical Simscape, Python/FMU comparisons and final Ukrainian PDF/ZIP delivery are verified; the remote implementation branch is published.
**Implementation owner:** SOL; executing the approved plan in this chat.
**Current focus:** implementation complete; final remote artifact integrity confirmed.
**Next focus:** submission or presentation using the verified PDF and ZIP; no required implementation work remains.
**Dependency focus:** tool-coupling FMUs require matching licensed local MATLAB/Simulink R2026a; standalone FMU Builder export is unavailable in the trial.

This is a manually maintained review table. Update it after actual implementation and verification milestones, not automatically with elapsed time. Do not mark the selected focus “In progress” until execution begins.

## Sources and evidence

- [Authoritative requirements and detailed buddy review](specs/2026-10-11-dc-motor-coursework.md).
- [SOL implementation plan](plans/2026-10-11-dc-motor-coursework-sol.md), tasks T1–T9.
- Buddy source: `C:\Users\ievge\Downloads\Курсовий проект\dc_motor_project\dc_motor_project` (30 MATLAB files, DOCX, 10 reference PNGs; no Python, FMU, generated SLX, PDF or numerical CSV/MAT files in that package).
- MATLAB numerical audit: `../../tmp/motor_buddy_audit/audit.log`; environment evidence: `../../tmp/motor_buddy_audit/environment.log`.
- Current implementation: `coursework/dc_motor/` in the managed `codex/dc-motor-coursework` worktree. All 30 reference source hashes match originals. Final deliverables published and remote SHA verified at `33fc7e6c11ebe870c8c760c74d713032d706c8c1`.
- Verified milestone evidence: current primary Full computations pass MATLAB 43/43 and Python 27/27; prior clean-copy Full reproduction passed 41/27. Numerical source/config hashes are unchanged; documentation and tested orchestration-order changes explicitly revalidated without repeating the clean-copy calculation. Revised 15-page Ukrainian PDF visually inspected; 210 payload-file ZIP and exact staged report-input hashes verified.

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
| E03 | Required | Simscape and Simscape Electrical available | Complete | Administrator-approved R2026aU4 installation completed; actual physical network compiles and simulates | Preserve version/installation evidence | T1, T6 |
| E04 | Required | MATLAB FMU export capability (trial-only amendment) | Complete | Genuine FMI2 tool-coupling exports pass using available Simulink; standalone FMU Builder entitlement remains absent | Require matching local licensed MATLAB/Simulink; never claim standalone execution | T1, T7 |
| E05 | Enabler | FMU build compiler configured | Complete | Verified official MinGW-w64 GCC 8.1 archive SHA256; C/C++ MEX configured in task-local directory | Actual licensed FMU export remains a separate gate | T1, T7 |
| E06 | Enabler | Python/FMPy and report dependencies reproducible | Complete | Project virtual environment created; tested versions pinned in requirements.txt; SciPy/FMPy/report dependencies installed and Python checks pass | Preserve pinned environment for final pipeline | T1, T7, T8 |

## Required modeling, control and evaluation

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| M01 | Required · 2.1 | Physical constants, load inertia, governing equations and transfer function | Complete | T2: analytical checks, 4 scenario comparisons and saved-model CLI runs passed; generated SLX/CSV/diagrams | Verify J=0.03, B=0.001, transfer denominator `[0.015,0.0605,0.012]`, units and load sign in project tests | T2 |
| M02 | Required · 2.1 | Differential-equation Simulink blocks | Complete | T2: analytical checks, 4 scenario comparisons and saved-model CLI runs passed; generated SLX/CSV/diagrams | Saved self-contained SLX, clean-session run, measured speed/current validation | T2 |
| M03 | Required · 2.1 | State-space implementation | Complete | T2: analytical checks, 4 scenario comparisons and saved-model CLI runs passed; generated SLX/CSV/diagrams | Correct A/B and both outputs; generated SLX passes same scenarios as M02 | T2 |
| M04 | Required · 2.1 / 2.6 | Physical Simscape motor and load | Complete | Real DC Motor plus external JL, sources, sensors, references and solver; units/sign verified; no equation fallback | Retain compiled SLX and physical trace evidence | T6 |
| M05 | Required · 2.6 | Reusable Motor Model Subsystem | Complete | All three models expose Vin/TL inputs and omega/i outputs with matched SI units | Preserve reusable interface | T2, T6 |
| M06 | Required · 2.1 / 2.6 | Numerical comparison of all three MATLAB models | Complete | Zero, 12 V and load-step cases compared on common grids/zero initial states; maximum physical speed/current errors 1.25e-6/1.45e-6 | Results in simscape_comparison.csv and physical plots | T2, T6 |
| C01 | Required · 2.2 | Justified PID tuning method | Complete | T3: tuning, filter/scenario regressions and metric edge cases passed; pid_baseline_summary.csv records measured speed/current/voltage agreement | Reproduce chosen method, document ideal versus implemented filtered/saturated controller | T3 |
| C02 | Required · 2.2 | Identical PID behavior in MATLAB and Simulink | Complete | T3: tuning, filter/scenario regressions and metric edge cases passed; pid_baseline_summary.csv records measured speed/current/voltage agreement | Shared Tf/anti-windup law, scenario isolation, automated equivalence checks pass | T3 |
| C03 | Required · 2.2 | 100 rad/s within 2 s; low overshoot and steady error | Complete | Optimized physical PID: ts=1.675 s, OS=0.163%; validated equilibrium; required physical load case ts=1.690 s | Preserve declared voltage/OS/error assumptions and measured evidence | T3, T4, T6 |
| O01 | Required · 2.3 | Executable PID optimizer | Complete | T4: real objective, 5 converged starts, seeded GA, 7 weights, source/config hashes and sensitivity data; Python dependencies installed/pinned | Fix schema, objective regression and optimizer smoke/full runs pass | T4 |
| O02 | Required · 2.3 | Joint optimization of IAE and voltage effort | Complete | T4: real objective, 5 converged starts, seeded GA, 7 weights, source/config hashes and sensitivity data; Python dependencies installed/pinned | Explicit primary IAE/absolute-voltage objective, normalized weights, feasibility constraints and measured tradeoffs | T4 |
| O03 | Required · 2.3 | Reproducible selected gains and before/after comparison | Complete | T4: real objective, 5 converged starts, seeded GA, 7 weights, source/config hashes and sensitivity data; Python dependencies installed/pinned | Successful run history, seed/config/source hashes, selected-gain artifact and independent reevaluation | T4 |
| V01 | Required · 2.4 | Speed versus reference and applied-voltage plots | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T4, T6–T8 |
| V02 | Required · 2.4 | Settling time, overshoot and static error | Complete | T3: tuning, filter/scenario regressions and metric edge cases passed; pid_baseline_summary.csv records measured speed/current/voltage agreement | Define first-entry/sustained settling and equilibrium-tail error; edge-case tests and output table | T3 |
| V03 | Required · 2.4 | Total voltage effort and IAE | Complete | T3: tuning, filter/scenario regressions and metric edge cases passed; pid_baseline_summary.csv records measured speed/current/voltage agreement | Consistent fields, units, horizon and generated metrics for every compared controller | T3, T4 |
| V04 | Required · 2.4 | Quantitative conclusions backed by results | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T4, T6–T8 |
| L01 | Required · 2.6 | Closed-loop lag compensator versus PID | Complete | Actual physical PID/lag comparison on identical 12 s scenarios; lag ts=2.330 s, error=0.160 rad/s | Measured table/plot in compensator_comparison.csv | T6 |
| L02 | Required · 2.6 | Lead design and lag/lead tradeoff comparison | Complete | Actual physical lead ts=1.781 s, error=1.525 rad/s; lead uses slightly less absolute voltage effort for this tuning | Preserve observed tradeoff and failed chosen steady-error target | T6 |

## Python and FMU requirements

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| X01 | Required | Independent Python motor/control simulation | Complete | Independent SciPy equations/PID implemented; 11 Python checks pass; six MATLAB comparisons, max speed error 9.18e-7 rad/s and settling difference 0 | Independent SciPy equations, matched controller, analytical tests and scenario runs | T7 |
| X02 | Required | Python versus MATLAB comparison | Complete | Independent SciPy equations/PID implemented; 11 Python checks pass; six MATLAB comparisons, max speed error 9.18e-7 rad/s and settling difference 0 | Same event timing, parameters and states; trajectory/metric error tables and plots pass | T7 |
| X03 | Required | Export actual FMU from MATLAB | Complete | Actual MATLAB plant/PID tool-coupling FMUs exported; named scalar ports, units, CRC and SHA verified | Preserve MATLAB generation metadata and explicit local runtime dependency | T7 |
| X04 | Required | Run FMU in Python and compare to Python model | Complete | FMPy executes five scenarios on 1 ms and 0.5 ms grids with dedicated licensed MATLAB session; all original error gates pass | User-approved trial-only route requires local MATLAB/Simulink; standalone portability not claimed | T7 |

## Optional bonus and chosen enhancements

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| B01 | Bonus · 2.5 | 0.05 N m disturbance at t=1 s and rejection | Complete | T5: 4 tests pass; required disturbance settles in 1.690 s; observer/load tables and live-update evidence generated | Required load run, speed/voltage metrics, loaded equilibrium and preserved performance | T5 |
| B02 | Bonus · 2.5 | Live speed/voltage visualization | Complete | T5: 4 tests pass; required disturbance settles in 1.690 s; observer/load tables and live-update evidence generated | Launch from CLI without interactions; show updates during integration and verify trajectory agreement | T5 |
| B03 | Enhancement | Disturbance observer and recovery edge cases | Complete | T5: 4 tests pass; required disturbance settles in 1.690 s; observer/load tables and live-update evidence generated | Observer/sign checks and return Inf/status when recovery never occurs | T5 |
| B04 | Enhancement | Gain/plant sensitivity and optional benchmark | Complete | T4: real objective, 5 converged starts, seeded GA, 7 weights, source/config hashes and sensitivity data; Python dependencies installed/pinned | Separate gain and plant perturbations; bounded, evidence-based conclusions | T4 |

## Documentation, reproducibility and delivery

| ID | Scope | Necessary element | Status | Current evidence / gap | Acceptance evidence needed / next action | Task |
|---|---|---|---|---|---|---|
| D01 | Required | Readable documented code and README instructions | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T1–T9 |
| D02 | Required | Final report in Ukrainian as PDF | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T8 |
| D03 | Enabler | Report accuracy and visual verification | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T8 |
| D04 | Enabler | Regression tests and honest failure statuses | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T2–T7 |
| D05 | Enabler | One-command pipeline and clean-copy reproduction | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T8, T9 |
| D06 | Required | Submission ZIP: code, results and README | Complete | Primary Full CLI passes 43 MATLAB/27 Python checks; prior clean-copy 41/27 retained with unchanged numerical sources; genuine trial-only FMUs accepted; final 15-page Ukrainian PDF visually inspected; 210-file ZIP/extraction/PDF rebuild and Git byte checks verified | Preserve final manifest and documented local MATLAB/Simulink runtime dependency | T9 |
| D07 | Required | All code and PDF pushed to Git | Complete | Ordinary branch push verified at 33fc7e6; committed code, SLX, FMUs, PDF and ZIP paths checked | Preserve the published branch and downloadable artifacts | T9 |

## Current focus and review order

| Order | Focus | Status now | Exit condition |
|---|---|---|---|
| 1 | E02: isolated project and shared parameter/scenario contract | Verified milestone | Source snapshot/configuration saved; 30/30 hashes match originals |
| 2 | O01 + C02: optimizer field defect, PID filter and load overwrite | Verified milestone | Regressions pass on corrected production code |
| 3 | M01–M03 + C01–C03 + V02–V03: trusted core model/controller/metrics | Core verified; physical C03 validation pending | Clean CLI model/controller checks pass; nominal settling 1.675 s |
| 4 | O02–O03: actual optimization and comparison data | Verified milestone | Reproducible selected gains and measured objective tradeoffs saved |
| Dependency track | E03–E05: physical modeling and FMU tools | Freshly confirmed blocked; awaiting user decision | Libraries/exporter/compiler smoke tests pass; core work can proceed meanwhile |
| 5 | M04–M06 + L01–L02 + X01–X04 | Python verified; physical/FMU portions blocked | Three MATLAB models, Python and FMU all compared successfully |
| 6 | B01–B04, then D01–D07 | Bonus verified; final documentation/delivery pending | Report/ZIP verified; complete remote delivery confirmed |

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
| 2026-10-11 | Disturbance and independent Python milestones; MATLAB 37/37, Python 11/11; six cross-language cases; remote source SHA verified | Source branch published at e649148; physical products require administrator installation; final PDF/FMU/ZIP not complete |
| 2026-10-11 | Status review against completed milestone artifacts and implementation ledger | Corrected stale queued/failing narrative entries; retained physical/FMU blockers and pending Ukrainian PDF/ZIP; installation approval still pending |

| 2026-10-11 | Core runner exit 0, MATLAB 37/37, Python/report 16/16, SHA256 manifest and 14-page visual inspection | Ukrainian progress PDF verified; final report remains incomplete; simple milestone table maintained separately |

| 2026-10-11 | Lag/lead reference synthesis, independent lsim, event-refinement tests, full core exit 0; MATLAB 37/37 and Python/report 16/16; all 11 PDF pages inspected | Reference compensator milestone verified; physical implementation, real FMU and final delivery still pending |

| 2026-10-11 | Administrator install completed; portable compiler configured; actual three-model/physical-controller comparisons; 37 MATLAB and 16 Python/report checks | Simscape milestone complete; real FMU export still blocked by missing FMU Builder license, not missing installation |
