import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../../widgets/widgets.dart';
import '../orders/order_service.dart';
import '../../utils/map_marker_helper.dart';
import 'navigation_launcher.dart';
import 'courier_provider.dart';
import 'courier_service.dart';

/// Kurye teslimat ekranı
///
/// - Sipariş konumunu (teslimat adresi) haritada gösterir
/// - Kuryenin kendi konumunu haritada günceller
/// - "Yol Tarifi" butonu → haritayı kurye ↔ müşteri arasında sığdırır
/// - "Yola Çık" butonu → status = on_the_way + konum yayını başlar
/// - "Teslim Ettim" butonu → status = delivered + konum yayını durur
class CourierDeliveryScreen extends ConsumerStatefulWidget {
  const CourierDeliveryScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<CourierDeliveryScreen> createState() =>
      _CourierDeliveryScreenState();
}

class _CourierDeliveryScreenState
    extends ConsumerState<CourierDeliveryScreen> {
  GoogleMapController? _mapController;
  LatLng? _courierPos;
  List<LatLng> _routePoints = [];
  BitmapDescriptor? _courierIcon;
  BitmapDescriptor? _destIcon;
  Timer? _pollTimer;
  bool _actionLoading = false;

  /// Yol tarifi modu aktif mi (harita iki nokta arasını gösteriyor)
  bool _routeActive = false;

  StreamSubscription<Position>? _locationSubscription;

  static const Set<Factory<OneSequenceGestureRecognizer>> _mapGestures = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)
  };

  @override
  void initState() {
    super.initState();
    _startSelfLocation();
    _refreshRoute();
    _buildIcons();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(courierOrderDetailProvider(widget.orderId));
      _refreshRoute();
    });
    // Ekran açıldığında sipariş zaten on_the_way ise konum takibini başlat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final order = await OrderService.getOrder(widget.orderId);
        if (order.status == 'on_the_way' && mounted) {
          await ref
              .read(locationStreamProvider.notifier)
              .startTracking(orderId: widget.orderId);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _locationSubscription?.cancel();
    // NOT (19 Haziran 2026): Buradaki stopTracking() çağrısı KASITLI olarak
    // kaldırıldı. Artık konum takibi Android Foreground Service üzerinden
    // çalışıyor — kurye bu ekrandan çıkıp dashboard'a dönse bile teslimat
    // hâlâ "on_the_way" durumundaysa takip DEVAM ETMELİ. Takip artık sadece
    // _completeDelivery()'de (teslim tamamlanınca) durduruluyor.
    _mapController?.dispose();
    super.dispose();
  }

  /// Haritada kuryenin kendi konumunu izle
  void _startSelfLocation() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (pos) {
        final ll = LatLng(pos.latitude, pos.longitude);
        if (mounted) setState(() => _courierPos = ll);
        // Yol tarifi modu açık değilse kamerayı kurye konumuna kilitle
        if (!_routeActive) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(ll));
        }
        _refreshRoute();
      },
      onError: (Object e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Konum alınamıyor: ${e.toString()}'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  /// Haritayı kurye konumu ile müşteri konumunu kapsayacak şekilde sığdır
  String? _courierIconName;

  Future<void> _buildIcons() async {
    final dest = await createLabeledMarker(
        text: 'Teslimat', color: const Color(0xFF5A00D6));
    if (mounted) setState(() => _destIcon = dest);
  }

  /// Kurye ikonunu kurye adıyla üret (Test K. gibi).
  Future<void> _buildCourierIcon(String? courierName) async {
    final label = shortName(courierName);
    if (_courierIconName == label && _courierIcon != null) return;
    _courierIconName = label;
    final icon = await createLabeledMarker(
        text: label, color: const Color(0xFFFF7A00));
    if (mounted) setState(() => _courierIcon = icon);
  }

  /// Backend'den gerçek yol çizgisini (ORS) çek.
  Future<void> _refreshRoute() async {
    try {
      final pts = await OrderService.getOrderRoute(widget.orderId);
      if (mounted && pts.isNotEmpty) {
        setState(() {
          _routePoints = pts.map((p) => LatLng(p.lat, p.lng)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fitRoute(LatLng dest) async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    final origin = _courierPos ?? dest;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(origin.latitude, dest.latitude),
        math.min(origin.longitude, dest.longitude),
      ),
      northeast: LatLng(
        math.max(origin.latitude, dest.latitude),
        math.max(origin.longitude, dest.longitude),
      ),
    );

    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding
    );

    if (mounted) setState(() => _routeActive = true);
  }

  /// Yol tarifi modunu kapat, kamerayı kurye konumuna döndür
  void _exitRoute() {
    setState(() => _routeActive = false);
    if (_courierPos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _courierPos!, zoom: 16),
        ),
      );
    }
  }

  Future<void> _startDelivery(OrderDetail order) async {
    setState(() => _actionLoading = true);
    try {
      await CourierService.startDelivery(order.id);
      await ref
          .read(locationStreamProvider.notifier)
          .startTracking(orderId: order.id);
      ref.invalidate(courierOrderDetailProvider(order.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛵 Yola çıktın! Konum paylaşımı başladı.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _completeDelivery(OrderDetail order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Teslim Et'),
        content: Text(
            'Sipariş #${order.id} teslim edildi olarak işaretlensin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Teslim Ettim'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await CourierService.completeDelivery(order.id);
      ref.read(locationStreamProvider.notifier).stopTracking();
      ref.invalidate(courierOrderDetailProvider(order.id));
      ref.invalidate(courierOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Sipariş teslim edildi!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
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
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(courierOrderDetailProvider(widget.orderId));

    ref.listen<AsyncValue<void>>(locationStreamProvider, (_, next) {
      if (next.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum gönderilemedi: ${next.error}'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Teslimat #${widget.orderId}',
            style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Yüklenemedi',
          message: CourierService.errorMessage(e),
          icon: Icons.error_outline_rounded,
        ),
        data: (order) => _body(order),
      ),
    );
  }

  Widget _body(OrderDetail order) {
    final destPos = _destLatLng(order);
    final isReady = order.status == 'ready';
    final isOnTheWay = order.status == 'on_the_way';
    final isDelivered = order.status == 'delivered';

    return Column(
      children: [
        // ── Harita ───────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: destPos ?? const LatLng(41.0082, 28.9784),
                  zoom: 15,
                ),
                markers: (() {
                  _buildCourierIcon(order.courierName);
                  return _buildMarkers(destPos);
                })(),
                polylines: (_courierPos != null && destPos != null)
                    ? {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: _routePoints.length >= 2
                              ? _routePoints
                              : [_courierPos!, destPos],
                          color: _routeActive
                              ? AppColors.secondary
                              : AppColors.primary,
                          width: _routeActive ? 6 : 5,
                          patterns: (isOnTheWay || _routePoints.length >= 2)
                              ? []
                              : [
                                  PatternItem.dash(20),
                                  PatternItem.gap(10)
                                ],
                        ),
                      }
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onMapCreated: (c) {
                  _mapController = c;
                  if (_courierPos != null) {
                    c.animateCamera(CameraUpdate.newLatLng(_courierPos!));
                  }
                },
                gestureRecognizers: _mapGestures,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // ── Yol Tarifi butonu ────────────────────────────────────
              if (destPos != null)
                Positioned(
                  top: isOnTheWay ? 60 : 16,
                  right: 16,
                  child: _routeActive
                      // Rotadan çık butonu
                      ? FloatingActionButton.small(
                          heroTag: 'exit_route',
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          onPressed: _exitRoute,
                          child: const Icon(Icons.close_rounded),
                        )
                      // Yol tarifi başlat butonu
                      : FloatingActionButton.extended(
                          heroTag: 'navigate',
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 3,
                          onPressed: () => _fitRoute(destPos),
                          icon: const Icon(Icons.directions_rounded),
                          label: Text(
                            'Yol Tarifi',
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                ),

              // ── Telefon Haritası (Google/Apple/Yandex) butonu ─────────
              if (destPos != null && !_routeActive)
                Positioned(
                  top: isOnTheWay ? 116 : 72,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'ext_nav',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    onPressed: () => showNavigationSheet(context, order),
                    icon: const Icon(Icons.map_rounded),
                    label: Text(
                      'Telefon Haritası',
                      style: AppTypography.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),

              // ── Koordinat bulunamadı uyarısı ──────────────────────────
              if (destPos == null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Müşteri koordinatı bulunamadı — harita yol tarifi devre dışı.',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Konum paylaşımı rozeti ────────────────────────────────
              if (isOnTheWay)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_tethering_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('Konum paylaşılıyor',
                              style: AppTypography.labelSmall
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Yol tarifi aktif mesafe bandı ────────────────────────
              if (_routeActive && _courierPos != null && destPos != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _RouteBanner(
                    origin: _courierPos!,
                    destination: destPos,
                  ),
                ),
            ],
          ),
        ),

        // ── Alt panel ────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.screenPadding,
            // Telefonun alt güvenli alanı (gesture bar) kadar ekstra boşluk
            bottom: AppSpacing.screenPadding +
                MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            boxShadow: AppShadows.soft,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.xl),
              topRight: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.storeName ?? 'Restoran',
                            style: AppTypography.titleMedium),
                        Text(
                            '₺${order.total.toStringAsFixed(2)} · Sipariş #${order.id}',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  _StatusBadgeMini(status: order.status),
                ],
              ),

              // ── Adres + Haritada Göster ───────────────────────────────
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(order.deliveryAddress!,
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (destPos != null)
                        GestureDetector(
                          onTap: _routeActive
                              ? _exitRoute
                              : () => _fitRoute(destPos),
                          child: Container(
                            margin:
                                const EdgeInsets.only(left: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _routeActive
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _routeActive
                                      ? Icons.map_rounded
                                      : Icons.directions_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _routeActive
                                      ? 'Haritada'
                                      : 'Yol Tarifi',
                                  style: AppTypography.labelSmall
                                      .copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: isDelivered
                    ? Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withValues(alpha: 0.1),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Teslim Edildi',
                                style: AppTypography.titleMedium
                                    .copyWith(color: AppColors.success)),
                          ],
                        ),
                      )
                    : isOnTheWay
                        ? ElevatedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _completeDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.mdAll),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.check_circle_outline_rounded),
                            label: Text(
                              _actionLoading
                                  ? 'İşleniyor...'
                                  : '✅ Teslim Ettim',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _actionLoading
                                ? null
                                : () => _startDelivery(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.mdAll),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            icon: _actionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.delivery_dining_rounded),
                            label: Text(
                              _actionLoading
                                  ? 'İşleniyor...'
                                  : '🛵 Yola Çık',
                              style: AppTypography.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LatLng? _destLatLng(OrderDetail order) {
    if (order.addressLat != null && order.addressLng != null) {
      return LatLng(order.addressLat!, order.addressLng!);
    }
    return null;
  }

  Set<Marker> _buildMarkers(LatLng? dest) {
    final markers = <Marker>{};

    if (_courierPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('courier'),
        position: _courierPos!,
        infoWindow: const InfoWindow(title: '🛵 Sen'),
        icon: _courierIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    if (dest != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: dest,
        infoWindow: const InfoWindow(title: '📍 Teslimat Adresi'),
        icon: _destIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    return markers;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yol tarifi aktifken altta gösterilen mesafe / tahmini süre bandı
// ─────────────────────────────────────────────────────────────────────────────

class _RouteBanner extends StatelessWidget {
  const _RouteBanner({
    required this.origin,
    required this.destination,
  });

  final LatLng origin;
  final LatLng destination;

  /// Haversine ile kuş uçuşu mesafe (km)
  double _distanceKm() {
    const r = 6371.0;
    final dLat = _rad(destination.latitude - origin.latitude);
    final dLng = _rad(destination.longitude - origin.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(origin.latitude)) *
            math.cos(_rad(destination.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final km = _distanceKm();
    final distLabel =
        km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

    // Ortalama kurye hızı 25 km/s varsayımıyla tahmini süre
    final minutes = (km / 25 * 60).round();
    final timeLabel = minutes < 1
        ? '< 1 dk'
        : minutes < 60
            ? '$minutes dk'
            : '${(minutes / 60).floor()} sa ${minutes % 60} dk';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          // Mesafe
          _InfoCell(
            icon: Icons.straighten_rounded,
            label: 'Mesafe',
            value: distLabel,
            color: AppColors.primary,
          ),
          const _Divider(),
          // Tahmini süre
          _InfoCell(
            icon: Icons.access_time_rounded,
            label: 'Tahmini',
            value: timeLabel,
            color: AppColors.secondary,
          ),
          const _Divider(),
          // Araç modu
          _InfoCell(
            icon: Icons.delivery_dining_rounded,
            label: 'Araç',
            value: 'Motorsiklet',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style:
                  AppTypography.titleSmall.copyWith(color: AppColors.textDark),
              textAlign: TextAlign.center),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Durum rozeti
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadgeMini extends StatelessWidget {
  const _StatusBadgeMini({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Bekliyor', AppColors.warning),
      'confirmed' => ('Onaylandı', AppColors.info),
      'preparing' => ('Hazırlanıyor', AppColors.secondary),
      'ready' => ('Kurye Bekleniyor 📦', AppColors.success),
      'on_the_way' => ('Yolda 🛵', AppColors.primary),
      'delivered' => ('Teslim ✅', AppColors.success),
      _ => (status, AppColors.softGray),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(label,
          style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}
