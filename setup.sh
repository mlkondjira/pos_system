#!/bin/bash
# ============================================================
#  POS System — Script d'installation et configuration
# ============================================================
set -e

echo "🚀 POS System — Installation"
echo "=============================="

# 1. Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé. Visitez https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter: $(flutter --version | head -1)"

# 2. Installer les dépendances
echo ""
echo "📦 Installation des dépendances..."
flutter pub get

# 3. Générer le code Drift
echo ""
echo "🔧 Génération du code Drift (SQLite)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Installation terminée !"
echo ""
echo "Pour lancer l'application :"
echo "  Android/iOS  → flutter run"
echo "  Windows      → flutter run -d windows"
echo "  macOS        → flutter run -d macos"
echo "  Linux        → flutter run -d linux"
echo ""
echo "⚠️  N'oubliez pas de configurer les permissions :"
echo "  Android → android_config/AndroidManifest_permissions.xml"
echo "  iOS     → android_config/ios_Info_plist_keys.xml"
