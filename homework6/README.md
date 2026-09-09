# Homework 6 - transfer function and inverted pendulum

## Run the Python analysis

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r homework6\requirements.txt
$env:MPLCONFIGDIR = (Join-Path (Get-Location) 'homework6\.matplotlib')
.\.venv\Scripts\python.exe -m homework6.run_analysis
.\.venv\Scripts\python.exe -m unittest discover -s homework6\tests -v
```

## Build the Simulink models

```matlab
addpath('homework6/simulink');
build_hw6_models
```

## Build the report

```powershell
.\.venv\Scripts\python.exe homework6\report\build_report.py
```

The final submission is `report/DZ6_Control_and_Pendulum_Report.pdf`; the
Simulink deliverables are `simulink/hw6_linear_pendulum.slx` and
`simulink/hw6_nonlinear_pendulum.slx`.
