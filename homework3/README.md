# Homework 3 — custom 6DOF equations in NED

This folder contains a custom six-degree-of-freedom rigid-body model in the
North-East-Down frame and an automated comparison with the Aerospace Blockset
`6DoF (Euler Angles)` block.

## Run

1. Open MATLAB R2026a with Simulink and Aerospace Blockset.
2. Add `homework3/scripts` to the MATLAB path.
3. Run `run_dz3_comparison` to rebuild the model, execute all 11 scenarios,
   and regenerate the result tables and plots.
4. Run `runtests('../tests')` from `homework3/scripts` for the acceptance suite.

The Simulink model can also be opened and run directly. Its `InitFcn` creates
safe zero force and moment inputs only when scenario inputs are absent.

## Main artifacts

- `scripts/build_dz3_6dof_model.m` — reproducible model builder.
- `scripts/run_dz3_comparison.m` — canonical and Homework 1 comparisons.
- `models/dz3_6dof_ned_compare.slx` — generated Simulink model.
- `tests/` — mathematical, structural, and end-to-end tests.
- `report/DZ3_6DOF_NED_Report_Final.pdf` — final report.
