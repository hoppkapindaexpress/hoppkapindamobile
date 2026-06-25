import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../auth/auth_provider.dart';
import '../orders/order_service.dart';
import 'courier_provider.dart';
import 'courier_service.dart';

/// Kuryenin çevrimiçi/çevrimdışı durumu (yeni sipariş kabul edebilir mi).
///
/// GÜNCELLEME (20 Haziran 2026) — Daha önce bu sadece yerel bir
/// StateProvider'dı, backend'e hiç ulaşmıyordu. Bu yüzden "Çevrimdışı"
/// toggle'ına basmak hiçbir gerçek etki yaratmıyordu: kurye hâlâ konum
/// gönderiyor ve yeni sipariş push bildirimleri alıyordu. Artık gerçek
/// durum backend'de (couriers.status) tutuluyor; bu notifier açılışta
/// /courier/profile'dan durumu çeker, toggle'da /courier/availability'yi
/// çağırır.
class CourierOnlineNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final profile = await CourierService.getProfile();
      final status = profile['status'] as String?;
      return status != 'off_duty';
    } catch (_) {
      // Profil çekilemezse güvenli taraf: çevrimdışı say (konum/push
      // göndermeye "izinliyim" diye varsayılmasın).
      return false;
    }
  }

  /// Toggle'a basılınca çağrılır. Backend reddederse (örn. aktif teslimat
  /// sırasında çevrimdışı olmaya çalışınca) state eski haline döner ve
  /// hata fırlatılır — UI bunu yakalayıp SnackBar gösterebilir.
  Future<void> setOnline(bool online) async {
    final previous = state.valueOrNull ?? true;
    state = AsyncValue.data(online); // optimistic update
    try {
      final status = await CourierService.updateAvailability(online);
      state = AsyncValue.data(status != 'off_duty');
    } catch (e) {
      state = AsyncValue.data(previous); // geri al
      rethrow;
    }
  }
}

final courierOnlineProvider =
    AsyncNotifierProvider<CourierOnlineNotifier, bool>(
  CourierOnlineNotifier.new,
);

/// Kurye panosu — günün özeti, aktif sipariş, çevrimiçi durumu.
class CourierDashboardScreen extends ConsumerWidget {
  const CourierDashboardScreen({super.key, this.onSeeOrders});

  /// "Siparişlere git" sekmesine geçiş için shell'den gelen callback.
  final VoidCallback? onSeeOrders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final onlineAsync = ref.watch(courierOnlineProvider);
    final online = onlineAsync.valueOrNull ?? true;
    final ordersAsync = ref.watch(courierOrdersProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(courierOrdersProvider);
          await ref.read(courierOrdersProvider.future).catchError((_) => <OrderDetail>[]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba,', style: AppTypography.bodyMedium),
                      Text(user?.name ?? 'Kurye',
                          style: AppTypography.displayMedium),
                    ],
                  ),
                ),
                _onlineToggle(context, ref, online),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            ordersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _errorBox(ref, e),
              data: (orders) => _content(context, ref, orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, List<OrderDetail> orders) {
    // Kuryeye atanmış aktif siparişler ve bugün teslim edilenler.
    final mine = orders.where((o) => o.courierId != null).toList();
    final active = mine.where((o) => o.isActive).toList();
    final deliveredToday = mine.where((o) => o.status == 'delivered').length;
    final waiting = orders.where((o) => o.courierId == null && o.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aktif sipariş banner'ı
        if (active.isNotEmpty) ...[
          _activeOrderBanner(context, active.first),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Özet kartları
        Row(
          children: [
            _statCard(
              icon: Icons.check_circle_rounded,
              value: '$deliveredToday',
              label: 'Bugün teslim',
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            _statCard(
              icon: Icons.local_shipping_rounded,
              value: '${active.length}',
              label: 'Aktif sipariş',
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            _statCard(
              icon: Icons.inbox_rounded,
              value: '$waiting',
              label: 'Bekleyen',
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Bekleyen sipariş varsa "Siparişlere git" çağrısı
        if (waiting > 0) ...[
          _ctaCard(
            title: '$waiting yeni sipariş seni bekliyor',
            subtitle: 'Hemen üstlenmek için siparişlere göz at',
            onTap: onSeeOrders,
          ),
        ] else if (active.isEmpty) ...[
          _emptyState(),
        ],
      ],
    );
  }

  Widget _onlineToggle(BuildContext context, WidgetRef ref, bool online) {
    Future<void> handleTap() async {
      try {
        await ref.read(courierOnlineProvider.notifier).setOnline(!online);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(CourierService.errorMessage(e)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: online
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.softGray.withValues(alpha: 0.15),
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: online ? AppColors.success : AppColors.softGray,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              online ? 'Çevrimiçi' : 'Çevrimdışı',
              style: AppTypography.labelMedium.copyWith(
                color: online ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeOrderBanner(BuildContext context, OrderDetail order) {
    return GestureDetector(
      onTap: () => context.push('/courier/order/${order.id}'),
      child: Container(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.navigation_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aktif teslimat',
                      style: AppTypography.labelMedium
                          .copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 2),
                  Text('Sipariş #${order.id} · ${order.statusLabel}',
                      style: AppTypography.titleMedium
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value,
                style: AppTypography.headlineSmall.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _ctaCard({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: AppColors.secondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          const Icon(Icons.coffee_rounded, size: 40, color: AppColors.softGray),
          const SizedBox(height: AppSpacing.sm),
          Text('Şu an aktif siparişin yok',
              style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Yeni sipariş geldiğinde burada görünecek',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _errorBox(WidgetRef ref, Object error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(height: 8),
          Text('Veriler yüklenemedi', style: AppTypography.titleSmall),
          const SizedBox(height: 6),
          Text(
            CourierService.errorMessage(error),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(courierOrdersProvider),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
