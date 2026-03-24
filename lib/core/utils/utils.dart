// lib/core/utils/utils.dart
// Re-export formatters for screens using the old utils import
export 'formatters.dart';

// Aliases pour compatibilité avec les screens qui utilisent CurrencyUtils/DateUtils2
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyUtils {
  static String format(double amount) {
    final f = NumberFormat('#,##0', 'fr_FR');
    return '${f.format(amount)} ${AppConstants.defaultCurrency}';
  }

  static String formatCompact(double amount) {
    final f = NumberFormat('#,##0', 'fr_FR');
    return '${f.format(amount)} ${AppConstants.defaultCurrencySymbol}';
  }
}

class DateUtils2 {
  static String formatDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

  static String formatDateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(d);

  static String formatTime(DateTime d) =>
      DateFormat('HH:mm', 'fr_FR').format(d);
}
