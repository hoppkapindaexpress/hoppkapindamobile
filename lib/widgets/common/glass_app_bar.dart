import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Buzlu cam (glassmorphism) efektli app bar.
///
/// Arka plandaki içeriği bulanıklaştırarak premium derinlik hissi verir.
/// Genellikle restoran detay gibi kapak görseli üzerinde kullanılır.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.blur = 18,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double blur;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            border: Border(
              bottom: BorderSide(color: AppColors.glassStroke, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.xs),
                  leading ?? const _GlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  if (title != null)
                    Expanded(
                      child: Text(title!,
                          style: AppTypography.headlineSmall
                              .copyWith(color: AppColors.textOnPrimary)),
                    )
                  else
                    const Spacer(),
                  if (actions != null) ...actions!,
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnPrimary, size: 18),
      ),
    );
  }
}

/// Kampanya / kupon banner'ı — Home ve sepet ekranlarında kullanılır.
class OfferBanner extends StatelessWidget {
  const OfferBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel = 'Keşfet',
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: AppRadius.xlAll,
          boxShadow: AppShadows.brandGlow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.headlineMedium
                        .copyWith(color: AppColors.textOnPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(actionLabel,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
