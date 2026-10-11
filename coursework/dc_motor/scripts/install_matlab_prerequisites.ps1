param(
    [string]$MatlabRoot = 'C:\Program Files\MATLAB\R2026a',
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$products = @('Simscape', 'Simscape_Electrical', 'Simulink_FMU_Builder')
Write-Output "Destination: $MatlabRoot"
Write-Output 'Release: R2026a Update 4 (matches the current installation)'
Write-Output ('Products: ' + ($products -join ', '))
Write-Output "Administrator token: $isAdministrator"
if ($CheckOnly) { return }
if (-not $isAdministrator) {
    throw 'Run this script from an administrator PowerShell. No product installation has been attempted.'
}
if (-not (Test-Path -LiteralPath (Join-Path $MatlabRoot 'bin\matlab.exe'))) {
    throw 'The existing MATLAB executable was not found at the specified destination.'
}
$cache = Join-Path $projectRoot '.installer-cache'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$mpm = Join-Path $cache 'mpm.exe'
Invoke-WebRequest -Uri 'https://www.mathworks.com/mpm/win64/mpm' -OutFile $mpm
$signature = Get-AuthenticodeSignature -LiteralPath $mpm
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'MathWorks') {
    throw 'The downloaded MathWorks installer signature could not be verified.'
}
$logDir = Join-Path $projectRoot 'results\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
& $mpm install '--release=R2026aU4' "--destination=$MatlabRoot" '--products=Simscape' 'Simscape_Electrical' 'Simulink_FMU_Builder' *> (Join-Path $logDir 'matlab_product_install.log')
if ($LASTEXITCODE -ne 0) {
    Get-Content -LiteralPath (Join-Path $logDir 'matlab_product_install.log') -Tail 25
    throw "MathWorks product installation failed (exit $LASTEXITCODE)."
}
Write-Output 'Product installation command completed. Re-run MATLAB preflight before accepting the environment.'
Write-Output 'A compiler may still need installation/configuration; actual FMU export will verify that separately.'
