import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/cart_item.dart';
import '../../repositories/api_store_repository.dart';

/// Sayı ya da string (örn. "36.25") gelen değeri güvenle double'a çevirir.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Basit lat/lng nokta (route polyline için).
class LatLngPoint {
  const LatLngPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}


/// Oluşturulan siparişin özeti (API yanıtından).
class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.total,
  });
  final String id;
  final String status;
  final double total;
}

/// Sipariş servisi — kayıtlı kullanıcı ve misafir akışlarını yönetir.
class OrderService {
  /// Misafir siparişi için token'sız Dio örneği.
  static Dio _guestDio() => Dio(BaseOptions(
        baseUrl: DioFactory.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ));

  /// POST /orders veya POST /orders/guest
  static Future<OrderSummary> createOrder({
    required String storeId,
    required List<CartItem> items,
    required String deliveryAddress,
    required String phone,
    Map<String, dynamic>? address,
    String? couponCode,
    String paymentMethod = 'card',
    String? guestName,
    String? courierNote,
  }) async {
    // DEBUG — silinecek
    for (final item in items) {
      debugPrint('🛒 ${item.product.name} | note: ${item.note} | opts: ${item.selectedOptions}');
    }
    final payload = {
      'store_id': storeId,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
      'phone': phone,
      if (guestName != null && guestName.isNotEmpty) 'guest_name': guestName,
      if (courierNote != null && courierNote.isNotEmpty) 'courier_note': courierNote,
      if (address != null) 'address': address,
      if (couponCode != null) 'coupon_code': couponCode,
      'items': items
          .map((i) => {
                'product_id': i.product.id,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
                if (i.note != null && i.note!.isNotEmpty) 'note': i.note,
                if (i.selectedOptions.isNotEmpty)
                  'options': i.selectedOptions['structured'] is List
                      ? i.selectedOptions['structured']
                      : i.selectedOptions.entries
                          .map((e) => {
                                'group': e.key,
                                'items': e.value is List ? e.value : [e.value],
                              })
                          .toList(),
              })
          .toList(),
    };

    final Response<dynamic> res;

    if (guestName != null && guestName.isNotEmpty) {
      final dio = _guestDio();
      res = await dio.post('/orders/guest', data: payload);
    } else {
      final dio = await DioFactory.create();
      res = await dio.post('/orders', data: payload);
    }

    final data = res.data['data'] as Map<String, dynamic>;
    return OrderSummary(
      id: data['id'].toString(),
      status: data['status'] as String? ?? 'pending',
      total: _toDouble(data['total']) ?? 0,
    );
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401) return 'Sipariş vermek için giriş yapmalısın.';
      if (code == 422) return 'Sipariş bilgileri eksik veya hatalı.';
      if (e.type == DioExceptionType.connectionError) {
        return 'Sunucuya bağlanılamadı.';
      }
    }
    return 'Sipariş oluşturulamadı, tekrar dene.';
  }

  /// GET /orders/{id} — tek siparişin güncel durumunu çeker.
  static Future<OrderDetail> getOrder(String id) async {
    final dio = await DioFactory.create();
    final res = await dio.get('/orders/$id');
    return OrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// GET /orders — kullanıcının tüm siparişlerini çeker.
  static Future<List<OrderDetail>> getOrders() async {
    final dio = await DioFactory.create();
    final res = await dio.get('/orders');
    final raw = (res.data is Map) ? res.data['data'] : res.data;
    return (raw as List)
        .map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /orders/{id}/route — kurye -> teslimat gerçek yol çizgisi (ORS).
  /// Yol noktalarının listesini döndürür; yoksa boş liste.
  static Future<List<LatLngPoint>> getOrderRoute(String id) async {
    try {
      final dio = await DioFactory.create();
      final res = await dio.get('/orders/$id/route');
      final data = res.data is Map ? res.data['data'] : null;
      if (data == null) return [];
      final pts = data['points'] as List?;
      if (pts == null) return [];
      return pts
          .map((e) => LatLngPoint(
                _toDouble(e['lat']) ?? 0,
                _toDouble(e['lng']) ?? 0,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// PATCH /orders/{id}/status — Admin: sipariş durumunu günceller.
  static Future<OrderDetail> updateOrderStatus(String id, String status) async {
    final dio = await DioFactory.create();
    final res =
        await dio.patch('/orders/$id/status', data: {'status': status});
    return OrderDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

/// Sipariş takibi için zengin sipariş modeli.
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.status,
    required this.total,
    this.storeName,
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.estimatedDeliveryAt,
    this.deliveryAddress,
    this.addressLat,
    this.addressLng,
    this.courierNote,
  });

  final String id;
  final String status;
  final double total;
  final String? storeName;

  /// Atanan kuryenin id'si (null → henüz kurye yok)
  final String? courierId;

  final String? courierName;
  final String? courierPhone;
  final DateTime? estimatedDeliveryAt;
  final String? deliveryAddress;

  /// Teslimat adresinin koordinatları (harita için)
  final double? addressLat;
  final double? addressLng;

  /// Müşterinin kurye için yazdığı not (örn. "Kapı kodu 1234")
  final String? courierNote;

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final addr = j['address'] as Map<String, dynamic>?;
    return OrderDetail(
      id: j['id'].toString(),
      status: j['status'] as String? ?? 'pending',
      total: _toDouble(j['total']) ?? 0,
      storeName: j['store_name'] as String?,
      courierId: j['courier_id']?.toString(),
      courierName: j['courier_name'] as String?,
      courierPhone: j['courier_phone'] as String?,
      deliveryAddress: addr?['full_address'] as String? ??
          j['delivery_address'] as String?,
      addressLat: _toDouble(addr?['lat']) ?? _toDouble(j['delivery_lat']),
      addressLng: _toDouble(addr?['lng']) ?? _toDouble(j['delivery_lng']),
      courierNote: j['courier_note'] as String?,
      estimatedDeliveryAt: j['estimated_delivery_at'] is String
          ? DateTime.tryParse(j['estimated_delivery_at'] as String)
          : null,
    );
  }

  int get stepIndex => switch (status) {
        'pending' => 0,
        'confirmed' => 1,
        'preparing' => 2,
        'ready' => 3,
        'on_the_way' => 4,
        'delivered' => 5,
        'cancelled' => -1,
        _ => 0,
      };

  bool get isCancelled => status == 'cancelled';

  bool get isActive => status != 'delivered' && status != 'cancelled';

  String get statusLabel => switch (status) {
        'pending' => 'Onay bekliyor',
        'confirmed' => 'Onaylandı',
        'preparing' => 'Hazırlanıyor',
        'ready' => 'Kurye bekleniyor',
        'on_the_way' => 'Yolda',
        'delivered' => 'Teslim edildi',
        'cancelled' => 'İptal edildi',
        _ => status,
      };
}
