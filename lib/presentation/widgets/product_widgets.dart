import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/pos_database.dart';

/// Badge intelligent qui change de couleur selon l'état du stock.
class StockBadge extends StatelessWidget {
  final Product product;

  const StockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (product.isOutOfStock) {
      color = AppColors.danger;
      label = 'Rupture';
    } else if (product.isLowStock) {
      color = AppColors.warning;
      label = '${product.stockQty} ${product.unit}';
    } else {
      color = AppColors.success;
      label = '${product.stockQty} ${product.unit}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color, 
          fontSize: 11, 
          fontWeight: FontWeight.w700
        ),
      ),
    );
  }
}

/// Affiche le prix TTC formaté en utilisant l'extension sécurisée.
class ProductPriceText extends StatelessWidget {
  final Product product;
  final TextStyle? style;

  const ProductPriceText({super.key, required this.product, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      Fmt.currency(product.priceTtc),
      style: style ?? const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
    );
  }
}