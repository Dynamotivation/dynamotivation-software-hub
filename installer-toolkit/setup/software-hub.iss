; Dynamotivation Software Hub. Flutter requires Windows 10 or newer, so the floor is 10.0.
; Compile: iscc /DAppVersion=0.1.0 /Sdyn=<sign-command> installer\software-hub.iss
#ifndef AppVersion
  #error Pass /DAppVersion=x.y.z
#endif
#define AppId "{{6F0B3E52-2C58-4C0B-9F5E-1D7A4B8E9C31}"
#define AppName "Dynamotivation Software Hub"
#define AppExeName "dynamotivation_software_hub.exe"
#define OutputBase "Dynamotivation-Software-Hub-Setup"
#define MinVersion "10.0.10240"
#ifndef SourceDir
  #define SourceDir "..\apps\windows\build\windows\x64\runner\Release"
#endif

#include "common.iss"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
