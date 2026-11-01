; Shared Inno Setup 5.6.1 settings for every Dynamotivation Windows app.
; An app script defines AppId (as "{{GUID}", the doubled brace is Inno's escape), AppName, AppVersion, AppExeName, SourceDir, OutputBase
; and MinVersion before including this file. Compile with ISCC 5.6.1 (Unicode).

#ifndef Publisher
  #define Publisher "Dynamotivation"
#endif
#define PublisherUrl "https://dynamotivation.com/"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Publisher}
AppPublisherURL={#PublisherUrl}
AppSupportURL={#PublisherUrl}
AppUpdatesURL={#PublisherUrl}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#Publisher}
VersionInfoDescription={#AppName} Setup
DefaultDirName={localappdata}\Programs\{#Publisher}\{#AppName}
DefaultGroupName={#Publisher}
DisableProgramGroupPage=yes
DisableDirPage=yes
ShowLanguageDialog=no
#ifndef AssetDir
  #define AssetDir "assets"
#endif
SetupIconFile={#AssetDir}\setup.ico
; Per-DPI wizard artwork, rendered from setup-icon.svg and full-logo.svg by installer\tools\render_assets.py.
; Inno picks the best match at runtime; sizes follow Inno's own recommended table.
WizardImageFile={#AssetDir}\wizard-large-100.bmp,{#AssetDir}\wizard-large-125.bmp,{#AssetDir}\wizard-large-150.bmp,{#AssetDir}\wizard-large-175.bmp,{#AssetDir}\wizard-large-200.bmp,{#AssetDir}\wizard-large-225.bmp,{#AssetDir}\wizard-large-250.bmp
WizardSmallImageFile={#AssetDir}\wizard-small-100.bmp,{#AssetDir}\wizard-small-125.bmp,{#AssetDir}\wizard-small-150.bmp,{#AssetDir}\wizard-small-175.bmp,{#AssetDir}\wizard-small-200.bmp,{#AssetDir}\wizard-small-225.bmp,{#AssetDir}\wizard-small-250.bmp
PrivilegesRequired=lowest
MinVersion={#MinVersion}
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
Compression=lzma2
SolidCompression=yes
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBase}-setup-{#AppVersion}
#ifdef SignEnabled
SignTool=dyn
SignedUninstaller=yes
#endif

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
