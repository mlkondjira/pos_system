// lib/core/extensions/context_extensions.dart
// ============================================================
//  Extensions sur BuildContext pour simplifier l'i18n
//  Usage : context.l10n.cashier_title
//          context.l10n.login_hello('Amadou')
// ============================================================
import 'package:flutter/material.dart'; //
import 'package:pos_system/core/l10n/app_localizations.dart'; // Chemin corrigé

extension LocalizationExtension on BuildContext {
  /// Accès rapide aux traductions
  /// Exemple : context.l10n.cashier_empty_cart
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension ThemeExtension on BuildContext {
  /// Accès rapide au thème
  ThemeData get theme => Theme.of(this);

  /// Accès rapide à la locale actuelle
  Locale get locale => Localizations.localeOf(this);

  /// Vrai si la locale est RTL (arabe, hébreu, etc.)
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
