param([string]$CompilerParent = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$repositoryRoot = Split-Path (Split-Path $projectRoot -Parent) -Parent
if (-not $CompilerParent) { $CompilerParent = Join-Path (Split-Path $repositoryRoot -Parent) 'toolchain' }
if ($CompilerParent -match '\s') { throw 'Use a compiler directory without spaces (MathWorks MinGW requirement).' }
$cache = Join-Path $projectRoot '.installer-cache'
New-Item -ItemType Directory -Force -Path $cache,$CompilerParent | Out-Null
$archive = Join-Path $cache 'mingw-8.1.0.7z'
$expectedSha = '853970527B5DE4A55EC8CA4D3FD732C00AE1C69974CC930C82604396D43E79F8'
$url = 'https://downloads.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z'
if (-not (Test-Path -LiteralPath $archive) -or (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedSha) {
    & curl.exe --fail --location --retry 2 --output $archive $url
    if ($LASTEXITCODE -ne 0) { throw 'Official compiler archive download failed.' }
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedSha) { throw 'Compiler archive SHA256 differs from the verified distribution.' }
$compilerRoot = Join-Path $CompilerParent 'mingw64'
if (-not (Test-Path -LiteralPath (Join-Path $compilerRoot 'bin\gcc.exe'))) {
    & tar.exe -xf $archive -C $CompilerParent
    if ($LASTEXITCODE -ne 0) { throw 'Compiler extraction failed.' }
}
$compilerVersion = & (Join-Path $compilerRoot 'bin\gcc.exe') --version
if ($LASTEXITCODE -ne 0 -or $compilerVersion[0] -notmatch '8\.1\.0') { throw 'Expected MinGW-w64 GCC 8.1.0.' }
$env:MW_MINGW64_LOC = $compilerRoot
Write-Output "MW_MINGW64_LOC=$compilerRoot (this PowerShell session only)"
Write-Output $compilerVersion[0]
& 'C:\Program Files\MATLAB\R2026a\bin\matlab.exe' -batch "mex('-setup','C'); mex('-setup','C++');"
if ($LASTEXITCODE -ne 0) { throw 'MATLAB compiler selection failed.' }
