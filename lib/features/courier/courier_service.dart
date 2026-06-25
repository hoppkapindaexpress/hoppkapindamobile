import 'package:dio/dio.dart';
import '../orders/order_service.dart';
import '../../repositories/api_store_repository.dart';

/// Sayı ya da string gelen değeri güvenle double'a çevirir.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Kurye konum modeli
class CourierLocation {
  const CourierLocation({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.recordedAt,
  });

  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final DateTime? recordedAt;

  factory CourierLocation.fromJson(Map<String, dynamic> j) => CourierLocation(
        lat: _toDouble(j['lat']) ?? 0,
        lng: _toDouble(j['lng']) ?? 0,
        heading: _toDouble(j['heading']),
        speed: _toDouble(j['speed']),
        recordedAt: j['recorded_at'] != null
            ? DateTime.tryParse(j['recorded_at'] as String)
            : null,
      );
}

/// Kurye API servisi
class CourierService {
  /// GET /courier/orders — Kuryeye atanmış + bekleyen siparişler
  static Future<List<OrderDetail>> getOrders() async {
    final dio = await DioFactory.create();
    final res = await dio.get('/courier/orders');
    final raw = (res.data is Map) ? res.data['data'] : res.data;
    if (raw is! List) return [];
    final orders = <OrderDetail>[];
    for (final e in raw) {
      try {
        orders.add(OrderDetail.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Tek bir bozuk sipariş tüm listeyi çökertmesin; atla.
      }
    }
    return orders;
  }

  /// POST /courier/orders/{id}/accept — Siparişi üstlen
  static Future<OrderDetail> acceptOrder(String orderId) async {
    final dio = await DioFactory.create();
    final res = await dio.post('/courier/orders/$orderId/accept');
    return OrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /courier/orders/{id}/start — Yola çık (status → on_the_way)
  static Future<OrderDetail> startDelivery(String orderId) async {
    final dio = await DioFactory.create();
    final res = await dio.post('/courier/orders/$orderId/start');
    return OrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /courier/orders/{id}/complete — Teslim et (status → delivered)
  static Future<OrderDetail> completeDelivery(String orderId) async {
    final dio = await DioFactory.create();
    final res = await dio.post('/courier/orders/$orderId/complete');
    return OrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// GET /courier/profile — Kuryenin kendi profili (status dahil)
  static Future<Map<String, dynamic>> getProfile() async {
    final dio = await DioFactory.create();
    final res = await dio.get('/courier/profile');
    return (res.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /courier/availability — Çevrimiçi/çevrimdışı durumunu ayarla
  ///
  /// EKLENDİ (20 Haziran 2026) — Daha önce kurye panelindeki toggle sadece
  /// yerel UI state'ti, backend'e hiç ulaşmıyordu. Bu yüzden çevrimdışı
  /// görünen kurye hâlâ konum gönderebiliyor ve yeni sipariş push'u
  /// alabiliyordu. Artık gerçek durum backend'de couriers.status alanında.
  static Future<String> updateAvailability(bool online) async {
    final dio = await DioFactory.create();
    final res = await dio.patch('/courier/availability', data: {'online': online});
    return (res.data['data'] as Map<String, dynamic>)['status'] as String;
  }

  /// POST /courier/location — Canlı konum gönder
  static Future<void> pushLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    String? orderId,
  }) async {
    final dio = await DioFactory.create();
    await dio.post('/courier/location', data: {
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (orderId != null) 'order_id': orderId,
    });
  }

  /// GET /orders/{id}/courier-location — Müşteri: kurye konumunu çek
  static Future<CourierLocation?> getOrderCourierLocation(String orderId) async {
    final dio = await DioFactory.create();
    final res = await dio.get('/orders/$orderId/courier-location');
    final data = res.data['data'];
    if (data == null) return null;
    return CourierLocation.fromJson(data as Map<String, dynamic>);
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 403) {
        final msg = e.response?.data?['message'] as String?;
        return msg ?? 'Bu işlem için yetkiniz yok.';
      }
      if (code == 409) return 'Sipariş başka bir kurye tarafından alındı.';
      if (code == 422) {
        final msg = e.response?.data?['message'] as String?;
        return msg ?? 'Geçersiz işlem.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Sunucuya bağlanılamadı.';
      }
    }
    return 'Bir hata oluştu, tekrar dene.';
  }
}
