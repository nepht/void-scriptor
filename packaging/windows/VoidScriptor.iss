#define AppName "Void Scriptor Studio"
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef ReleaseLabel
  #define ReleaseLabel "preview"
#endif
#ifndef SourceDir
  #define SourceDir "build\\windows\\x64\\runner\\Release"
#endif
#ifndef OutputDir
  #define OutputDir "build\\release-metadata"
#endif

[Setup]
AppId={{B5FCEB5D-4B72-4D6D-9B78-8EA8A2A1A45C}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#ReleaseLabel}
AppPublisher=Void Scriptor Studio
DefaultDirName={localappdata}\Programs\Void Scriptor Studio
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64
OutputDir={#OutputDir}
OutputBaseFilename=VoidScriptor-{#ReleaseLabel}-windows-x64-signed
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#AppName} {#ReleaseLabel}

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\void_scriptor.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\void_scriptor.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Buat pintasan di desktop"; GroupDescription: "Pintasan tambahan:"

[Run]
Filename: "{app}\void_scriptor.exe"; Description: "Jalankan {#AppName}"; Flags: nowait postinstall skipifsilent
