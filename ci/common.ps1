# Shared helpers for the CI scripts.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar

function Get-VsPath {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
    if (-not $vs) { throw 'Visual Studio with MSBuild not found' }
    return $vs
}

function Get-MSBuild { Join-Path (Get-VsPath) 'MSBuild\Current\Bin\MSBuild.exe' }

function Invoke-Checked([string]$what, [scriptblock]$cmd) {
    Write-Host "::group::$what"
    & $cmd
    $code = $LASTEXITCODE
    Write-Host '::endgroup::'
    if ($code -ne 0) { throw "$what failed with exit code $code" }
}
