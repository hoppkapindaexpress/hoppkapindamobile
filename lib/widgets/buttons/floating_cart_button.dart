import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Ekranın altında yüzen sepet butonu.
///
/// [itemCount] > 0 olduğunda animasyonla belirir ve toplam tutarı gösterir.
class FloatingCartButton extends StatelessWidget {
  const FloatingCartButton({
    super.key,
    required this.itemCount,
    required this.total,
    this.onTap,
  });

  final int itemCount;
  final double total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: itemCount > 0 ? Offset.zero : const Offset(0, 2),
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: itemCount > 0 ? 1 : 0,
        duration: AppDurations.fast,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: AppRadius.lgAll,
              boxShadow: AppShadows.brandGlow,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_bag_rounded,
                        color: AppColors.textOnPrimary, size: 26),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$itemCount',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.textOnPrimary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Sepeti Görüntüle',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textOnPrimary)),
                const Spacer(),
                Text('₺${total.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.textOnPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
