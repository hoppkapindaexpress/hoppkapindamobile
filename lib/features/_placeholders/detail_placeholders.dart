import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';

/// 2. turda tam olarak inşa edilecek detay ekranları için
/// geçici ama derlenebilir placeholder'lar.
/// Router'ın tüm rotaları bağlaması ve uygulamanın baştan sona
/// gezilebilmesi için buradalar.

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => _ComingSoon(
        title: 'Restoran Detayı',
        subtitle: 'ID: $id\n2. turda: kapak görseli, menü, ürün kartları',
        icon: Icons.storefront_rounded,
      );
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => _ComingSoon(
        title: 'Ürün Detayı',
        subtitle: 'ID: $id\n2. turda: büyük görsel, içindekiler, adet seçici',
        icon: Icons.fastfood_rounded,
      );
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => _ComingSoon(
        title: 'Sipariş Takibi',
        subtitle: 'Sipariş: $id\n2. turda: canlı harita, kurye kartı, durum çizgisi',
        icon: Icons.delivery_dining_rounded,
      );
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(title: title, message: subtitle, icon: icon),
    );
  }
}
