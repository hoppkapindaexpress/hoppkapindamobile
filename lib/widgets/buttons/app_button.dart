import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Buton görsel varyantları.
enum AppButtonVariant { primary, secondary, gradient, outline, ghost }

/// Hopp Kapında ortak butonu.
///
/// - Basıldığında hafif "scale down" mikro-etkileşimi yapar.
/// - [loading] true iken spinner gösterir ve tıklamayı kilitler.
/// - Tüm varyantlar tek widget'tan türetilir (DRY).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final double height;

  bool get _enabled => onPressed != null && !loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget._enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget._enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget._enabled ? 1 : 0.5,
          duration: AppDurations.fast,
          child: Container(
            height: widget.height,
            width: widget.expanded ? double.infinity : null,
            padding: widget.expanded
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: _decoration(isDark),
            alignment: Alignment.center,
            child: _content(isDark),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.mdAll,
          boxShadow: widget._enabled ? AppShadows.brandGlow : null,
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: AppColors.secondary,
          borderRadius: AppRadius.mdAll,
          boxShadow: widget._enabled ? AppShadows.accentGlow : null,
        );
      case AppButtonVariant.gradient:
        return BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppRadius.mdAll,
          boxShadow: widget._enabled ? AppShadows.brandGlow : null,
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.primary, width: 1.6),
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.surfaceVariant,
          borderRadius: AppRadius.mdAll,
        );
    }
  }

  Color get _foreground {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.gradient:
        return AppColors.textOnPrimary;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  Widget _content(bool isDark) {
    if (widget.loading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation(_foreground),
        ),
      );
    }

    final textStyle = AppTypography.labelLarge.copyWith(color: _foreground);
    if (widget.icon == null) {
      return Text(widget.label, style: textStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: 20, color: _foreground),
        const SizedBox(width: AppSpacing.xs),
        Text(widget.label, style: textStyle),
      ],
    );
  }
}
