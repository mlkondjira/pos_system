// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Fmt {
  /// Formate un montant monétaire
  static String currency(double amount, {String? symbol}) {
    final sym = symbol ?? AppConstants.defaultCurrencySymbol;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $sym';
    }
    final n = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$n $sym';
  }

  /// Format date DD/MM/YYYY
  static String date(DateTime dt) =>
      DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);

  /// Format date + heure
  static String dateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt);

  /// Format heure seule
  static String time(DateTime dt) =>
      DateFormat('HH:mm', 'fr_FR').format(dt);

  /// Génère une référence de vente unique
  static String saleRef() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch % 100000;
    return 'VTE-${now.year}${_p(now.month)}${_p(now.day)}'
        '-${ts.toString().padLeft(5, '0')}';
  }

  /// Génère une référence d'inventaire unique
  static String inventoryRef() {
    final now = DateTime.now();
    return 'INV-${now.year}${_p(now.month)}${_p(now.day)}'
        '-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
  }

  /// Formate un pourcentage
  static String percent(double v) => '${(v * 100).toStringAsFixed(1)}%';

  /// Formate quantité + unité
  static String qty(int qty, String unit) => '$qty $unit';

  /// Libellé mode de paiement
  static String paymentMethod(String method) => switch (method) {
        'cash' => 'Espèces',
        'card' => 'Carte bancaire',
        'mobile_money' => 'Mobile Money',
        'wave' => 'Wave',
        'orange_money' => 'Orange Money',
        'credit' => 'Crédit',
        _ => method,
      };

  static String _p(int n) => n.toString().padLeft(2, '0');
}
