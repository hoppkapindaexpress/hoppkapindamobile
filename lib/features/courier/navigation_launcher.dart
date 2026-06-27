import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_dimensions.dart';
import '../orders/order_service.dart';

/// Adrese göre yol tarifi modalını açar.
///
/// Koordinat varsa koordinatla, yoksa adres string'iyle arama yapılır.
/// Google Maps, Yandex Maps ve Apple Maps — platform fark etmeksizin
/// üçü de listelenir (Apple Maps Android'de çalışmayabilir, bkz. ilgili
/// yorum aşağıda).
Future<void> showNavigationSheet(
  BuildContext context,
  OrderDetail order,
) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    backgroundColor: AppColors.card,
    builder: (_) => _NavigationSheet(order: order),
  );
}

class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final hasCoords = order.addressLat != null && order.addressLng != null;
    final lat = order.addressLat;
    final lng = order.addressLng;
    final address = order.deliveryAddress ?? '';

    final apps = _buildApps(
      hasCoords: hasCoords,
      lat: lat,
      lng: lng,
      address: address,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Text('Yol Tarifi Al', style: AppTypography.titleLarge),
            const SizedBox(height: 4),

            // Adres
            if (address.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Uygulama butonları
            ...apps.map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppTile(app: app),
                )),

            // Koordinat yoksa uyarı
            if (!hasCoords)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 13, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Koordinat bulunamadı, adres metniyle arama yapılacak.',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.warning),
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

  List<_NavApp> _buildApps({
    required bool hasCoords,
    required double? lat,
    required double? lng,
    required String address,
  }) {
    final encoded = Uri.encodeComponent(address);

    final apps = <_NavApp>[];

    // Google Maps
    final googleUrl = hasCoords
        ? 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
        : 'https://www.google.com/maps/search/?api=1&query=$encoded';
    apps.add(_NavApp(
      name: 'Google Maps',
      icon: Icons.map_rounded,
      color: const Color(0xFF4285F4),
      url: googleUrl,
    ));

    // Yandex Maps
    final yandexUrl = hasCoords
        ? 'yandexmaps://maps.yandex.com/?rtext=~$lat,$lng&rtt=auto'
        : 'yandexmaps://maps.yandex.com/?text=$encoded';
    final yandexFallback = hasCoords
        ? 'https://yandex.com/maps/?rtext=~$lat,$lng&rtt=auto'
        : 'https://yandex.com/maps/?text=$encoded';
    apps.add(_NavApp(
      name: 'Yandex Maps',
      icon: Icons.navigation_rounded,
      color: const Color(0xFFFC3F1D),
      url: yandexUrl,
      fallbackUrl: yandexFallback,
    ));

    // Apple Maps — kullanıcı isteğiyle platform kısıtlaması kaldırıldı.
    // NOT: Android'de native Apple Maps uygulaması yok; maps.apple.com
    // web linki Android tarayıcılarında genelde çalışmıyor/boş sayfa
    // gösteriyor. Bu seçenek Android'de görünür ama gerçek navigasyon
    // sağlamayabilir.
    {
      final appleUrl = hasCoords
          ? 'http://maps.apple.com/?daddr=$lat,$lng&dirflg=d'
          : 'http://maps.apple.com/?q=$encoded';
      apps.add(_NavApp(
        name: 'Apple Maps',
        icon: Icons.map_outlined,
        color: const Color(0xFF000000),
        url: appleUrl,
      ));
    }

    return apps;
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});
  final _NavApp app;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _launch(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(app.icon, color: app.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  app.name,
                  style: AppTypography.titleMedium,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(app.url);

    // Önce native uygulamayı dene
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
      return;
    }

    // Native uygulama yoksa fallback URL'e git (tarayıcı)
    if (app.fallbackUrl != null) {
      final fallback = Uri.parse(app.fallbackUrl!);
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
        if (context.mounted) Navigator.pop(context);
        return;
      }
    }

    // Hiçbiri açılamadıysa hata göster
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.name} açılamadı'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _NavApp {
  const _NavApp({
    required this.name,
    required this.icon,
    required this.color,
    required this.url,
    this.fallbackUrl,
  });

  final String name;
  final IconData icon;
  final Color color;
  final String url;
  final String? fallbackUrl; // Yandex gibi native uygulama yoksa web
}
