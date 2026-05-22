import 'dart:convert';
import 'dart:math';
import '../../presentation/blocs/cart_bloc.dart';

import '../../data/database/pos_database.dart';

class PromotionEngine {
  /// Évalue les promotions et retourne les remises à appliquer par article
  static List<CartItem> applyPromotions(
    List<CartItem> items,
    List<Discount> activeDiscounts,
  ) {
    // On trie les remises par priorité
    final List<dynamic> sortedDiscounts = List.from(activeDiscounts);
    sortedDiscounts.sort((a, b) {
      final int pA = (a.priority as int?) ?? 0;
      final int pB = (b.priority as int?) ?? 0;
      return pB.compareTo(pA);
    });

    var processedItems = List<CartItem>.from(items);
    final now = DateTime.now();

    for (final discount in sortedDiscounts) {
      if (!discount.isActive || discount.isArchived) continue;

      // Vérification des dates
      if (discount.startDate != null && now.isBefore(discount.startDate!)) {
        continue;
      }
      if (discount.endDate != null && now.isAfter(discount.endDate!)) continue;

      final rules = discount.rules != null ? jsonDecode(discount.rules!) : null;

      processedItems = processedItems.map((item) {
        double currentAutoPct = item.autoDiscountPct;

        // 1. Règle "Buy X Get Y" (BXGY)
        if (rules?['type'] == 'bxgy') {
          final buyQty = (rules['buy_qty'] as num?)?.toInt() ?? 0;
          final getQty = (rules['get_qty'] as num?)?.toInt() ?? 0;
          final targetProductId = rules['product_id'] as int?;

          if (buyQty > 0 && getQty > 0) {
            if (targetProductId == null || item.productId == targetProductId) {
              if (item.quantity >= buyQty + getQty) {
                final sets = item.quantity ~/ (buyQty + getQty);
                final discountVal = (sets * getQty * item.priceTtc);
                final pctEquivalent =
                    (discountVal / (item.quantity * item.priceTtc)) * 100;
                currentAutoPct = max(currentAutoPct, pctEquivalent);
              }
            }
          }
        }

        // 2. Règle "Happy Hour" par créneau horaire
        if (rules?['type'] == 'happy_hour') {
          final startHour = (rules['start_hour'] as num?)?.toInt();
          final endHour = (rules['end_hour'] as num?)?.toInt();
          final categoryId = rules['category_id'] as int?;
          final pct = (rules['pct'] as num?)?.toDouble() ?? 0;

          if (startHour != null && endHour != null) {
            if (now.hour >= startHour && now.hour < endHour) {
              if (categoryId == null || item.product.categoryId == categoryId) {
                currentAutoPct = max(currentAutoPct, pct);
              }
            }
          }
        }

        // 3. Règle "Expiry Near" (Produits proches de l'expiration)
        if (rules?['type'] == 'expiry_near') {
          final thresholdDays = (rules['days'] as num?)?.toInt() ?? 7;
          final pct = (rules['pct'] as num?)?.toDouble() ?? 0;

          if (item.product.expiryDate != null) {
            final daysUntilExpiry = item.product.expiryDate!
                .difference(now)
                .inDays;
            // Appliquer si la date est comprise entre aujourd'hui et le seuil
            if (daysUntilExpiry >= 0 && daysUntilExpiry <= thresholdDays) {
              currentAutoPct = max(currentAutoPct, pct);
            }
          }
        }

        return item.copyWith(autoDiscountPct: currentAutoPct);
      }).toList();

      // Si la promo n'est pas cumulable, on s'arrête à la première promo trouvée
      if (!discount.isStackable &&
          processedItems.any((i) => i.autoDiscountPct > 0)) {
        break;
      }
    }

    return processedItems;
  }
}
