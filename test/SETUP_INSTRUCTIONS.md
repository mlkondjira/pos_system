# ============================================================
#  INSTRUCTIONS — Intégrer les tests dans GPOS
# ============================================================

# ── ÉTAPE 1 : Copier les fichiers ─────────────────────────────
# Copier les 4 fichiers dans ton projet :
#
# test/unit/test_helpers.dart
# test/unit/promotion_engine_test.dart
# test/unit/cart_state_test.dart
# test/unit/sync_service_test.dart

# ── ÉTAPE 2 : Vérifier pubspec.yaml ───────────────────────────
# Ces dépendances sont déjà dans ton pubspec.yaml :

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

# Ajouter si absent :
  mockito: ^5.4.4
  build_runner: ^2.12.2  # déjà présent

# ── ÉTAPE 3 : Corriger sync_service.dart ──────────────────────
# Les tests sync_service_test.dart testent la logique pure.
# Pour les faire compiler, ajouter dans SyncService :
#
# // Expose pour les tests (à la fin du fichier)
# @visibleForTesting
# String tableForTest(String entityType) => _tableFor(entityType);
#
# @visibleForTesting
# String generateShopIdTest() => _generateShopId();

# ── ÉTAPE 4 : Lancer les tests ────────────────────────────────

# Lancer tous les tests unitaires :
# flutter test test/unit/

# Lancer un fichier spécifique :
# flutter test test/unit/promotion_engine_test.dart

# Lancer avec coverage :
# flutter test --coverage test/unit/
# genhtml coverage/lcov.info -o coverage/html

# Lancer avec verbose (voir chaque test) :
# flutter test test/unit/ --reporter=expanded

# ── RÉSULTATS ATTENDUS ─────────────────────────────────────────
# promotion_engine_test.dart  : 17 tests
# cart_state_test.dart        : 22 tests
# sync_service_test.dart      : 18 tests
# Total                       : 57 tests

# ── ÉTAPE 5 : Intégrer dans GitHub Actions ────────────────────
# Déplacer .github/workflows/release_android.yml (actuellement
# dans lib/) vers .github/workflows/ et ajouter ce step :
#
# - name: Run unit tests
#   run: flutter test test/unit/ --reporter=github
