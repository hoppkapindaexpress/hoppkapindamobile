import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

/// Uygulamanın Material 3 tema tanımı (light + dark).
///
/// Tüm widget'lar mümkün olduğunca `Theme.of(context)` üzerinden okunur;
/// böylece dark mode tek satır değişiklikle çalışır.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
      error: AppColors.error,
      brightness: Brightness.light,
    ).copyWith(
      surfaceContainerLowest: AppColors.background,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurface: AppColors.textDark,
      outlineVariant: AppColors.border,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffold: AppColors.background,
      textColor: AppColors.textDark,
      mutedColor: AppColors.textMuted,
      cardColor: AppColors.card,
      borderColor: AppColors.border,
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      surface: AppColors.darkCard,
      error: AppColors.error,
      brightness: Brightness.dark,
    ).copyWith(
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurface: AppColors.darkTextDark,
      outlineVariant: AppColors.darkBorder,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffold: AppColors.darkBackground,
      textColor: AppColors.darkTextDark,
      mutedColor: AppColors.darkTextMuted,
      cardColor: AppColors.darkCard,
      borderColor: AppColors.darkBorder,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Brightness brightness,
  }) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,

      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayLarge.copyWith(color: textColor),
        displayMedium: AppTypography.displayMedium.copyWith(color: textColor),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: textColor),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: textColor),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: textColor),
        titleLarge: AppTypography.titleLarge.copyWith(color: textColor),
        titleMedium: AppTypography.titleMedium.copyWith(color: textColor),
        titleSmall: AppTypography.titleSmall.copyWith(color: textColor),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: mutedColor),
        bodySmall: AppTypography.bodySmall.copyWith(color: mutedColor),
        labelLarge: AppTypography.labelLarge.copyWith(color: textColor),
        labelMedium: AppTypography.labelMedium.copyWith(color: textColor),
        labelSmall: AppTypography.labelSmall.copyWith(color: mutedColor),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: textColor),
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium.copyWith(color: textColor),
        secondaryLabelStyle:
            AppTypography.labelMedium.copyWith(color: AppColors.textOnPrimary),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.softGray),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textColor,
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: scaffold),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
    );
  }
}
