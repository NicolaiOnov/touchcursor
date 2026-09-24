. "$PSScriptRoot\common.ps1"
$msbuild = Get-MSBuild
$root = Split-Path $PSScriptRoot -Parent
foreach ($cfg in 'Debug', 'Release') {
    Invoke-Checked "Build TouchCursor $cfg" {
        & $msbuild "$root\touchcursor.sln" /m /v:minimal /p:Configuration=$cfg /p:Platform=Win32
    }
}
Get-ChildItem "$root\bin" -Recurse -Include *.exe, *.dll | Select-Object FullName, Length | Out-Host
