; Script Inno Setup pour POS System

[Setup]
AppId={{A8788AEF-1C15-457B-9B0D-637D0C524FF8}
AppName=POS System
AppVersion=1.0
AppPublisher=My Business
DefaultDirName={autopf}\POS System
DefaultGroupName=POS System
; Dossier où sera généré l'installeur
OutputDir=..\build\windows\installer
OutputBaseFilename=pos_system_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; Affiche le contrat de licence avant l'installation
LicenseFile=license.txt
; Icone de l'installeur (si vous en avez une)
; SetupIconFile=runner\resources\app_icon.ico

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; L'exécutable principal
Source: "..\build\windows\x64\runner\Release\pos_system.exe"; DestDir: "{app}"; Flags: ignoreversion

; Les DLLs indispensables (Flutter engine, plugins comme audioplayers, etc.)
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Inclure l'installeur Visual C++ (téléchargé et placé dans le dossier windows/)
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

; Le dossier Data (Polices, Assets, Icônes) - Très important !
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Note: Si vous utilisez des polices spécifiques ou des fichiers de config,
; assurez-vous qu'ils sont bien dans le dossier data via pubspec.yaml

[Icons]
Name: "{group}\POS System"; Filename: "{app}\pos_system.exe"
Name: "{autodesktop}\POS System"; Filename: "{app}\pos_system.exe"; Tasks: desktopicon

[Run]
; Installation du Redistribuable Visual C++ (uniquement si nécessaire)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Check: VCRedistNeedsInstall; StatusMsg: "Installation des composants système (Visual C++ Redistributable)..."

; Lancer l'app après l'installation
Filename: "{app}\pos_system.exe"; Description: "{cm:LaunchProgram,POS System}"; Flags: nowait postinstall skipifsilent

[Code]
// Fonction pour vérifier si le Redistribuable VC++ 2015-2022 x64 est déjà installé
function VCRedistNeedsInstall(): Boolean;
var
  Installed: Cardinal;
begin
  // On vérifie la clé de registre spécifique à la version x64 du Redistribuable 14.0 (2015-2022)
  if RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Installed', Installed) then
  begin
    // Si Installed = 1, le composant est déjà présent
    Result := (Installed = 0);
  end
  else
  begin
    // Si la clé n'existe pas, il faut l'installer
    Result := True;
  end;
end;