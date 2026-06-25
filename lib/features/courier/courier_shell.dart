import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../../config/theme_provider.dart';
import '../../routes/app_router.dart';
import '../auth/auth_provider.dart';
import 'courier_dashboard_screen.dart';
import 'courier_orders_screen.dart';

/// Kurye ana kabuğu — müşteri MainShell'inden tamamen bağımsız.
/// İki sekme: Siparişler + Profil
class CourierShell extends ConsumerStatefulWidget {
  const CourierShell({super.key});

  @override
  ConsumerState<CourierShell> createState() => _CourierShellState();
}

class _CourierShellState extends ConsumerState<CourierShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      CourierDashboardScreen(onSeeOrders: () => setState(() => _index = 1)),
      const CourierOrdersScreen(),
      const _CourierProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Panel',
          ),
          AppNavItem(
            icon: Icons.delivery_dining_outlined,
            activeIcon: Icons.delivery_dining_rounded,
            label: 'Siparişler',
          ),
          AppNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Kurye profil sekmesi
class _CourierProfileTab extends ConsumerWidget {
  const _CourierProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Profilim', style: AppTypography.displayMedium),
          const SizedBox(height: AppSpacing.lg),

          // Kurye kimlik kartı
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5A00D6), Color(0xFF7B3BE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.xlAll,
              boxShadow: AppShadows.brandGlow,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Kurye',
                        style: AppTypography.titleLarge
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          'Kurye',
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Ayarlar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppRadius.lgAll,
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ayarlar',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ),
                SwitchListTile(
                  value: isDark,
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text('Karanlık Mod', style: AppTypography.titleMedium),
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined,
                      color: AppColors.textDark),
                  title:
                      Text('Bildirimler', style: AppTypography.titleMedium),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.softGray),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Çıkış
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text('Çıkış Yap', style: AppTypography.labelLarge),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
