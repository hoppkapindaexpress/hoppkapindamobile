import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

/// Ana ekran ve listelerde kullanılan arama çubuğu.
///
/// [readOnly] true iken bir butona dönüşür (Home'da tıklanınca arama
/// ekranına yönlendirme için tipik kullanım).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hint = 'Restoran, market ya da ürün ara',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          filled: false,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.softGray, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.textOnPrimary, size: 20),
          ),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
