# DC motor coursework - milestone check

Updated: 2026-10-12. Implementation: `codex/dc-motor-coursework`.

| Milestone | Check | Evidence / remaining work |
|---|---|---|
| 1. Review and core CLI setup | Done | Buddy/course review and MATLAB/Python core setup verified |
| 2. Equations and state-space models | Done | Two generated Simulink models agree with direct equations |
| 3. PID and performance metrics | Done | MATLAB/Simulink controller agreement verified |
| 4. PID optimization | Done | Settling 1.675 s; overshoot 0.163%; measured IAE/voltage tradeoffs |
| 5. Disturbance and live visualization | Done | Required load case settles in 1.690 s; CLI live updates verified |
| 6. Simscape and lag/lead comparisons | Done | Actual physical motor/load and PID/lag/lead comparisons pass numerical gates |
| 7. Python and FMU exchange | Done | Genuine MATLAB tool-coupling FMUs run in FMPy; five scenarios pass at 1 ms and 0.5 ms; local MATLAB/Simulink required |
| 8. Ukrainian report | Done | Final 15-page Ukrainian PDF built from accepted results; all pages rendered and inspected |
| 9. Final ZIP and Git delivery | Done | Primary 43 MATLAB/27 Python; prior clean-copy 41/27 retained with unchanged numerical sources; revised PDF/ZIP verified; remote 33fc7e6 confirmed |

Current focus: all nine milestones complete. Trial-compatible tool-coupling FMUs require local MATLAB/Simulink R2026a. The missing historical course note remains a documented preparation limitation.

[Detailed requirement checks](dc-motor-requirements.md) · [Approved implementation plan](plans/2026-10-11-dc-motor-coursework-sol.md)
