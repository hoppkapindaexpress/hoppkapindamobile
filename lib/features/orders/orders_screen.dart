import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/widgets.dart';
import '../auth/auth_provider.dart';
import 'order_provider.dart';
import 'order_service.dart';

/// Siparişler ekranı — aktif ve geçmiş sipariş sekmeleri.
/// Gerçek API'den (/orders) kullanıcının siparişlerini çeker.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider).isLoggedIn;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
            child: Text('Siparişlerim', style: AppTypography.displayMedium),
          ),
          if (!loggedIn)
            Expanded(child: _loginPrompt())
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  AppChip(label: 'Aktif', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(label: 'Geçmiş', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _ordersList()),
          ],
        ],
      ),
    );
  }

  Widget _loginPrompt() => EmptyState(
        title: 'Siparişlerini görmek için giriş yap',
        message: 'Geçmiş ve aktif siparişlerin burada listelenir.',
        icon: Icons.receipt_long_outlined,
        action: AppButton(
          label: 'Giriş Yap',
          expanded: false,
          onPressed: () => context.push('/login'),
        ),
      );

  Widget _ordersList() {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        title: 'Siparişler yüklenemedi',
        message: OrderService.errorMessage(e),
        icon: Icons.error_outline_rounded,
        action: AppButton(
          label: 'Tekrar dene',
          expanded: false,
          onPressed: () => ref.invalidate(ordersProvider),
        ),
      ),
      data: (orders) {
        final filtered = orders.where((o) => _tab == 0 ? o.isActive : !o.isActive).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            title: _tab == 0 ? 'Aktif siparişin yok' : 'Geçmiş siparişin yok',
            message: _tab == 0 ? 'Yeni bir sipariş ver, burada takip et.' : null,
            icon: Icons.receipt_long_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ordersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _orderCard(filtered[i]),
          ),
        );
      },
    );
  }

  Widget _orderCard(OrderDetail order) {
    final statusColor = order.isActive ? AppColors.secondary : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.storeName ?? 'Sipariş #${order.id}',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 7, height: 7,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(order.statusLabel,
                            style: AppTypography.labelSmall.copyWith(color: statusColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Text('₺${order.total.toStringAsFixed(2)}', style: AppTypography.price),
            ],
          ),
          if (order.isActive) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Siparişi Takip Et',
              variant: AppButtonVariant.gradient,
              height: 46,
              icon: Icons.location_on_rounded,
              onPressed: () => context.push('/order/${order.id}/track'),
            ),
          ],
        ],
      ),
    );
  }
}
