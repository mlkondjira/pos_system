// lib/presentation/widgets/stock_prediction_card.dart
// ============================================================
//  Widget — Carte de prédiction de rupture de stock
//  Affiché dans : ReportsScreen, ProduitsScreen (badge)
// ============================================================
import 'package:flutter/material.dart';
import '../../core/services/stock_predictor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../data/database/pos_database.dart';

// Note: La classe StockPredictionPanel a été déplacée dans son propre fichier.

// ── CARTE INDIVIDUELLE ────────────────────────────────────────

class StockPredictionCard extends StatelessWidget {
  final StockPrediction prediction;
  const StockPredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(prediction.level);
    final icon = _levelIcon(prediction.level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prediction.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _LevelBadge(prediction: prediction, color: color),
            ],
          ),

          const SizedBox(height: 10),

          // Métriques
          Row(
            children: [
              _Metric(
                label: 'Stock',
                value: '${prediction.currentStock}',
                color: prediction.currentStock <= prediction.stockAlert
                    ? AppColors.danger
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              _Metric(
                label: 'Ventes/jour',
                value: prediction.dailySalesRate > 0
                    ? prediction.dailySalesRate.toStringAsFixed(1)
                    : '—',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              if (prediction.daysUntilStockout != null)
                _Metric(
                  label: 'Rupture dans',
                  value: '${prediction.daysUntilStockout} j',
                  color: color,
                ),
            ],
          ),

          // Barre de progression stock
          const SizedBox(height: 10),
          _StockBar(prediction: prediction, color: color),

          // Suggestion de commande
          if (prediction.suggestedOrderQty > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Commander ${prediction.suggestedOrderQty} unités (30j de couverture)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Confidence indicator
          const SizedBox(height: 4),
          _ConfidenceRow(confidence: prediction.confidence),
        ],
      ),
    );
  }

  Color _levelColor(PredictionLevel level) {
    switch (level) {
      case PredictionLevel.outOfStock:
        return AppColors.danger;
      case PredictionLevel.critical:
        return AppColors.danger;
      case PredictionLevel.warning:
        return AppColors.warning;
      case PredictionLevel.alert:
        return AppColors.warning;
      case PredictionLevel.ok:
        return AppColors.success;
    }
  }

  IconData _levelIcon(PredictionLevel level) {
    switch (level) {
      case PredictionLevel.outOfStock:
        return Icons.inventory_2_outlined;
      case PredictionLevel.critical:
        return Icons.warning_amber_rounded;
      case PredictionLevel.warning:
        return Icons.access_time_rounded;
      case PredictionLevel.alert:
        return Icons.notifications_outlined;
      case PredictionLevel.ok:
        return Icons.check_circle_outline;
    }
  }
}

class _LevelBadge extends StatelessWidget {
  final StockPrediction prediction;
  final Color color;
  const _LevelBadge({required this.prediction, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        prediction.levelLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ],
    );
  }
}

class _StockBar extends StatelessWidget {
  final StockPrediction prediction;
  final Color color;
  const _StockBar({required this.prediction, required this.color});

  @override
  Widget build(BuildContext context) {
    // On considère 200% du seuil d'alerte comme "plein"
    final max = (prediction.stockAlert * 2).clamp(1, 999999);
    final progress = (prediction.currentStock / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stock actuel',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            Text(
              '${prediction.currentStock} / seuil ${prediction.stockAlert}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  final PredictionConfidence confidence;
  const _ConfidenceRow({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final labels = {
      PredictionConfidence.high: ('Haute précision', AppColors.success),
      PredictionConfidence.medium: ('Précision moyenne', AppColors.warning),
      PredictionConfidence.low: ('Données insuffisantes', AppColors.textMuted),
    };
    final (label, color) = labels[confidence]!;

    return Row(
      children: [
        Icon(Icons.analytics_outlined, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

// ── WIDGET BADGE COMPACT (pour le SideRail) ───────────────────

class StockPredictionBadge extends StatelessWidget {
  const StockPredictionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StockPrediction>>(
      future: StockPredictor(getIt<PosDatabase>()).analyzeAll(onlyAtRisk: true),
      builder: (context, snap) {
        final critical = (snap.data ?? [])
            .where(
              (p) =>
                  p.level == PredictionLevel.critical ||
                  p.level == PredictionLevel.outOfStock,
            )
            .length;

        if (critical == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$critical',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
