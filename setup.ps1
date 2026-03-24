# ============================================================
#  POS System - Script d'installation (Windows PowerShell)
# ============================================================
$ErrorActionPreference = "Stop"

Write-Host "POS System - Installation" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# 1. Vérifier Flutter
if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    $version = flutter --version | Select-Object -First 1
    Write-Host "Flutter: $version" -ForegroundColor Green
} else {
    Write-Error "Flutter n'est pas installe. Visitez https://flutter.dev/docs/get-started/install"
    exit 1
}

# 1b. Generer les dossiers plateforme si manquants
if (-not (Test-Path "android") -or -not (Test-Path "ios")) {
    Write-Host ""
    Write-Host "Generation des fichiers plateforme..." -ForegroundColor Yellow
    flutter create .
}

# 2. Installer les dépendances
Write-Host ""
Write-Host "Installation des dependances..." -ForegroundColor Yellow
flutter pub get

# 3. Générer le code Drift
Write-Host ""
Write-Host "Generation du code Drift (SQLite)..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host ""
Write-Host "Installation terminee !" -ForegroundColor Green
Write-Host ""
Write-Host "Pour lancer l'application :"
Write-Host "  Windows      -> flutter run -d windows"
Write-Host "  Android/iOS  -> flutter run"
Write-Host ""
Write-Host "[!] N'oubliez pas de configurer les permissions :" -ForegroundColor Yellow
Write-Host "  Android -> android_config/AndroidManifest_permissions.xml"
Write-Host "  iOS     -> android_config/ios_Info_plist_keys.xml"