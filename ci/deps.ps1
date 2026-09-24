# Builds the third-party libraries into the locations touchcursor.props expects:
#   C:\dev\external\wxWidgets-3.2.11   (static, Win32, /MD, Debug + Release)
#   C:\dev\external\boost_1_86_0       (Boost.Serialization, static, Win32, /MD)
# NOTE: this file's hash is the cache key, so any edit forces a full rebuild.
. "$PSScriptRoot\common.ps1"

$ext   = 'C:\dev\external'
$wx    = "$ext\wxWidgets-3.2.11"
$boost = "$ext\boost_1_86_0"
New-Item -ItemType Directory -Force $ext | Out-Null
$msbuild = Get-MSBuild

# --- wxWidgets ---
Invoke-WebRequest 'https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.11/wxWidgets-3.2.11.zip' -OutFile "$env:TEMP\wx.zip"
New-Item -ItemType Directory -Force $wx | Out-Null
Invoke-Checked 'Extract wxWidgets' { tar -xf "$env:TEMP\wx.zip" -C $wx }   # archive has no top-level folder
foreach ($cfg in 'Debug', 'Release') {
    Invoke-Checked "Build wxWidgets $cfg" {
        & $msbuild "$wx\build\msw\wx_vc17.sln" /m /v:minimal /p:Configuration=$cfg /p:Platform=Win32
    }
}
if (-not (Test-Path "$wx\lib\vc_lib\wxmsw32u_core.lib") -or -not (Test-Path "$wx\lib\vc_lib\wxmsw32ud_core.lib")) {
    Get-ChildItem "$wx\lib" -Recurse -Filter *.lib | Select-Object -First 20 FullName | Out-Host
    throw 'wxWidgets libraries not where touchcursor.props expects them'
}

# --- Boost.Serialization ---
Invoke-WebRequest 'https://github.com/boostorg/boost/releases/download/boost-1.86.0/boost-1.86.0-b2-nodocs.zip' -OutFile "$env:TEMP\boost.zip"
Invoke-Checked 'Extract Boost' { tar -xf "$env:TEMP\boost.zip" -C $ext }
Rename-Item "$ext\boost-1.86.0" $boost
Push-Location $boost
try {
    Invoke-Checked 'Bootstrap b2' { cmd /c bootstrap.bat }
    # runtime-link=shared matches the project's /MD and /MDd; the versioned layout
    # produces the names Boost's auto-linking asks for (e.g. ...-vc143-mt-gd-x32-1_86.lib).
    Invoke-Checked 'Build Boost.Serialization' {
        .\b2.exe --with-serialization toolset=msvc-14.3 address-model=32 architecture=x86 `
            link=static runtime-link=shared threading=multi variant=debug,release -j4 stage
    }
    New-Item -ItemType Directory -Force "$boost\lib32-msvc-14.3" | Out-Null
    Copy-Item "$boost\stage\lib\*.lib" "$boost\lib32-msvc-14.3"
    Get-ChildItem "$boost\lib32-msvc-14.3" | Select-Object Name | Out-Host
}
finally { Pop-Location }
