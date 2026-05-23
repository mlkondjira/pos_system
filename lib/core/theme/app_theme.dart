// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── PALETTE PRINCIPALE ────────────────────────────────────
  static const primary = Color(0xFF007AFF); // Bleu du logo
  static const primaryLight = Color(0xFFCCE5FF); // Nuance claire du bleu
  static const primaryDark = Color(0xFF005BBF); // Nuance foncée du bleu

  static const warmAccent = Color(0xFFFFB800); // Jaune alerte
  static const roseAccent = Color(0xFFD82C0D); // Rouge erreur
  static const accent = Color(0xFF9333EA);
  static const accentSoft = Color(0x1A9333EA); // Violet translucide
  static const accentDark = Color(0xFF7E22CE); // Violet profond

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark], // Utilise les nouvelles nuances de bleu
  );

  // ── FONDS SHOPIFY ───────────────────────────────────
  static const bg = Color(0xFFF6F6F7); // Gris Shopify standard
  static const bgGradientStart = Color(0xFFF6F6F7);
  static const bgGradientEnd = Color(0xFFEDEEEF);

  // Pour certains écrans (caisse, produits) on utilise un 2e dégradé
  static const bgSoftStart = Color(0xFFFFFFFF);
  static const bgSoftEnd = Color(0xFFF8FAFC);

  // Surfaces vitrées (Liquid Glass)
  static const surface = Color(0xE6FFFFFF); // Blanc 90% pour plus de lisibilité
  static const surfaceLight = Color(0x99FFFFFF); // Blanc 60%
  static Color surfaceCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1A1C1D)
      : const Color(0xFFFFFFFF);
  static const card = Colors.white;

  static const border = Color(0xFFEEEFF1); // Bordure plus subtile
  static const borderDark = Color(0xFFC9CCCF);
  static const glassBorder = Color(
    0x66FFFFFF,
  ); // Bordure de lumière plus marquée
  static const glassHighlight = Color(0x4DFFFFFF); // Reflet sur le dessus
  static const softShadow = Color(0x1A007AFF); // Ombre du nouveau bleu

  static const shadow = Color(0x0A000000);

  // ── TEXTE ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFF202223); // Ink (Presque noir)
  static const textSecondary = Color(0xFF6D7175); // Grey
  static const textMuted = Color(0xFF8C9196); // Silver

  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkMuted = Color(0xCCFFFFFF); // blanc 80%

  // ── ÉTATS ─────────────────────────────────────────────────
  static const success = Color(0xFF10B981); // Émeraude premium
  static const successSoft = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF59E0B); // Ambre
  static const warningSoft = Color(0x33F59E0B);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFF8686);
  static const dangerSoft = Color(0x33EF4444);
  static const info = Color(0xFF5479F7);
  static const infoSoft = Color(0x335479F7);

  // ── DÉGRADÉS PRÊTS À L'EMPLOI ─────────────────────────────
  static LinearGradient gradientMain(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF0F172A),
              const Color(0xFF1E1B4B),
            ] // Nuit profonde vers Bleu nuit
          : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
    );
  }

  static const gradientSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // Dégradé pour les écrans de contenu (liste produits, etc.)
  static const gradientContent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0F4FF), Color(0xFFE8EEFF)],
  );
}

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light, // Toujours clair pour "Clean Glass"
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.primary,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0, // Design plat moderne
      shadowColor: const Color(0x0F000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE2E8F0), // Bordure un peu plus affirmée
          width: 0.8,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // Champs texte glass
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgGradientEnd.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: AppColors.textMuted,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 22, // Hauteur massive type Shopify POS
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800, // Texte très clair et affirmé
              letterSpacing: 0.5,
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primaryDark;
              }
              return AppColors.primary;
            }),
          ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),

    iconTheme: const IconThemeData(color: AppColors.textSecondary),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8, // Plus sobre et moderne
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w900, // Titre très affirmé
        letterSpacing: -0.5,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // Espace réduit
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      elevation: 8,
      textStyle: TextStyle(color: AppColors.textPrimary),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Colors.white, width: 1),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  static final ThemeData glass = light;

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF0B0C0D), // Fond plus profond
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Color(0xFF1A1C1D),
      onSurface: Color(0xFFE3E3E3),
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary, // Ligne 214
      selectionColor: AppColors.primary.withValues(alpha: 0.4),
      selectionHandleColor: AppColors.primary,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1C1D),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2F3133), width: 0.8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // Ligne 230
      fillColor: const Color(0xFF1A1C1D).withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18), // Harmonisation Premium
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF242627), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2.0, // Épaisseur augmentée pour une meilleure visibilité
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(
        color: Color(0xFFB1B3B5),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: Color(0xFF8C9196)),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      prefixIconColor: const Color(0xFF8C9196),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1C1D),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2F3133), width: 0.8),
      ),
      titleTextStyle: const TextStyle(
        color: Color(0xFFE3E3E3),
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
      contentTextStyle: const TextStyle(color: Color(0xFFB1B3B5), fontSize: 13),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1A1C1D),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF202223),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF202223),
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(color: Colors.white),
      side: const BorderSide(color: Color(0xFF2F3133)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
