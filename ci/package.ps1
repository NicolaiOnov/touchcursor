# Collects the Release binaries plus the x86 C++ runtime (app-local deployment,
# so the build works even without the VC++ Redistributable installed).
. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
$dist = "$root\dist"
New-Item -ItemType Directory -Force $dist | Out-Null
foreach ($f in 'touchcursor.exe', 'touchcursor.dll', 'tcconfig.exe', 'touchcursor_update.exe') {
    Copy-Item "$root\bin\Release\$f" $dist
}
$crt = Get-ChildItem "$(Get-VsPath)\VC\Redist\MSVC\*\x86\Microsoft.VC14*.CRT" -Directory |
       Sort-Object FullName | Select-Object -Last 1
Copy-Item "$($crt.FullName)\*.dll" $dist
Copy-Item "$root\ci\INSTALL.txt" $dist
Get-ChildItem $dist | Select-Object Name, Length | Out-Host
