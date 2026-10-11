param(
    [ValidateSet('Preflight','Core','Full')][string]$Mode = 'Preflight',
    [string]$MatlabExe = 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$repositoryRoot = Split-Path (Split-Path $projectRoot -Parent) -Parent
$matlabPath = ($repositoryRoot -replace '\\','/').Replace("'","''")
$logRoot = Join-Path $projectRoot 'results\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$requireAll = if ($Mode -eq 'Full') { 'true' } else { 'false' }
& $MatlabExe -batch "cd('$matlabPath'); addpath('coursework/dc_motor/matlab'); preflight($requireAll); assertSuccess(runtests('coursework/dc_motor/matlab/tests/test_preflight.m'));" -logfile (Join-Path $logRoot 'preflight.log')
if ($LASTEXITCODE -ne 0) { throw "Preflight failed (exit $LASTEXITCODE)." }
if ($Mode -ne 'Preflight') {
    throw 'Core/full orchestration is not implemented yet. This is a setup milestone, not a complete submission.'
}
