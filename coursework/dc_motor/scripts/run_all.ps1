param(
    [ValidateSet('Preflight','Core','Full')][string]$Mode = 'Preflight',
    [string]$MatlabExe = 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe',
    [string]$PythonExe = '',
    [string]$CompilerRoot = '',
    [switch]$ComputeOnly,
    [switch]$RegenerateOptimization
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$repositoryRoot = Split-Path (Split-Path $projectRoot -Parent) -Parent
if (-not $CompilerRoot) { $CompilerRoot = $env:MW_MINGW64_LOC }
if (-not $CompilerRoot) { $CompilerRoot = Join-Path (Split-Path $repositoryRoot -Parent) 'toolchain\mingw64' }
if (Test-Path -LiteralPath (Join-Path $CompilerRoot 'bin\gcc.exe')) { $env:MW_MINGW64_LOC = $CompilerRoot }
$matlabPath = ($repositoryRoot -replace '\\','/').Replace("'","''")
$logRoot = Join-Path $projectRoot 'results\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
if ($Mode -eq 'Preflight') {
    & $MatlabExe -batch "cd('$matlabPath'); addpath('coursework/dc_motor/matlab'); preflight(false,'tool_coupling'); assertSuccess(runtests('coursework/dc_motor/matlab/tests/test_preflight.m'));" -logfile (Join-Path $logRoot 'preflight.log')
    if ($LASTEXITCODE -ne 0) { throw "Preflight failed (exit $LASTEXITCODE)." }
    return
}
if (-not $PythonExe) { $PythonExe = Join-Path $projectRoot '.venv\Scripts\python.exe' }
if (-not (Test-Path -LiteralPath $PythonExe)) { throw 'Create the project Python environment and install requirements.txt first.' }
$regenerate = if ($RegenerateOptimization) { 'true' } else { 'false' }
$matlabMode = $Mode.ToLowerInvariant()
& $MatlabExe -batch "cd('$matlabPath'); addpath('coursework/dc_motor/matlab'); run_coursework('$matlabMode',$regenerate);" -logfile (Join-Path $logRoot 'core.log')
if ($LASTEXITCODE -ne 0) { throw "MATLAB $Mode run failed (exit $LASTEXITCODE)." }
& $PythonExe (Join-Path $projectRoot 'python\run_comparisons.py')
if ($LASTEXITCODE -ne 0) { throw 'Independent Python comparisons failed.' }
if ($Mode -eq 'Full') {
    $env:PYTHONPATH = Join-Path $projectRoot 'python'
    $env:DC_MOTOR_MATLAB_ROOT = Split-Path (Split-Path $MatlabExe -Parent) -Parent
    & $PythonExe -m dc_motor.run_fmu --study
    if ($LASTEXITCODE -ne 0) { throw 'Real MATLAB FMU/FMPy comparisons failed.' }
}
$builder = Join-Path $projectRoot 'report\build_report.py'
& $PythonExe $builder --draft --refresh-manifest
if ($LASTEXITCODE -ne 0) { throw 'Validated progress report failed.' }
$pytestXmlArgument = '--junitxml=' + (Join-Path $logRoot 'python-tests.xml')
& $PythonExe -m pytest (Join-Path $projectRoot 'python\tests') -q $pytestXmlArgument
if ($LASTEXITCODE -ne 0) { throw 'Python/report checks failed.' }
Write-Output "$Mode computations verified. Progress PDF generated; final PDF/ZIP require clean-copy verification."

if ($Mode -eq 'Full' -and -not $ComputeOnly) {
    & $PythonExe (Join-Path $projectRoot 'scripts\finish_submission.py') --matlab-exe $MatlabExe
    if ($LASTEXITCODE -ne 0) { throw 'Final clean-copy/PDF/ZIP verification failed.' }
}