import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../orders/order_service.dart';
import 'courier_background_service.dart';
import 'courier_service.dart';

/// Kuryenin aktif olarak üstlendiği sipariş id'si
final activeCourierOrderIdProvider = StateProvider<String?>((ref) => null);

/// Kurye sipariş listesi
final courierOrdersProvider = FutureProvider<List<OrderDetail>>((ref) {
  return CourierService.getOrders();
});

/// Belirli siparişin detayı (kurye paneli için)
///
/// DÜZELTME — Gereksiz tam liste yükü: tek sipariş için tüm listeyi
/// çekmek yerine doğrudan tek sipariş endpoint'ini kullan.
final courierOrderDetailProvider =
    FutureProvider.family<OrderDetail, String>((ref, id) async {
  // Tek sipariş endpoint'i (GET /orders/{id}) — tüm listeyi getirmekten kaçın
  return OrderService.getOrder(id);
});

/// Canlı konum yayınlama state'i
///
/// GÜNCELLEME (19 Haziran 2026) — Konum gönderimi artık uygulama içi
/// Timer.periodic ile DEĞİL, Android Foreground Service (arka plan
/// isolate'ı, bkz. courier_background_service.dart) üzerinden yapılıyor.
/// Bu sayede uygulama arka plana alınsa, ekran kapansa bile konum
/// gönderimi durmuyor. Bu sınıf artık sadece izin kontrolü yapıp
/// servisi başlatma/durdurma görevi görüyor; UI'daki hata state'i
/// hâlâ aynı şekilde çalışıyor.
class LocationStreamNotifier extends StateNotifier<AsyncValue<void>> {
  LocationStreamNotifier() : super(const AsyncValue.data(null));

  /// Konum yayınını başlat (arka plan foreground service üzerinden).
  Future<void> startTracking({
    required String orderId,
    int intervalSeconds = 3, // NOT: arka plan servisinde sabit aralık kullanılıyor (bkz. courier_background_service.dart)
  }) async {
    // İzin kontrolü — foreground service yaklaşımında "while in use" yeterli,
    // "always" (arka plan) iznine ihtiyaç YOK: Android, aktif bir foreground
    // service çalışırken konum erişimini "kullanımda" sayar.
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state = AsyncValue.error('Konum izni verilmedi.', StackTrace.current);
      return;
    }

    try {
      await startCourierLocationService(orderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Konum yayınını durdur (teslimat tamamlandı/iptal edildi).
  void stopTracking() {
    stopCourierLocationService();
  }
}

final locationStreamProvider =
    StateNotifierProvider<LocationStreamNotifier, AsyncValue<void>>(
  (ref) => LocationStreamNotifier(),
);

/// Müşteri: belirli sipariş için kurye konumunu çeker (polling)
///
/// DÜZELTME — Konum hataları kullanıcıya yansıtılmaz sorununa karşı:
/// provider AsyncValue.error taşır; UI bunu yakalar ve hata mesajı gösterir.
final courierLocationProvider =
    FutureProvider.family<CourierLocation?, String>((ref, orderId) async {
  return CourierService.getOrderCourierLocation(orderId);
});
