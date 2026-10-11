# DC motor coursework - milestone check

Updated: 2026-10-11. Implementation: `codex/dc-motor-coursework`.

| Milestone | Check | Evidence / remaining work |
|---|---|---|
| 1. Review and core CLI setup | Done | Buddy/course review and MATLAB/Python core setup verified |
| 2. Equations and state-space models | Done | Two generated Simulink models agree with direct equations |
| 3. PID and performance metrics | Done | MATLAB/Simulink controller agreement verified |
| 4. PID optimization | Done | Settling 1.675 s; overshoot 0.163%; measured IAE/voltage tradeoffs |
| 5. Disturbance and live visualization | Done | Required load case settles in 1.690 s; CLI live updates verified |
| 6. Simscape and lag/lead comparisons | Done | Actual physical motor/load and PID/lag/lead comparisons pass numerical gates |
| 7. Python and FMU exchange | Done | Genuine MATLAB tool-coupling FMUs run in FMPy; five scenarios pass at 1 ms and 0.5 ms; local MATLAB/Simulink required |
| 8. Ukrainian report | In progress | Final narrative and FMU results added; final PDF generation and visual inspection pending |
| 9. Final ZIP and Git delivery | Partial | Current source/results pushed; final PDF/ZIP and clean-copy checks pending |

Current focus: milestones 8-9 - complete Full CLI run, repeat from a fresh copy, inspect final Ukrainian PDF, package ZIP and verify Git push. User authorized trial-only tool-coupling FMUs; standalone portability is not claimed.

[Detailed requirement checks](dc-motor-requirements.md) · [Approved implementation plan](plans/2026-10-11-dc-motor-coursework-sol.md)
