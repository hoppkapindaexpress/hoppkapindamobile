import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography sistemi.
///
/// SF Pro / Inter estetiğine en yakın, ücretsiz ve yüksek okunabilirlikte
/// olan "Plus Jakarta Sans" kullanılır. Tek noktadan değiştirilebilir:
/// [_fontFamily] fonksiyonunu güncellemek tüm uygulamayı etkiler.
abstract final class AppTypography {
  AppTypography._();

  static TextStyle _base(
    double size,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textDark,
    );
  }

  // ---- Display / Başlıklar ----
  static TextStyle get displayLarge =>
      _base(34, FontWeight.w800, height: 1.15, letterSpacing: -0.5);
  static TextStyle get displayMedium =>
      _base(28, FontWeight.w800, height: 1.18, letterSpacing: -0.4);

  static TextStyle get headlineLarge =>
      _base(24, FontWeight.w700, height: 1.2, letterSpacing: -0.3);
  static TextStyle get headlineMedium =>
      _base(20, FontWeight.w700, height: 1.25, letterSpacing: -0.2);
  static TextStyle get headlineSmall =>
      _base(18, FontWeight.w700, height: 1.3);

  // ---- Title / Alt başlıklar ----
  static TextStyle get titleLarge =>
      _base(17, FontWeight.w600, height: 1.3);
  static TextStyle get titleMedium =>
      _base(15, FontWeight.w600, height: 1.35);
  static TextStyle get titleSmall =>
      _base(13, FontWeight.w600, height: 1.4);

  // ---- Body / Gövde ----
  static TextStyle get bodyLarge =>
      _base(16, FontWeight.w400, height: 1.5, color: AppColors.textDark);
  static TextStyle get bodyMedium =>
      _base(14, FontWeight.w400, height: 1.5, color: AppColors.textMuted);
  static TextStyle get bodySmall =>
      _base(12, FontWeight.w400, height: 1.45, color: AppColors.textMuted);

  // ---- Label / Etiket ----
  static TextStyle get labelLarge =>
      _base(15, FontWeight.w600, height: 1.2, letterSpacing: 0.1);
  static TextStyle get labelMedium =>
      _base(13, FontWeight.w600, height: 1.2, letterSpacing: 0.2);
  static TextStyle get labelSmall =>
      _base(11, FontWeight.w600, height: 1.2, letterSpacing: 0.3);

  /// Fiyat etiketleri için özel stil (tabular figures hissi).
  static TextStyle get price =>
      _base(16, FontWeight.w800, letterSpacing: -0.2);
}
