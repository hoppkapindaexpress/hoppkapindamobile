import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/widgets.dart';
import '../auth/auth_provider.dart';
import '../notifications/notifications_provider.dart';

/// Profil ekranı — kullanıcı bilgisi, hesap menüsü ve ayarlar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final user = ref.watch(authProvider).user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profil', style: AppTypography.displayMedium),
              const _NotifBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Kullanıcı kartı
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
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
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Misafir Kullanıcı',
                          style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? 'Giriş yapılmadı',
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
                const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _menuGroup(context, 'Hesabım', [
            _MenuItem(Icons.location_on_outlined, 'Adreslerim', route: AppRoutes.addresses),
            _MenuItem(Icons.credit_card_outlined, 'Ödeme Yöntemleri'),
            _MenuItem(Icons.favorite_border_rounded, 'Favorilerim'),
            _MenuItem(Icons.receipt_long_outlined, 'Sipariş Geçmişi'),
          ]),
          const SizedBox(height: AppSpacing.md),

          // Ayarlar grubu — dark mode toggle gerçek çalışır
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: AppRadius.lgAll,
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ayarlar', style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textMuted)),
                  ),
                ),
                SwitchListTile(
                  value: isDark,
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text('Karanlık Mod', style: AppTypography.titleMedium),
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
                _tile(context, Icons.language_outlined, 'Dil', trailing: 'Türkçe'),
                _tile(context, Icons.notifications_outlined, 'Bildirimler', route: AppRoutes.notifications),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _menuGroup(context, 'Destek', [
            _MenuItem(Icons.help_outline_rounded, 'Yardım Merkezi'),
            _MenuItem(Icons.info_outline_rounded, 'Hakkında'),
          ]),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: 'Çıkış Yap',
            variant: AppButtonVariant.outline,
            icon: Icons.logout_rounded,
            onPressed: () async {
              // Ayrıca context.go(AppRoutes.login) ÇAĞRILMIYOR —
              // logout() authProvider'ı temizleyince MainShell bunu
              // izleyip Profil sekmesini otomatik olarak (nav bar'lı)
              // LoginScreen'e çeviriyor.
              await ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _menuGroup(BuildContext context, String title, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Text(title, style: AppTypography.labelMedium
                .copyWith(color: AppColors.textMuted)),
          ),
          for (final item in items) _tile(context, item.icon, item.label, route: item.route),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      {String? trailing, String? route}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(label, style: AppTypography.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: AppTypography.bodySmall),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.softGray),
        ],
      ),
      onTap: route != null
          ? () => context.push(route)
          : () => AppToast.show(context, '$label yakında'),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, {this.route});
  final IconData icon;
  final String label;
  final String? route;
}

/// Profil ekranı üst köşesindeki bildirim zili.
/// Okunmamış bildirim varsa kırmızı badge gösterir.
class _NotifBadge extends ConsumerWidget {
  const _NotifBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textDark, size: 22),
          ),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
