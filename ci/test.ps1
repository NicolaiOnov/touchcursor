# Runs TouchCursor's built-in self-test. In Debug builds the hook DLL runs its
# test suite from a static initializer, i.e. simply loading the DLL executes it:
# on failure it calls exit(<failure count>), on success it prints "Unit tests passed".
. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
$bin  = "$root\bin\Debug"
$vs   = Get-VsPath

# The Debug DLL needs the debug C/C++ runtime, which is not on PATH: copy it next to it.
$crt = Get-ChildItem "$vs\VC\Redist\MSVC\*\debug_nonredist\x86\Microsoft.VC14*.DebugCRT" -Directory |
       Sort-Object FullName | Select-Object -Last 1
$ucrt = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x86\ucrt\ucrtbased.dll" |
        Sort-Object FullName | Select-Object -Last 1
if (-not $crt -or -not $ucrt) { throw 'Debug runtime DLLs not found' }
Copy-Item "$($crt.FullName)\*.dll", $ucrt.FullName $bin

# The DLL is 32-bit, so it must be loaded by the 32-bit PowerShell.
$ps32 = "$env:SystemRoot\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
$script = @"
Add-Type -Namespace Native -Name K32 -MemberDefinition '[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern IntPtr LoadLibraryW(string path);'
`$h = [Native.K32]::LoadLibraryW('$bin\touchcursor.dll')
if (`$h -eq [IntPtr]::Zero) { Write-Output ('LoadLibrary failed, error ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error()); exit 100 }
Write-Output 'DLL loaded'
"@
# Passed via a file: quoting a script through -Command is fragile.
$tmp = Join-Path $env:TEMP 'tc-selftest.ps1'
Set-Content -Path $tmp -Value $script -Encoding ASCII
$out = & $ps32 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $tmp 2>&1 | Out-String
$code = $LASTEXITCODE
Write-Host $out
if ($code -ne 0) { throw "Self-test process exited with code $code (a small number = count of failed checks)" }
if ($out -notmatch 'Unit tests passed') { throw 'Self-test did not report success (did it run at all?)' }
Write-Host 'Self-tests passed.'
