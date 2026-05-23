@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

echo [0/4] Fermeture des instances existantes de Gpos...
taskkill /F /IM Gpos.exe /T >nul 2>&1
timeout /t 1 /nobreak >nul

REM Utilisation de GOTO pour éviter les blocs de parenthèses qui plantent avec le PATH
if /i "%1"=="--clean" goto :do_clean
echo [1/3] Skip Nettoyage (utilisez --clean pour une recompilation totale)...
goto :after_clean

:do_clean
echo [1/3] Nettoyage complet du projet...
call flutter clean || (
    echo [!] flutter clean a echoue, suppression manuelle du dossier build...
    rmdir /s /q build 2>nul
)

:after_clean

echo [1.5/3] Restauration des packages...
call flutter pub get

echo [2/3] Conversion des fichiers audio (MP3 -> WAV)...
if not exist lib\core\utils\convert_audio.dart (
    echo ERROR: Fichier lib\core\utils\convert_audio.dart introuvable.
    exit /b 1)
call dart run lib/core/utils/convert_audio.dart
if %errorlevel% neq 0 (
    echo ERROR: La conversion audio a echoue.
    exit /b %errorlevel%
)

echo [2.3/3] Creation du logo carre (Assets)...
if not exist lib\core\utils\generate_square_icon.dart (
    echo ERROR: Fichier lib\core\utils\generate_square_icon.dart introuvable.
    exit /b 1)
call dart run lib/core/utils/generate_square_icon.dart
if %errorlevel% neq 0 (
    echo ERROR: La generation de l'icone carree a echoue.
    exit /b %errorlevel%
)

echo [2.6/3] Generation des icones de plateforme...
call dart run flutter_launcher_icons
if %errorlevel% neq 0 (
    echo ERROR: La generation des icones de plateforme a echoue.
    exit /b %errorlevel%
)

echo [3/3] Lancement de la compilation Flutter Windows...

REM Verification et telechargement de NuGet (pattern sans parentheses pour eviter les erreurs de parsing)
if exist "C:\Users\DELL\nuget.exe" goto :add_nuget_to_path
echo [3.0.1/3] nuget.exe non trouve. Telechargement...
powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'C:\Users\DELL\nuget.exe'"
if %errorlevel% neq 0 goto :nuget_download_error
echo [3.0.1/3] nuget.exe telecharge avec succes.
goto :add_nuget_to_path

:nuget_download_error
echo ERROR: Echec du telechargement de nuget.exe.
exit /b %errorlevel%

:add_nuget_to_path
REM Ajout au PATH en dehors de tout bloc de parentheses (CRUCIAL)
set "PATH=C:\Users\DELL;!PATH!"

echo [3.1/3] Verification de la commande flutter...
call flutter build windows

if %errorlevel% neq 0 (
    echo ERROR: La compilation Flutter a echoue.
    exit /b %errorlevel%
)

:after_flutter_build
echo.
echo [VÉRIFICATION] Veuillez vérifier l'icône de Gpos.exe dans la fenêtre qui vient de s'ouvrir.
explorer build\windows\x64\runner\Release
pause

echo [4/4] Creation de l'installeur EXE (Inno Setup)...
set "INNO_COMPILER=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

REM On evite les blocs de parentheses pour les chemins contenant (x86)
if not exist "%INNO_COMPILER%" goto :no_inno
"%INNO_COMPILER%" windows\installer\pos_installer.iss
goto :inno_done

:no_inno
echo WARNING: Compilateur Inno Setup non trouve. Installeur non genere.

:inno_done

if %errorlevel% equ 0 (
    explorer build\windows\installer
)

ENDLOCAL