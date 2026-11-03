; Dynamotivation Software Hub. Flutter requires Windows 10 or newer, so the floor is 10.0.
; Compile: iscc /DAppVersion=0.1.0 /Sdyn=<sign-command> installer\software-hub.iss
#ifndef AppVersion
  #error Pass /DAppVersion=x.y.z
#endif
#define AppId "{{6F0B3E52-2C58-4C0B-9F5E-1D7A4B8E9C31}"
#define AppName "Dynamotivation Software Hub"
#define AppExeName "dynamotivation_software_hub.exe"
#define OutputBase "dynamotivation-software-hub"
#define MinVersion "10.0.10240"
; The app's per-user data folder (its catalog cache and staged self-update setups).
#define AppDataName "Dynamotivation Software Hub"
#ifndef SourceDir
  #define SourceDir "..\apps\windows\build\windows\x64\runner\Release"
#endif
; Assets live one level above setup/ so the toolkit layout works as a subtree too.
#define AssetDir "..\assets"

#include "common.iss"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[UninstallDelete]
; The app writes its cache and the setup of the next version here; Setup never installed
; it, so without this the uninstaller leaves the folder behind.
Type: filesandordirs; Name: "{localappdata}\{#AppDataName}"
Type: dirifempty; Name: "{app}"
