# DC motor coursework - milestone check

Updated: 2026-10-11. Implementation: `codex/dc-motor-coursework`.

| Milestone | Check | Evidence / remaining work |
|---|---|---|
| 1. Review and CLI setup | Partial | Buddy/course review and MATLAB/Python setup done; Simscape/FMU products still need installation |
| 2. Equations and state-space models | Done | Two generated Simulink models agree with direct equations |
| 3. PID and performance metrics | Done | MATLAB/Simulink controller agreement verified |
| 4. PID optimization | Done | Settling 1.675 s; overshoot 0.163%; measured IAE/voltage tradeoffs |
| 5. Disturbance and live visualization | Done | Required load case settles in 1.690 s; CLI live updates verified |
| 6. Simscape and lag/lead comparisons | Pending tools | Physical libraries absent; actual physical validation still required |
| 7. Python and FMU exchange | Partial | Independent Python comparisons done; real MATLAB FMU export/run pending |
| 8. Ukrainian report | Draft done | 10-page progress PDF generated and visually checked; final report awaits Simscape/FMU |
| 9. Final ZIP and Git delivery | Partial | Current source/results pushed; final PDF/ZIP and clean-copy checks pending |

Current focus: milestone 6 - independent lag/lead design; physical validation follows when tools are installed.

[Detailed requirement checks](dc-motor-requirements.md) · [Approved implementation plan](plans/2026-10-11-dc-motor-coursework-sol.md)
