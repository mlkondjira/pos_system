// lib/data/database/extensions.dart
// Extensions sur les entités Drift pour ajouter des getters utiles

import 'pos_database.dart';

extension InventoryLineX on InventoryLine {
  /// Écart = quantité comptée - quantité théorique
  int? get difference {
    if (countedQty == null) return null;
    return countedQty! - expectedQty;
  }
}

extension InventorySessionX on InventorySession {
  /// Nombre d'écarts (approximation — sera précis après validation)
  int get discrepancies => 0; // calculé côté UI via les lignes
}
