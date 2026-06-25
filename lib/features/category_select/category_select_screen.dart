import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';

const String kCategoryKey = 'selected_category';

class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  bool _loading = false;

  Future<void> _onSelect(String category) async {
    if (_loading) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kCategoryKey, category);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              Text(
                'Hopp\'a\nHoş Geldin!',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ne sipariş etmek istiyorsun?',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 48),
              _CategoryCard(
                title: 'Yemek',
                subtitle: 'Lezzetli yemekler kapında!',
                imagePath: 'assets/images/categories/yemek.png',
                bgColor: const Color(0xFFFFF3E8),
                accentColor: const Color(0xFFFF7A00),
                onTap: _loading ? null : () => _onSelect('restaurant'),
              ),
              const SizedBox(height: 16),
              _CategoryCard(
                title: 'Tatlı',
                subtitle: 'En tatlı anlar için tatlılar!',
                imagePath: 'assets/images/categories/tatli.png',
                bgColor: const Color(0xFFFFF0F3),
                accentColor: const Color(0xFFE5484D),
                onTap: _loading ? null : () => _onSelect('dessert'),
              ),
              const SizedBox(height: 16),
              _CategoryCard(
                title: 'Market',
                subtitle: 'İhtiyacın olan her şey kapında!',
                imagePath: 'assets/images/categories/market.png',
                bgColor: const Color(0xFFEBF7F0),
                accentColor: const Color(0xFF1FB85F),
                onTap: _loading ? null : () => _onSelect('market'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loading ? null : () => _onSelect('all'),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'Tümünü Göster →',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.bgColor,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final Color bgColor;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.fastfood_rounded,
                  color: accentColor,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: accentColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
