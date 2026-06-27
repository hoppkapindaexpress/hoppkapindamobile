import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../widgets/widgets.dart';
import '../orders/order_service.dart';
import 'courier_provider.dart';
import 'courier_service.dart';

/// Kurye ana ekranı — atanmış ve bekleyen siparişleri listeler.
class CourierOrdersScreen extends ConsumerStatefulWidget {
  const CourierOrdersScreen({super.key});

  @override
  ConsumerState<CourierOrdersScreen> createState() =>
      _CourierOrdersScreenState();
}

class _CourierOrdersScreenState extends ConsumerState<CourierOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Bekleyen siparişler listesi başka bir kurye tarafından üstlenildiğinde
    // veya yeni sipariş geldiğinde otomatik düşmesi/güncellenmesi için
    // periyodik yenileme.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.invalidate(courierOrdersProvider);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(courierOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delivery_dining_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Kurye Paneli', style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.invalidate(courierOrdersProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.softGray,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Bekleyen Siparişler'),
            Tab(text: 'Benim Siparişlerim'),
          ],
        ),
      ),
      body: ordersAsync.when(
        // skipLoadingOnRefresh varsayılan olarak true: otomatik yenileme
        // (15 sn'de bir invalidate) sırasında elimizde önceki bir liste
        // varsa spinner'a düşmeden data callback'i eski veriyle çağrılır —
        // ekranın sürekli "flaşlamasını" önler. Sadece ilk açılışta
        // (henüz hiç veri yokken) loading callback'i tetiklenir.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Yüklenemedi',
          message: CourierService.errorMessage(e),
          icon: Icons.error_outline_rounded,
          action: AppButton(
            label: 'Tekrar dene',
            expanded: false,
            onPressed: () => ref.invalidate(courierOrdersProvider),
          ),
        ),
        data: (orders) => _OrdersTabView(tab: _tab, orders: orders),
      ),
    );
  }
}

/// Bekleyen ve üstlenilen siparişleri iki sekmede ayıran TabBarView.
/// `loading` (refresh) sırasında önceki veriyle de çağrılabilir,
/// bu nedenle ayrı bir widget olarak çıkarıldı.
class _OrdersTabView extends StatelessWidget {
  const _OrdersTabView({required this.tab, required this.orders});

  final TabController tab;
  final List<OrderDetail> orders;

  @override
  Widget build(BuildContext context) {
    final myOrders =
        orders.where((o) => o.courierId != null && o.isActive).toList();
    final pendingOrders = orders.where((o) => o.courierId == null).toList();

    return TabBarView(
      controller: tab,
      children: [
        _OrderList(
          orders: pendingOrders,
          emptyMessage: 'Şu an bekleyen sipariş yok.',
          isMine: false,
          tabController: tab,
        ),
        _OrderList(
          orders: myOrders,
          emptyMessage: 'Üstlendiğin aktif sipariş yok.',
          isMine: true,
          tabController: tab,
        ),
      ],
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.isMine,
    required this.tabController,
  });

  final List<OrderDetail> orders;
  final String emptyMessage;
  final bool isMine;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyState(
        title: 'Sipariş Yok',
        message: emptyMessage,
        icon: isMine
            ? Icons.inbox_rounded
            : Icons.hourglass_empty_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(courierOrdersProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _OrderCard(
          order: orders[i],
          isMine: isMine,
          tabController: tabController,
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({
    required this.order,
    required this.isMine,
    required this.tabController,
  });
  final OrderDetail order;
  final bool isMine;
  final TabController tabController;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await CourierService.acceptOrder(widget.order.id);
      ref.invalidate(courierOrdersProvider);
      if (mounted) {
        AppToast.showTop(
          context,
          'Sipariş #${widget.order.id} üstlenildi!',
          color: AppColors.success,
        );
        // Benim Siparişlerim sekmesine geç (index 1) ve üstlenilen
        // siparişin detayını otomatik aç.
        widget.tabController.animateTo(1);
        context.push('/courier/order/${widget.order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CourierService.errorMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: () => context.push('/courier/order/${order.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Başlık ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: statusColor, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Sipariş #${order.id}',
                      style: AppTypography.titleMedium),
                  const Spacer(),
                  _StatusBadge(status: order.status),
                ],
              ),
            ),

            // ── İçerik ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restoran
                  _InfoRow(
                    icon: Icons.store_rounded,
                    label: order.storeName ?? 'Restoran',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Teslimat adresi
                  if (order.deliveryAddress != null) ...[
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: order.deliveryAddress!,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],

                  // Tutar
                  _InfoRow(
                    icon: Icons.payments_rounded,
                    label: '₺${order.total.toStringAsFixed(2)}',
                    color: AppColors.success,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Aksiyon butonları
                  if (!widget.isMine)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdAll),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.assignment_turned_in_rounded,
                                size: 18),
                        label: Text(_loading ? 'İşleniyor...' : 'Siparişi Üstlen',
                            style: AppTypography.labelLarge
                                .copyWith(color: Colors.white)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/courier/order/${order.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdAll),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: Text('Siparişi Görüntüle',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => AppColors.warning,
        'confirmed' => AppColors.info,
        'preparing' => AppColors.secondary,
        'ready' => AppColors.success,
        'on_the_way' => AppColors.primary,
        'delivered' => AppColors.success,
        _ => AppColors.softGray,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Onay Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'ready' => ('Kurye Bekleniyor 📦', AppColors.success),
      'on_the_way' => ('Yolda', AppColors.primary),
      'delivered' => ('Teslim Edildi', AppColors.success),
      _ => (status, AppColors.softGray),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label,
              style: AppTypography.bodyMedium, maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
