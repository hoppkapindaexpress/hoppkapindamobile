import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tasarım token'ları — boşluk, köşe yarıçapı ve gölge ölçeği.
///
/// Premium spacing sistemi: 4'ün katları temel alınır.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Ekran kenar boşluğu — sayfaların standart yatay padding'i.
  static const double screenPadding = 20;
}

/// Köşe yarıçapı ölçeği — rounded corners tasarım diline uygun.
abstract final class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Soft shadow sistemi — premium derinlik için yumuşak gölgeler.
abstract final class AppShadows {
  AppShadows._();

  /// Kartlar için hafif gölge.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0F1E1E1E),
      blurRadius: 18,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Yükseltilmiş / floating elemanlar için.
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x141E1E1E),
      blurRadius: 28,
      offset: Offset(0, 14),
      spreadRadius: -6,
    ),
  ];

  /// Marka renkli gölge — primary butonlar için renkli halo.
  static const List<BoxShadow> brandGlow = [
    BoxShadow(
      color: Color(0x405A00D6),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  /// Turuncu CTA gölgesi.
  static const List<BoxShadow> accentGlow = [
    BoxShadow(
      color: Color(0x40FF7A00),
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];
}

/// Animasyon süreleri — tutarlı motion için.
abstract final class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration page = Duration(milliseconds: 350);
}

/// Glassmorphism efekti için yardımcı dekorasyon.
abstract final class AppGlass {
  AppGlass._();

  static BoxDecoration decoration({double radius = AppRadius.lg}) =>
      BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassStroke, width: 1),
      );
}
