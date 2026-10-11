# Implementation decisions and review record

These decisions are retained from the plan execution ledger. The trial-only FMU runtime dependency is the material delivery limitation.

Ruling: The user has approved the existing architectural plan; no new brainstorming approval cycle is needed. It would repeat an already completed decision.

Ruling: Native worktree lies outside initial sandbox writable roots. Use approved normal-permission CLI file/Git/MATLAB operations there; stage authoring files in the original workspace and copy them to the managed worktree. No repository content is implemented on main.

Ruling: Use native Windows Git Bash skill scripts because default bash.exe is WSL. Preserve ledger in the plan-scoped skill workspace.

Task 8: Ruling: User requested continued independent work and a simple milestone table. Implement validated core orchestration and a explicitly marked Ukrainian progress PDF while physical/FMU prerequisites remain unavailable. Final-report mode must reject incomplete/stale evidence; T8 stays partial until required comparisons exist. Cost if wrong: the draft cannot serve as final submission.

Task 6: Ruling: Physical libraries remain absent. Proceed with independent lag/lead synthesis and reference-equation comparison, clearly labelled nonphysical; do not mark Simscape acceptance complete. Cost if wrong: reference-controller work must be adapted if actual physical block behavior differs.

Task 6: Ruling: Final verification runs the whole MATLAB suite in an isolated source/config/gain-artifact copy, then current Python/report checks. This preserves the finalized SLX/CSV/PDF byte hashes while testing current code fresh. Cost if wrong: copied fixtures could mask an environmental dependency; the complete original core pipeline already exited0 and report-input hashes are checked separately.

Task 7: Ruling: User explicitly requested completion using only trial-available products. Replace the previously selected standalone FMU path with documented Simulink tool-coupling FMUs; preserve real MATLAB exports and FMPy numerical checks, but explicitly require a local R2026a MATLAB/Simulink session. Standalone portability is not claimed. Probe exported an actual FMI2.0 FMU and FMPy verified Gain2 ->6. Cost if wrong: another computer must have matching licensed MATLAB/Simulink to run FMUs.

Task 7: Ruling: The 1e-4 s fixed solver step produced required-load FMU current error 1.61977e-4 A, above the unchanged 1e-4 A gate; nominal FMU current error was only 1.09e-6 A. Refine the local ode4 step to 1e-5 s and rerun both communication grids. No time shift or loosened gate. Cost if wrong: increased simulation cost without sufficient event accuracy.

Task 8/9: Ruling: Final report acceptance consumes the clean-copy proof produced by packaging task9, so execute computation verification, fresh-copy reproduction, final PDF, then ZIP verification as one delivery gate. Source-only task commits may share this verified increment. Cost if wrong: final report cannot be independently accepted before clean-copy evidence exists.
