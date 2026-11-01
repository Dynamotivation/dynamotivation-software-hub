; Shared Inno Setup 5.6.1 settings for every Dynamotivation Windows app.
; An app script defines AppId (as "{{GUID}", the doubled brace is Inno's escape), AppName, AppVersion, AppExeName, SourceDir, OutputBase
; and MinVersion before including this file. Compile with ISCC 5.6.1 (Unicode).

#define Publisher "Dynamotivation"
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
SetupIconFile=assets\setup.ico
; Per-DPI wizard artwork, rendered from setup-icon.svg and full-logo.svg by installer\tools\render_assets.py.
; Inno picks the best match at runtime; sizes follow Inno's own recommended table.
WizardImageFile=assets\wizard-large-100.bmp,assets\wizard-large-125.bmp,assets\wizard-large-150.bmp,assets\wizard-large-175.bmp,assets\wizard-large-200.bmp,assets\wizard-large-225.bmp,assets\wizard-large-250.bmp
WizardSmallImageFile=assets\wizard-small-100.bmp,assets\wizard-small-125.bmp,assets\wizard-small-150.bmp,assets\wizard-small-175.bmp,assets\wizard-small-200.bmp,assets\wizard-small-225.bmp,assets\wizard-small-250.bmp
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
OutputDir=..\dist
OutputBaseFilename={#OutputBase}-{#AppVersion}
SignTool=dyn
SignedUninstaller=yes

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
