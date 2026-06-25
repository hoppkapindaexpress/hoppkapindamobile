import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Home ekranındaki büyük kategori kartı (Yemek / Tatlı / Market).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Gradient gradient;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          children: [
            // Dekoratif arka plan dairesi (glassmorphism dokunuşu).
            Positioned(
              right: -18,
              bottom: -18,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(icon,
                        color: AppColors.textOnPrimary, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.titleLarge
                              .copyWith(color: AppColors.textOnPrimary)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: AppTypography.bodySmall.copyWith(
                                color: Colors.white
                                    .withValues(alpha: 0.85))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yakındaki mağaza / restoran kartı (yatay listede kullanılır).
class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    this.deliveryFee = 'Ücretsiz',
    this.tags = const [],
    this.onTap,
  });

  final String name;
  final String imageUrl;
  final double rating;
  final String deliveryTime;
  final String deliveryFee;
  final List<String> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kapak görseli (network görsel Faz 3'te bağlanır; şimdilik
            // gradient placeholder ile premium görünür).
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white54, size: 44),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Badge(
                      icon: Icons.bolt_rounded,
                      label: deliveryTime,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium),
                      ),
                      const Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: AppTypography.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tags.isEmpty ? 'Teslimat: $deliveryFee' : tags.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondaryLight),
          const SizedBox(width: 3),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textOnPrimary)),
        ],
      ),
    );
  }
}
