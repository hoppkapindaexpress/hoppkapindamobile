import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_typography.dart';
import '../courier/courier_provider.dart';
import '../courier/courier_service.dart';
import 'order_provider.dart';
import 'order_service.dart';
import '../../utils/map_marker_helper.dart';

/// Müşteri sipariş takip ekranı.
///
/// Kurye "Yola Çık" butonuna bastıktan sonra:
/// - Haritada kurye konumu gerçek zamanlı güncellenir (her 6 sn polling)
/// - Teslimat adresi haritada gösterilir
/// - Kurye + teslimat adresi arasında rota çizgisi oluşur
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _pollTimer;
  Timer? _locationTimer;
  GoogleMapController? _mapController;
  CourierLocation? _courierLoc;
  List<LatLng> _routePoints = [];
  BitmapDescriptor? _courierIcon;
  BitmapDescriptor? _destIcon;
  LatLng? _animatedCourierPos; // haritada gösterilen (akıcı kayan) konum
  Timer? _markerAnimTimer;

  static const _steps = [
    ('Sipariş alındı', 'Siparişin restorana iletildi',
        Icons.receipt_long_rounded),
    ('Onaylandı', 'Restoran siparişini onayladı', Icons.check_circle_rounded),
    ('Hazırlanıyor', 'Siparişin özenle hazırlanıyor',
        Icons.restaurant_rounded),
    ('Kurye bekleniyor', 'Siparişin hazır, kurye aranıyor 📦',
        Icons.inventory_2_rounded),
    ('Yola çıktı', 'Kurye sana doğru geliyor',
        Icons.delivery_dining_rounded),
    ('Teslim edildi', 'Afiyet olsun!', Icons.home_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // Sipariş durumunu her 10 sn yenile
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(orderDetailProvider(widget.id));
    });
    // Kurye konumunu her 6 sn güncelle
    _locationTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _refreshLocation());
    _refreshLocation();
    _buildIcons();
  }

  String? _courierIconName; // hangi isimle üretildi (tekrar üretmemek için)

  Future<void> _buildIcons() async {
    final dest = await createLabeledMarker(
        text: 'Teslimat', color: const Color(0xFF5A00D6));
    if (mounted) setState(() => _destIcon = dest);
  }

  /// Kurye ikonunu, kurye adı geldiğinde (ya da değiştiğinde) üret.
  Future<void> _buildCourierIcon(String? courierName) async {
    final label = shortName(courierName);
    if (_courierIconName == label && _courierIcon != null) return;
    _courierIconName = label;
    final icon = await createLabeledMarker(
        text: label, color: const Color(0xFFFF7A00));
    if (mounted) setState(() => _courierIcon = icon);
  }

  /// Kurye marker'ını eski konumdan yeni konuma akıcı kaydırır.
  void _animateMarkerTo(LatLng target) {
    final start = _animatedCourierPos ?? target;
    _markerAnimTimer?.cancel();
    const steps = 25;
    const stepMs = 24; // ~600ms toplam
    var i = 0;
    _markerAnimTimer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      i++;
      final f = i / steps;
      if (f >= 1.0 || !mounted) {
        t.cancel();
        if (mounted) setState(() => _animatedCourierPos = target);
        return;
      }
      final lat = start.latitude + (target.latitude - start.latitude) * f;
      final lng = start.longitude + (target.longitude - start.longitude) * f;
      if (mounted) setState(() => _animatedCourierPos = LatLng(lat, lng));
    });
  }

  Future<void> _refreshLocation() async {
    try {
      final loc =
          await CourierService.getOrderCourierLocation(widget.id);
      if (mounted && loc != null) {
        final newPos = LatLng(loc.lat, loc.lng);
        _animateMarkerTo(newPos);
        setState(() => _courierLoc = loc);
        _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
      }
      // Gerçek yol çizgisini (ORS) çek
      final pts = await OrderService.getOrderRoute(widget.id);
      if (mounted && pts.isNotEmpty) {
        setState(() {
          _routePoints = pts.map((p) => LatLng(p.lat, p.lng)).toList();
        });
      }
    } catch (_) {
      // Konum henüz yok, sessizce geç
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _markerAnimTimer?.cancel();
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Takibi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(orderDetailProvider(widget.id));
              _refreshLocation();
            },
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Sipariş yüklenemedi',
          message: OrderService.errorMessage(e),
          icon: Icons.error_outline_rounded,
          action: AppButton(
            label: 'Tekrar dene',
            expanded: false,
            onPressed: () => ref.invalidate(orderDetailProvider(widget.id)),
          ),
        ),
        data: (order) => _trackingBody(context, order),
      ),
    );
  }

  Widget _trackingBody(BuildContext context, OrderDetail order) {
    if (order.isCancelled) {
      return const EmptyState(
        title: 'Sipariş iptal edildi',
        message: 'Bu sipariş iptal edilmiş.',
        icon: Icons.cancel_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _mapArea(order),
        const SizedBox(height: AppSpacing.lg),

        // Kurye canlı konum uyarısı
        if (order.status == 'on_the_way' && _courierLoc != null)
          _liveLocationBanner(),

        if (order.deliveryAddress != null &&
            order.deliveryAddress!.isNotEmpty) ...[
          _addressCard(order.deliveryAddress!),
          const SizedBox(height: AppSpacing.lg),
        ],

        _courierCard(order),
        const SizedBox(height: AppSpacing.lg),
        _statusTimeline(order.stepIndex),
      ],
    );
  }

  Widget _liveLocationBanner() => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A00D6), Color(0xFF7B3BE0)],
          ),
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_tethering_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text('Kurye konumu canlı izleniyor',
                style:
                    AppTypography.labelMedium.copyWith(color: Colors.white)),
          ],
        ),
      );

  Widget _addressCard(String address) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teslimat Adresi', style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(address, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final Set<Factory<OneSequenceGestureRecognizer>> _mapGestures = {
    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
  };

  Set<Marker> _buildMarkers(OrderDetail order) {
    final markers = <Marker>{};

    // Kurye konumu (gerçek zamanlı, akıcı)
    if (_courierLoc != null) {
      _buildCourierIcon(order.courierName);
      final cpos = _animatedCourierPos ??
          LatLng(_courierLoc!.lat, _courierLoc!.lng);
      markers.add(Marker(
        markerId: const MarkerId('courier'),
        position: cpos,
        infoWindow: InfoWindow(
          title: order.courierName ?? 'Kurye',
          snippet: 'Son güncelleme: az önce',
        ),
        icon: _courierIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    // Teslimat adresi
    if (order.addressLat != null && order.addressLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(order.addressLat!, order.addressLng!),
        infoWindow: const InfoWindow(title: 'Teslimat Adresi'),
        icon: _destIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        anchor: const Offset(0.5, 1.0),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(OrderDetail order) {
    // Gerçek yol çizgisi (ORS) varsa onu çiz
    if (_routePoints.length >= 2) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.primary,
          width: 5,
        ),
      };
    }

    // ORS yoksa kurye -> hedef düz çizgi (yedek)
    if (_courierLoc == null ||
        order.addressLat == null ||
        order.addressLng == null) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_courierLoc!.lat, _courierLoc!.lng),
          LatLng(order.addressLat!, order.addressLng!),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  LatLng _initialCamera(OrderDetail order) {
    if (_courierLoc != null) {
      return LatLng(_courierLoc!.lat, _courierLoc!.lng);
    }
    if (order.addressLat != null && order.addressLng != null) {
      return LatLng(order.addressLat!, order.addressLng!);
    }
    return const LatLng(41.0082, 28.9784);
  }

  Widget _mapArea(OrderDetail order) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCamera(order),
                zoom: 14,
              ),
              markers: _buildMarkers(order),
              polylines: _buildPolylines(order),
              onMapCreated: (controller) => _mapController = controller,
              gestureRecognizers: _mapGestures,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _FullScreenMap(
                  markers: _buildMarkers(order),
                  polylines: _buildPolylines(order),
                  gestures: _mapGestures,
                  initialTarget: _initialCamera(order),
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.smAll,
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(Icons.fullscreen_rounded,
                  color: AppColors.primary, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _courierCard(OrderDetail order) {
    final hasCourier = order.courierName != null;
    final isOnTheWay = order.status == 'on_the_way';
    final isReady = order.status == 'ready';
    final subtitle = hasCourier
        ? (isOnTheWay
            ? 'Sana doğru geliyor 🛵'
            : isReady
                ? 'Kurye siparişi teslim alacak 📦'
                : 'Kuryen atandı')
        : (order.stepIndex >= 3
            ? 'Kurye atanıyor...'
            : 'Henüz kurye atanmadı');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.courierName ?? 'Kurye',
                    style: AppTypography.titleMedium),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          if (hasCourier) ...[
            _circleAction(Icons.phone_rounded, AppColors.success),
            const SizedBox(width: 8),
            _circleAction(Icons.message_rounded, AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, Color color) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      );

  Widget _statusTimeline(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sipariş durumu', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _steps.length; i++)
            _timelineStep(i, _steps[i], currentStep,
                isLast: i == _steps.length - 1),
        ],
      ),
    );
  }

  Widget _timelineStep(int index, (String, String, IconData) step,
      int currentStep,
      {required bool isLast}) {
    final done = index <= currentStep;
    final active = index == currentStep;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      done ? AppColors.primary : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  boxShadow: active ? AppShadows.brandGlow : null,
                ),
                child: Icon(step.$3,
                    color: done ? Colors.white : AppColors.softGray,
                    size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: index < currentStep
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.$1,
                      style: AppTypography.titleMedium.copyWith(
                        color:
                            done ? AppColors.textDark : AppColors.softGray,
                      )),
                  const SizedBox(height: 2),
                  Text(step.$2, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.pillAll,
              ),
              child: Text('Şimdi',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _FullScreenMap extends StatelessWidget {
  const _FullScreenMap({
    required this.markers,
    required this.polylines,
    required this.gestures,
    required this.initialTarget,
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Factory<OneSequenceGestureRecognizer>> gestures;
  final LatLng initialTarget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            gestureRecognizers: gestures,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.soft,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textDark, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
