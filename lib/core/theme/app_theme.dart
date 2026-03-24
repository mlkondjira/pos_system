// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── PALETTE PRINCIPALE ────────────────────────────────────
  static const primary      = Color(0xFF6366F1); // Indigo vibrant
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark  = Color(0xFF4F46E5);

  static const accent     = Color(0xFF8B5CF6); // Violet
  static const accentSoft = Color(0x338B5CF6);
  static const accentDark = Color(0xFF7C3AED);

  // ── FONDS DÉGRADÉ (identique à la démo Liquid Glass) ─────
  // Fond violet/bleu intense — même ambiance qu'iOS 26
  static const bg              = Color(0xFF667EEA); // Couleur solide fallback
  static const bgGradientStart = Color(0xFF667EEA); // Indigo clair
  static const bgGradientEnd   = Color(0xFF764BA2); // Violet profond

  // Pour certains écrans (caisse, produits) on utilise un 2e dégradé
  // plus subtil afin que le contenu reste lisible
  static const bgSoftStart = Color(0xFFF0F4FF); // Très clair pour les listes
  static const bgSoftEnd   = Color(0xFFE8EEFF);

  // Surfaces vitrées (Liquid Glass)
  static const surface      = Color(0xB3FFFFFF); // Blanc 70%
  static const surfaceLight = Color(0x80FFFFFF); // Blanc 50%
  static const surfaceCard  = Color(0x33FFFFFF); // Blanc 20% (Glass effect prononcé)
  static const card         = surfaceCard;

  static const border = Color(0x4DFFFFFF); // Bordure blanche subtile

  // ── TEXTE ─────────────────────────────────────────────────
  // Sur fond sombre on utilise blanc, sur fond clair on utilise foncé
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted     = Color(0xFF94A3B8);
  // Version claire pour texte sur fond coloré/sombre
  static const textOnDark       = Color(0xFFFFFFFF);
  static const textOnDarkMuted  = Color(0xCCFFFFFF); // blanc 80%

  // ── ÉTATS ─────────────────────────────────────────────────
  static const success     = Color(0xFF10B981);
  static const successSoft = Color(0x3310B981);
  static const warning     = Color(0xFFF59E0B);
  static const warningSoft = Color(0x33F59E0B);
  static const danger      = Color(0xFFEF4444);
  static const dangerSoft  = Color(0x33EF4444);
  static const info        = Color(0xFF3B82F6);
  static const infoSoft    = Color(0x333B82F6);

  // ── DÉGRADÉS PRÊTS À L'EMPLOI ─────────────────────────────
  // Dégradé principal (fond app)
  static const gradientMain = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA), // Indigo
      Color(0xFF764BA2), // Violet
      Color(0xFFF093FB), // Rose clair (optionnel, voir ci-dessous)
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Dégradé version courte sans rose (plus sobre)
  static const gradientSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
    ],
  );

  // Dégradé pour les écrans de contenu (liste produits, etc.)
  static const gradientContent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0F4FF),
      Color(0xFFE8EEFF),
    ],
  );
}

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bgGradientStart,
    fontFamily: 'Inter',

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      // Teinte générale du thème
      primaryContainer: AppColors.primary.withValues(alpha: 0.12),
      onPrimaryContainer: AppColors.primary,
    ),

    // Cartes avec effet verre
    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // Champs texte glass
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.danger,
          width: 1.5,
        ),
      ),
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
      ),
    ),

    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),

    iconTheme: IconThemeData(
      color: Colors.white.withValues(alpha: 0.9),
    ),

    // Dialogues glass
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      textStyle: const TextStyle(color: AppColors.textPrimary),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalBackgroundColor: Colors.white.withValues(alpha: 0.88),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        side: BorderSide(color: Colors.white, width: 1),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      contentTextStyle: const TextStyle(
        color: AppColors.textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      selectedColor: Colors.white.withValues(alpha: 0.45),
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.45),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  static final ThemeData glass = light;
}