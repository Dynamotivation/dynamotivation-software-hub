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
WizardImageFile=assets\wizard-large.bmp
WizardSmallImageFile=assets\wizard-small.bmp
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
