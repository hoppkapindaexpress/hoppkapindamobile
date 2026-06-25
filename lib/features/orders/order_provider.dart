import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_service.dart';

/// Tek siparişin güncel detayını çeker (takip ekranı için).
///
/// `.family` ile sipariş id'sine göre çalışır. Takip ekranı bunu izler;
/// durum değişince (admin panel ilerletince) ekran otomatik güncellenir.
final orderDetailProvider =
    FutureProvider.family<OrderDetail, String>((ref, id) async {
  return OrderService.getOrder(id);
});

/// Kullanıcının tüm siparişlerini çeker (Siparişlerim ekranı).
final ordersProvider = FutureProvider<List<OrderDetail>>((ref) async {
  return OrderService.getOrders();
});
