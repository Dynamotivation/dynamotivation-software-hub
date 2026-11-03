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
; The app's own per-user data folder: the deterministic cache of hub_core
; (hubCacheName + cacheDirectory) must keep matching this.
#define AppDataName "Dynamotivation Software Hub"
#ifndef SourceDir
  #define SourceDir "..\apps\windows\build\windows\x64\runner\Release"
#endif
; Assets live one level above setup/ so the toolkit layout works as a subtree too.
#define AssetDir "..\assets"

#include "common.iss"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Code]
{ Where updates stage their setup, next to the app's disk cache. The app must
  keep this in sync: hub_core downloads to <AppDataName>\Cache\updates. }
function UpdatesFolder: String;
begin
  Result := AddBackslash(ExpandConstant('{localappdata}')) + '{#AppDataName}' + '\Cache\updates\';
end;

{ Older staged setups (failed, cancelled or superseded updates) must not pile up
  in the cache folder. The setup about to run lives there too by name
  setup-<this-version>.exe, so the running one is skipped: deleting the file
  Setup runs from breaks the update (inno launched it from disk). }
procedure RemoveStaleStagedSetups;
var
  Rec: TFindRec;
  Folder, Running: String;
begin
  Folder := UpdatesFolder;
  Running := ExpandConstant('{srcexe}');
  if not DirExists(Folder) then
    Exit;
  if FindFirst(Folder + 'setup-*.exe', Rec) then
  try
    repeat
      if ((Rec.Attributes and FILE_ATTRIBUTE_DIRECTORY) = 0) and
         (CompareText(Folder + Rec.Name, Running) <> 0) then
        DeleteFile(Folder + Rec.Name);
    until not FindNext(Rec);
  finally
    FindClose(Rec);
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  RemoveStaleStagedSetups;
end;

{ When this setup runs from the staging folder itself (i.e. it was started by
  the app's updater), a running exe cannot delete itself: hand it to a hidden
  cmd that retries until it is gone, like the generator's installer does. Only
  a setup-*.exe inside the staging folder is removed; a setup the user started
  from anywhere else is never touched. }
procedure DeinitializeSetup;
var
  Source, Folder: String;
  ResultCode: Integer;
begin
  Source := ExpandConstant('{srcexe}');
  try
    Folder := UpdatesFolder;
  except
    Exit;
  end;
  if (CompareText(AddBackslash(ExtractFilePath(Source)), Folder) = 0)
      and (CompareText(Copy(ExtractFileName(Source), 1, 6), 'setup-') = 0) then
    Exec(ExpandConstant('{sys}\cmd.exe'),
      '/c for /l %i in (1,1,20) do @if exist "' + Source + '" (del /f /q "' + Source + '" 2>nul & ping 127.0.0.1 -n 2 >nul)',
      '', SW_HIDE, ewNoWait, ResultCode);
end;

[UninstallDelete]
; Self-updates stage the setup of the next version in the app's disk cache
; (updates\setup-<version>.exe), and the catalog cache and its icons live in
; the same per-user data folder. Setup never installed any of it, so without
; this the uninstaller would leave the whole folder behind.
Type: filesandordirs; Name: "{localappdata}\{#AppDataName}"
