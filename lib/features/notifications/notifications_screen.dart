import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/widgets.dart';
import 'notifications_provider.dart';

/// Bildirimler ekranı.
///
/// Sipariş durumu, kampanya ve sistem bildirimleri API'den kullanıcıya özel
/// yüklenir. Sağa kaydırma → okundu | Sola kaydırma → sil.
/// Üst sağda "Tümünü Oku" butonu okunmamış bildirim varken görünür.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);
    final unread      = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Flexible(
              child: Text('Bildirimler',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$unread',
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white, fontSize: 11)),
              ),
            ],
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppColors.textDark,
        actions: [
          if (unread > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
              tooltip: 'Tümünü Oku',
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllRead();
                AppToast.show(context, 'Tüm bildirimler okundu');
              },
            ),
          // Yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.softGray),
            tooltip: 'Yenile',
            onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
          if (asyncNotifs.valueOrNull?.isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.softGray),
              tooltip: 'Hepsini Temizle',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: asyncNotifs.when(
        // ---- Yükleniyor ----
        loading: () => const Center(child: CircularProgressIndicator()),

        // ---- Hata ----
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.softGray),
              const SizedBox(height: 12),
              Text('Bildirimler yüklenemedi',
                  style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),

        // ---- Veri ----
        data: (notifications) => notifications.isEmpty
            ? const EmptyState(
                title: 'Henüz bildirim yok',
                message:
                    'Sipariş durumu ve kampanya bildirimleri burada görünecek.',
                icon: Icons.notifications_none_rounded,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 16,
                      endIndent: 16),
                  itemBuilder: (context, i) {
                    final notif = notifications[i];
                    return _NotifTile(
                      notification: notif,
                      onTap: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .markRead(notif.id);
                        if (notif.actionRoute != null) {
                          context.push(notif.actionRoute!);
                        }
                      },
                      onDismissed: (dir) {
                        if (dir == DismissDirection.endToStart) {
                          ref
                              .read(notificationsProvider.notifier)
                              .remove(notif.id);
                          AppToast.show(context, 'Bildirim silindi');
                        } else {
                          ref
                              .read(notificationsProvider.notifier)
                              .markRead(notif.id);
                        }
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirimleri Temizle'),
        content: const Text('Tüm bildirimler silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text('Temizle',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Bildirim Tile (Dismissible)
// ============================================================

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });
  final AppNotification notification;
  final VoidCallback onTap;
  final void Function(DismissDirection) onDismissed;

  @override
  Widget build(BuildContext context) {
    final n     = notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(n.id),
      confirmDismiss: (dir) async => true,
      onDismissed: onDismissed,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        color: AppColors.success.withValues(alpha: 0.15),
        child: const Icon(Icons.done_all_rounded, color: AppColors.success),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: n.isRead
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _bgColor(n.type).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(n.type.icon,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(n.timeAgo,
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.softGray)),
                        if (!n.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (n.actionRoute != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Detayı gör →',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bgColor(NotifType type) => switch (type) {
        NotifType.orderStatus => AppColors.primary,
        NotifType.campaign    => AppColors.secondary,
        NotifType.system      => AppColors.info,
      };
}
