import 'package:flutter/material.dart';

/// Hopp Kapında — Marka renk paleti.
///
/// Tüm renkler tek bir yerden yönetilir. Yeni bir renk gerektiğinde
/// doğrudan widget içine hex yazmak yerine buraya eklenir.
abstract final class AppColors {
  AppColors._();

  // ---- Marka (Brand) ----
  /// Primary Purple — ana marka rengi.
  static const Color primary = Color(0xFF5A00D6);
  static const Color primaryDark = Color(0xFF4400A8);
  static const Color primaryLight = Color(0xFF7B3BE0);

  /// Secondary Orange — vurgu / CTA aksanı.
  static const Color secondary = Color(0xFFFF7A00);
  static const Color secondaryDark = Color(0xFFE56A00);
  static const Color secondaryLight = Color(0xFFFF9838);

  // ---- Yüzeyler (Surfaces) ----
  static const Color background = Color(0xFFF8F8FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F1F5);

  // ---- Metin (Text) ----
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF6B6B72);
  static const Color softGray = Color(0xFFA0A0A0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---- Durum (State) ----
  static const Color success = Color(0xFF1FB85F);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF2D7FF9);

  // ---- Kenarlık & Çizgi ----
  static const Color border = Color(0xFFEAEAEF);
  static const Color divider = Color(0xFFF0F0F4);

  // ---- Dark Mode yüzeyleri ----
  static const Color darkBackground = Color(0xFF121016);
  static const Color darkCard = Color(0xFF1C1A22);
  static const Color darkSurfaceVariant = Color(0xFF262430);
  static const Color darkTextDark = Color(0xFFF4F4F6);
  static const Color darkTextMuted = Color(0xFFA4A2AD);
  static const Color darkBorder = Color(0xFF2E2C38);

  // ---- Gradyanlar ----
  /// Marka gradyanı — splash, butonlar ve hero alanları için.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6E12E0), Color(0xFF5A00D6)],
  );

  /// Purple → Orange geçişi — kampanya / öne çıkan alanlar için.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A00D6), Color(0xFF9B30FF), Color(0xFFFF7A00)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Sıcak vurgu gradyanı — tatlı / kampanya rozetleri.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF7A00), Color(0xFFFF9838)],
  );

  /// Turuncu → mor ters gradyan (onboarding 3. sayfa vb.).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A00), Color(0xFF5A00D6)],
  );

  /// Glassmorphism overlay için yarı saydam beyaz.
  static const Color glassFill = Color(0x4DFFFFFF);
  static const Color glassStroke = Color(0x66FFFFFF);
}
