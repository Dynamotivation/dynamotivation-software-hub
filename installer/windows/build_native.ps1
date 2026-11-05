<#
The only step that needs Windows: compile the app (Flutter's own Windows build, MSVC)
and the tiny signing bridge Inno calls under Wine on Linux. Everything after this
(signing, the Inno Setup installer, release, website) runs on Linux, see
installer/linux/package_windows.py.

Output, below -Out:
  bundle/                       the Release folder plus the app-local VC++ runtime
  native/hub_sign_bridge.exe    static-CRT helper that hands signing back to Linux
#>
param([Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Out = [IO.Path]::GetFullPath($Out, $root)
Remove-Item $Out -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$Out\bundle", "$Out\native", "$Out\obj" | Out-Null

Push-Location "$root\apps\windows"
try {
  flutter build windows --release
  if ($LASTEXITCODE) { throw 'flutter build windows failed' }
} finally { Pop-Location }

$release = "$root\apps\windows\build\windows\x64\runner\Release"
if (-not (Test-Path "$release\dynamotivation_software_hub.exe")) { throw 'The Windows build produced no exe.' }
Copy-Item "$release\*" "$Out\bundle" -Recurse

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with the C++ tools was not found.' }

# The app links the dynamic VC++ runtime; ship it beside the exe (app-local
# deployment) so the app starts on a machine without the redistributable.
$crt = Get-ChildItem "$vs\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT" -Directory |
  Sort-Object FullName | Select-Object -Last 1
if (-not $crt) { throw 'The VC++ runtime was not found.' }
Copy-Item "$($crt.FullName)\*.dll" "$Out\bundle"

$build = "`"$vs\VC\Auxiliary\Build\vcvars64.bat`" && cl /nologo /EHsc /O2 /MT /Fo`"$Out\obj\sign_bridge.obj`" " +
  "/Fe`"$Out\native\hub_sign_bridge.exe`" `"$root\installer\windows\sign_bridge.cpp`" ws2_32.lib"
cmd /c $build
if ($LASTEXITCODE) { throw 'Compiling the signing bridge failed.' }
Remove-Item "$Out\obj" -Recurse -Force
