// lib/core/services/stock_predictor.dart
// ============================================================
//  Service de prédiction de rupture de stock
//  Algorithme : régression linéaire locale sur 30 jours
//  100% offline — aucune API externe
// ============================================================
import 'dart:math';
import '../../data/database/pos_database.dart';

// ── MODÈLES ───────────────────────────────────────────────────

/// Résultat de prédiction pour un produit
class StockPrediction {
  final int productId;
  final String productName;
  final int currentStock;
  final int stockAlert;
  final double dailySalesRate; // Unités vendues par jour (moyenne)
  final int? daysUntilStockout; // null = pas de rupture prévue
  final int? daysUntilAlert; // Jours avant passage sous le seuil d'alerte
  final DateTime? predictedStockoutDate;
  final PredictionConfidence confidence;
  final String? shopId; // AJOUTÉ
  final int? preferredSupplierId; // AJOUTÉ
  final double costPrice; // AJOUTÉ
  final String unit; // AJOUTÉ
  final List<DailyConsumption> history; // 30 jours de consommation

  const StockPrediction({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.stockAlert,
    required this.dailySalesRate,
    this.daysUntilStockout,
    this.daysUntilAlert,
    this.predictedStockoutDate,
    required this.confidence,
    this.shopId,
    this.preferredSupplierId,
    required this.costPrice,
    required this.unit,
    required this.history,
  });

  /// Niveau d'urgence
  PredictionLevel get level {
    if (currentStock <= 0) return PredictionLevel.outOfStock;
    if (daysUntilStockout != null && daysUntilStockout! <= 3) {
      return PredictionLevel.critical;
    }
    if (daysUntilStockout != null && daysUntilStockout! <= 7) {
      return PredictionLevel.warning;
    }
    if (currentStock <= stockAlert) return PredictionLevel.alert;
    return PredictionLevel.ok;
  }

  /// Quantité suggérée à commander (30 jours de couverture)
  int get suggestedOrderQty {
    if (dailySalesRate <= 0) return 0;
    final needed = (dailySalesRate * 30).ceil();
    return max(needed - currentStock, 0);
  }

  String get levelLabel {
    switch (level) {
      case PredictionLevel.outOfStock:
        return 'Épuisé';
      case PredictionLevel.critical:
        return 'Critique';
      case PredictionLevel.warning:
        return 'Attention';
      case PredictionLevel.alert:
        return 'Alerte';
      case PredictionLevel.ok:
        return 'OK';
    }
  }
}

enum PredictionLevel { outOfStock, critical, warning, alert, ok }

enum PredictionConfidence {
  high, // 20+ jours de données
  medium, // 10-19 jours
  low, // < 10 jours
}

/// Consommation journalière historique
class DailyConsumption {
  final DateTime date;
  final int qtySold;
  const DailyConsumption({required this.date, required this.qtySold});
}

// ── SERVICE PRINCIPAL ─────────────────────────────────────────

class StockPredictor {
  final PosDatabase _db;

  StockPredictor(this._db);

  // ── ANALYSE COMPLÈTE ─────────────────────────────────────

  /// Analyse tous les produits actifs et retourne les prédictions
  /// triées par urgence (les plus critiques en premier)
  Future<List<StockPrediction>> analyzeAll({
    int lookbackDays = 30,
    bool onlyAtRisk = false,
  }) async {
    // Utilisation de l'extension définie dans pos_database.dart
    final products = await _db.getActiveProducts();
    final predictions = <StockPrediction>[];

    for (final product in products) {
      final prediction = await _predictProduct(
        product: product,
        lookbackDays: lookbackDays,
      );
      if (!onlyAtRisk || prediction.level != PredictionLevel.ok) {
        predictions.add(prediction);
      }
    }

    // Trier par urgence : épuisé > critique > warning > alerte > ok
    predictions.sort((a, b) {
      final levelOrder = {
        PredictionLevel.outOfStock: 0,
        PredictionLevel.critical: 1,
        PredictionLevel.warning: 2,
        PredictionLevel.alert: 3,
        PredictionLevel.ok: 4,
      };
      final levelComp = (levelOrder[a.level] ?? 5).compareTo(
        levelOrder[b.level] ?? 5,
      );
      if (levelComp != 0) return levelComp;
      // À même niveau, trier par jours restants (moins = plus urgent)
      final aDays = a.daysUntilStockout ?? 999;
      final bDays = b.daysUntilStockout ?? 999;
      return aDays.compareTo(bDays);
    });

    return predictions;
  }

  /// Analyse un seul produit
  Future<StockPrediction> _predictProduct({
    required Product product,
    required int lookbackDays,
  }) async {
    // 1. Récupérer les mouvements de vente des N derniers jours
    final since = DateTime.now().subtract(Duration(days: lookbackDays));
    final movements = await _db.getStockMovementsForProduct(
      productId: product.id,
      since: since,
      type: 'sale',
    );

    // 2. Agréger par jour
    final dailyMap = <String, int>{};
    for (final m in movements) {
      final key = _dateKey(m.movedAt);
      // qtyDelta est négatif pour les ventes (sortie de stock)
      dailyMap[key] = (dailyMap[key] ?? 0) + m.qtyDelta.abs();
    }

    // 3. Construire la série temporelle (incluant les jours à 0 vente)
    final history = <DailyConsumption>[];
    for (var i = lookbackDays - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dateKey(date);
      history.add(DailyConsumption(date: date, qtySold: dailyMap[key] ?? 0));
    }

    // 4. Régression linéaire pour calculer la tendance
    final regression = _linearRegression(history);
    final dailyRate = regression.slope > 0
        ? regression.slope
        : _simpleMean(history); // Fallback sur la moyenne si tendance négative

    // 5. Confiance selon le nombre de jours avec des données
    final daysWithData = history.where((h) => h.qtySold > 0).length;
    final confidence = daysWithData >= 20
        ? PredictionConfidence.high
        : daysWithData >= 10
        ? PredictionConfidence.medium
        : PredictionConfidence.low;

    // 6. Calculer les jours jusqu'à rupture / alerte
    int? daysUntilStockout;
    int? daysUntilAlert;
    DateTime? predictedStockoutDate;

    if (dailyRate > 0) {
      // Jours avant épuisement complet
      final rawDays = product.stockQty / dailyRate;
      daysUntilStockout = rawDays.toInt();
      predictedStockoutDate = DateTime.now().add(
        Duration(days: daysUntilStockout),
      );

      // Jours avant passage sous le seuil d'alerte
      if (product.stockQty > product.stockAlert) {
        final daysToAlert = (product.stockQty - product.stockAlert) / dailyRate;
        daysUntilAlert = daysToAlert.floor();
      }
    }

    return StockPrediction(
      productId: product.id,
      productName: product.name,
      currentStock: product.stockQty,
      stockAlert: product.stockAlert,
      dailySalesRate: dailyRate,
      daysUntilStockout: daysUntilStockout,
      daysUntilAlert: daysUntilAlert,
      predictedStockoutDate: predictedStockoutDate,
      confidence: confidence,
      shopId: product.shopId,
      preferredSupplierId: product.preferredSupplierId,
      costPrice: product.costPrice ?? 0.0,
      unit: product.unit,
      history: history,
    );
  }

  // ── ALGORITHMES STATISTIQUES ─────────────────────────────

  /// Régression linéaire simple (moindres carrés)
  /// Retourne la pente (taux de consommation journalier)
  _RegressionResult _linearRegression(List<DailyConsumption> history) {
    if (history.isEmpty) {
      return const _RegressionResult(slope: 0, intercept: 0, r2: 0);
    }

    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = history[i].qtySold.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) {
      return _RegressionResult(slope: 0, intercept: sumY / n, r2: 0);
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // R² pour mesurer la qualité de la régression
    final meanY = sumY / n;
    double ssTot = 0, ssRes = 0;
    for (var i = 0; i < n; i++) {
      final predicted = (slope * i) + intercept;
      final actual = history[i].qtySold.toDouble();
      final diffTot = actual - meanY;
      final diffRes = actual - predicted;
      ssTot += diffTot * diffTot;
      ssRes += diffRes * diffRes;
    }
    final r2 = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;

    return _RegressionResult(slope: slope, intercept: intercept, r2: r2);
  }

  /// Moyenne simple (fallback si régression donne tendance négative)
  double _simpleMean(List<DailyConsumption> history) {
    if (history.isEmpty) return 0;
    final total = history.fold(0, (sum, h) => sum + h.qtySold);
    return total / history.length;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _RegressionResult {
  final double slope;
  final double intercept;
  final double r2;
  const _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.r2,
  });
}
