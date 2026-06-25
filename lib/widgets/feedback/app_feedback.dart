import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Shimmer efektli yükleme iskeleti kutusu.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      highlightColor:
          isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Tipik ürün kartı yükleme iskeleti.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(height: 90, radius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: 120),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 70, height: 12),
        ],
      ),
    );
  }
}

/// Boş durum (empty state) görünümü.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Filtre / etiket chip'i (seçilebilir).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.card),
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected ? AppShadows.brandGlow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? AppColors.textOnPrimary : AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? AppColors.textOnPrimary : AppColors.textDark,
                )),
          ],
        ),
      ),
    );
  }
}

/// Toast / SnackBar yardımcıları — tutarlı bildirimler için.
abstract final class AppToast {
  AppToast._();

  static void show(BuildContext context, String message, {IconData? icon}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.secondaryLight, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, icon: Icons.check_circle_rounded);
}
