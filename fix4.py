path = 'C:/hopp_kapinda/lib/features/orders/order_tracking_screen.dart'
content = open(path, encoding='utf-8').read()

old = """  static const _steps = [
    ('Sipariş alındı', 'Siparişin restorana iletildi',
        Icons.receipt_long_rounded),
    ('Onaylandı', 'Restoran siparişini onayladı', Icons.check_circle_rounded),
    ('Hazırlanıyor', 'Siparişin özenle hazırlanıyor',
        Icons.restaurant_rounded),
    ('Yola çıktı', 'Kurye sana doğru geliyor',
        Icons.delivery_dining_rounded),
    ('Teslim edildi', 'Afiyet olsun!', Icons.home_rounded),
  ];"""
new = """  static const _steps = [
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
  ];"""
content = content.replace(old, new)

old2 = """    final hasCourier = order.courierName != null;
    final isOnTheWay = order.status == 'on_the_way';
    final subtitle = hasCourier
        ? (isOnTheWay ? 'Sana doğru geliyor 🛵' : 'Kuryen atandı')
        : (order.stepIndex >= 3
            ? 'Kurye atanıyor...'
            : 'Henüz kurye atanmadı');"""
new2 = """    final hasCourier = order.courierName != null;
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
            : 'Henüz kurye atanmadı');"""
content = content.replace(old2, new2)

open(path, 'w', encoding='utf-8').write(content)
print('order_tracking_screen.dart OK')
