import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../routes/app_router.dart';
import '../../widgets/widgets.dart';

/// Onboarding verisi.
class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
}

/// 3 sayfalık premium onboarding akışı.
///
/// Sayfalar arası yumuşak geçiş, smooth indicator ve CTA butonları içerir.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.restaurant_menu_rounded,
      title: 'Binlerce lezzet\ntek dokunuşta',
      description:
          'En sevdiğin restoranlar, market ve tatlıcılar tek uygulamada. Keşfet, seç, sipariş ver.',
      gradient: AppColors.brandGradient,
    ),
    _OnboardPage(
      icon: Icons.bolt_rounded,
      title: 'Şimşek hızında\nteslimat',
      description:
          'Marketten 15 dakikada, restorandan dakikalar içinde. Kuryeni canlı takip et.',
      gradient: AppColors.warmGradient,
    ),
    _OnboardPage(
      icon: Icons.local_offer_rounded,
      title: 'Sana özel\nkampanyalar',
      description:
          'lk siparişine özel indirimler, kuponlar ve sadece üyelere özel fırsatlar seni bekliyor.',
      gradient: AppColors.accentGradient,
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _next() async {
    if (_isLast) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
      if (mounted) context.go(AppRoutes.home);
    } else {
      _controller.nextPage(
          duration: AppDurations.page, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // "Atla" butonu.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md, top: 8),
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_seen', true);
                    if (mounted) context.go(AppRoutes.home);
                  },
                  child: Text('Atla',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textMuted)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.border,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: _isLast ? 'Hadi başlayalım' : 'Devam et',
                    variant: AppButtonVariant.gradient,
                    icon: _isLast ? Icons.arrow_forward_rounded : null,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // llüstrasyon yerine premium gradient daire + ikon
          // (gerçek illüstrasyon/Lottie Faz 3'te assets ile eklenir).
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.brandGlow,
            ),
            child: Icon(page.icon, size: 96, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(page.title,
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.md),
          Text(page.description,
              textAlign: TextAlign.center, style: AppTypography.bodyLarge),
        ],
      ),
    );
  }
}