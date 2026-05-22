; Script Inno Setup pour POS System
#define AppName "Gpos"
#define AppVersion "1.0.0"
#define AppPublisher "Emelka Tech"
#define AppExeName "Gpos.exe"
#define AppIconName "app_icon.ico"

[Setup]
AppId={{A8788AEF-1C15-457B-9B0D-637D0C524FF8}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
AppMutex=GposMutex
CloseApplications=yes
PrivilegesRequired=admin
LicenseFile=license.txt
; Dossier de sortie de l'installeur
OutputDir=..\..\build\windows\installer
OutputBaseFilename=Setup_Gpos
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; --- CONFIGURATION DES ICÔNES ---
; Icône du fichier d'installation (Setup.exe)
SetupIconFile=..\runner\resources\{#AppIconName}
; Icône affichée dans le panneau de configuration (Désinstallation)
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; On inclut l'exécutable principal
Source: "..\..\build\windows\x64\runner\Release\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; On inclut TOUTES les DLL et le dossier data nécessaires au fonctionnement de Flutter
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#AppExeName}"
; Note: ne pas inclure de fichiers de base de données ici pour ne pas écraser les données clients lors d'une mise à jour

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#AppExeName}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Optionnel : Vérifier si WebView2 ou d'autres dépendances sont installées si nécessaire