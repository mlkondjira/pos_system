# 🛒 Gpos — Point de Vente & Inventaire

Système de caisse complet pour petits et moyens commerces.  
**Flutter multiplateforme** : Android · iOS · Windows · macOS · Linux

---

## 📋 Fonctionnalités

### 💰 Caisse (POS)
- Scan de codes-barres via caméra smartphone (ML Kit)
- Grille de produits avec recherche en temps réel
- Panier avec modification de quantités et remises par ligne
- Remise globale sur la vente
- Calcul automatique TTC/HT/taxes
- Modes de paiement : Espèces, Carte, Mobile Money, Crédit
- Rendu de monnaie automatique
- Succès dialog avec option de reçu

### 🧾 Reçus thermiques Bluetooth
- Génération ESC/POS native (EPSON, Star, Xprinter…)
- Papier 58mm et 80mm configurable
- Connexion Bluetooth automatique
- Réimpression depuis l'historique

### 📦 Gestion des produits
- Catalogue avec catégories et sous-catégories
- Codes-barres (EAN-8, EAN-13, QR, codes internes)
- Prix HT + taux de taxe par produit
- Prix d'achat (calcul de marge)
- Gestion des unités (pce, kg, L, m…)
- Photo produit (optionnel)
- Alertes stock faible en temps réel

### 📋 Inventaire (module complet)
- Création de session d'inventaire avec snapshot du stock théorique
- Comptage produit par produit avec clavier numérique
- **Scan Bluetooth pour localiser instantanément un produit**
- Filtres : Tous / En attente / Comptés / Écarts
- Barre de progression temps réel
- Rapport d'écarts (positifs et négatifs)
- Validation avec application automatique des corrections
- Historique de toutes les sessions
- Journal d'audit complet des mouvements

### 📊 Rapports & Analytics
- Tableau de bord du jour (CA, nombre de ventes, panier moyen, taxes)
- Graphique barres sur 7 jours (fl_chart)
- Top 10 produits les plus vendus (30 jours)
- Historique des ventes avec filtres date

### 👥 Clients & Fidélité
- Fichier clients (nom, téléphone, email)
- Programme de points de fidélité automatique
- Historique des achats par client

### ⚙️ Paramètres
- Infos magasin (nom, adresse, téléphone)
- Configuration imprimante Bluetooth
- Message de pied de reçu personnalisé
- Gestion des devises et taux de taxe par défaut
- Export CSV
- Sauvegarde de la base de données

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/    # AppConstants
│   ├── di/           # Injection de dépendances (get_it)
│   ├── theme/        # AppTheme, AppColors
│   └── utils/        # CurrencyUtils, DateUtils, RefGenerator
│
├── data/
│   ├── database/     # pos_database.dart (Drift/SQLite)
│   └── services/     # receipt_service.dart (ESC/POS Bluetooth)
│
└── presentation/
    ├── blocs/        # PosBloc, ProductsBloc, InventoryBloc
    ├── screens/
    │   ├── pos/          # Écran caisse + dialog paiement
    │   ├── products/     # Catalogue + formulaire produit
    │   ├── inventory/    # Liste sessions + session detail
    │   ├── reports/      # Dashboard + graphiques
    │   ├── customers/    # Gestion clients
    │   ├── sales/        # Historique ventes
    │   └── settings/     # Configuration
    └── widgets/      # Widgets partagés (StatCard, NumPad…)
```

### Couches (Clean Architecture)
```
Présentation (BLoC) ←→ Domaine (Use Cases) ←→ Données (Drift/SQLite)
```

---

## 🚀 Installation

### Prérequis
- Flutter 3.16+
- Dart 3.2+

### 1. Cloner et installer
```bash
git clone <repo>
cd pos_system
flutter pub get
```

### 2. Générer le code Drift
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurer les permissions

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<!-- Bluetooth pour Android 11 et inférieur -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Bluetooth pour Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />

<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>Scanner les codes-barres des produits</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connexion à l'imprimante thermique</string>
```

### 4. Lancer l'application
```bash
# Android/iOS
flutter run

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

---

## 📱 Imprimante Bluetooth

### Imprimantes testées et compatibles
| Modèle | Type | Connexion |
|--------|------|-----------|
| EPSON TM-T20III | Thermique 80mm | BT/USB |
| Xprinter XP-58 | Thermique 58mm | BT |
| MUNBYN ITPP047 | Thermique 80mm | BT |
| Star TSP143III | Thermique 80mm | BT |

### Configuration
1. Allumer l'imprimante et l'appairer en Bluetooth avec le téléphone
2. Dans l'app : **Paramètres → Imprimante Bluetooth → Connecter**
3. Sélectionner l'imprimante dans la liste

---

## 🗄️ Base de données SQLite

### Tables principales
| Table | Description |
|-------|-------------|
| `users` | Utilisateurs et PIN (rôles: admin, manager, caissier) |
| `categories` | Catégories de produits |
| `products` | Catalogue avec prix, stock, barcode |
| `customers` | Clients et fidélité |
| `sales` | En-têtes de ventes |
| `sale_items` | Lignes (snapshot prix/nom) |
| `payments` | Paiements multi-modes |
| `stock_movements` | Journal d'audit complet |
| `receipts` | Reçus sérialisés (réimpression) |
| `inventory_sessions` | Sessions d'inventaire |
| `inventory_lines` | Lignes de comptage |
| `app_settings` | Configuration clé/valeur |

### Emplacement de la base
- **Android/iOS** : `getApplicationDocumentsDirectory()/pos_v1.db`
- **Windows** : `%APPDATA%/pos_v1.db`
- **macOS** : `~/Library/Application Support/pos_v1.db`

---

## 🔄 Flux d'inventaire

```
1. Créer session     → Snapshot de tous les stocks théoriques
2. Compter           → Saisir les quantités réelles (scan ou manuel)
3. Vérifier écarts   → Vue filtrée des différences
4. Valider           → Application des corrections + journal audit
```

Les stocks non comptés ne sont pas corrigés.  
Chaque correction génère un mouvement de type `inventory` dans `stock_movements`.

---

## 🛠️ Développement futur

- [ ] Synchronisation cloud (API REST)
- [ ] Multi-magasins
- [ ] Rapports PDF exportables
- [ ] Code-barres QR pour reçus numériques (WhatsApp/Email)
- [ ] Gestion des fournisseurs et bons de commande
- [ ] Module de comptabilité simplifié
- [ ] Authentification PIN à l'ouverture de session
- [ ] Mode démo / formation

---

## 🚀 Déploiement (Release)

### Android
1. Générer un Keystore : `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Configurer `android/key.properties`.
3. Compiler l'APK :
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Windows
1. Compiler la version Release :
```bash
flutter build windows --release
```
2. Le livrable se trouve dans `build\windows\x64\runner\Release`.
3. Utiliser **Inno Setup** pour packager le dossier en un seul installeur `.exe`.

### Base de données Cloud
Avant tout déploiement, assurez-vous d'avoir exécuté `lib/supabase_setup.sql` sur votre instance Supabase de production pour :
- Créer les tables et les extensions UUID.
- Activer la sécurité RLS.
- Déployer les fonctions RPC pour les statistiques et le stock.

---

## � Support

Développé avec Flutter + Drift (SQLite)  
Architecture : Clean Architecture + BLoC  
Cible : Commerces d'Afrique de l'Ouest (devise FCFA, TVA configurable)
