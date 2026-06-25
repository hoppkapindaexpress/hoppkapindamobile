import '../models/store.dart';

/// Geçici sahte veri kaynağı.
///
/// Faz 3'te repository + Laravel API ile değiştirilecek. Tüm ekranlar
/// bu sınıf üzerinden beslenir; böylece gerçek API'ye geçiş tek noktadan olur.
abstract final class MockData {
  MockData._();

  static const List<Campaign> campaigns = [
    Campaign(
      id: 'c1',
      title: 'İlk siparişe %40',
      subtitle: 'HOPP40 koduyla kapına gelsin',
      code: 'HOPP40',
    ),
    Campaign(
      id: 'c2',
      title: 'Markette 80₺ üzeri',
      subtitle: 'Teslimat bizden, 20 dakikada',
      code: 'MARKET20',
    ),
    Campaign(
      id: 'c3',
      title: 'Tatlı saatleri',
      subtitle: 'Her gün 15:00-18:00 arası %25',
      code: 'TATLI25',
    ),
  ];

  static const List<Store> stores = [
    Store(
      id: 's1',
      name: 'Burger House',
      type: StoreType.restaurant,
      rating: 4.7,
      reviewCount: 1240,
      deliveryTimeMinutes: 25,
      deliveryFee: 0,
      minOrder: 120,
      tags: ['Burger', 'Fast Food', 'Amerikan'],
      coverColor: 0,
    ),
    Store(
      id: 's2',
      name: 'Pizza Roma',
      type: StoreType.restaurant,
      rating: 4.5,
      reviewCount: 890,
      deliveryTimeMinutes: 30,
      deliveryFee: 15,
      minOrder: 100,
      tags: ['Pizza', 'İtalyan'],
      coverColor: 1,
    ),
    Store(
      id: 's3',
      name: 'Sushi Master',
      type: StoreType.restaurant,
      rating: 4.8,
      reviewCount: 560,
      deliveryTimeMinutes: 35,
      deliveryFee: 25,
      minOrder: 200,
      tags: ['Sushi', 'Japon', 'Deniz Ürünleri'],
      coverColor: 2,
    ),
    Store(
      id: 's4',
      name: 'Migros Hemen',
      type: StoreType.market,
      rating: 4.6,
      reviewCount: 3200,
      deliveryTimeMinutes: 15,
      deliveryFee: 0,
      minOrder: 80,
      tags: ['Market', 'Gıda', 'Temizlik'],
      coverColor: 3,
    ),
    Store(
      id: 's5',
      name: 'Tatlı Dünyası',
      type: StoreType.dessert,
      rating: 4.9,
      reviewCount: 410,
      deliveryTimeMinutes: 20,
      deliveryFee: 10,
      minOrder: 60,
      tags: ['Tatlı', 'Pasta', 'Dondurma'],
      coverColor: 4,
    ),
    Store(
      id: 's6',
      name: 'Kebapçı Usta',
      type: StoreType.restaurant,
      rating: 4.4,
      reviewCount: 720,
      deliveryTimeMinutes: 28,
      deliveryFee: 12,
      minOrder: 90,
      tags: ['Kebap', 'Türk Mutfağı'],
      coverColor: 5,
    ),
  ];

  static const List<Product> products = [
    Product(
      id: 'p1',
      storeId: 's1',
      name: 'Cheeseburger Menü',
      description: 'Dana köfte, cheddar, patates kızartması ve içecek',
      price: 69.90,
      oldPrice: 89.90,
      ingredients: ['Dana köfte', 'Cheddar', 'Marul', 'Domates', 'Özel sos'],
      isPopular: true,
    ),
    Product(
      id: 'p2',
      storeId: 's1',
      name: 'Double Burger',
      description: 'Çift köfte, çift peynir, bol soslu',
      price: 94.50,
      ingredients: ['2x Dana köfte', '2x Cheddar', 'Turşu', 'Soğan'],
      isPopular: true,
    ),
    Product(
      id: 'p3',
      storeId: 's1',
      name: 'Çıtır Tavuk Burger',
      description: 'Çıtır tavuk göğsü, ranch sos',
      price: 64.00,
      ingredients: ['Çıtır tavuk', 'Marul', 'Ranch sos'],
    ),
    Product(
      id: 'p4',
      storeId: 's2',
      name: 'Margherita Pizza',
      description: 'Mozzarella, domates sosu, fesleğen',
      price: 119.50,
      isPopular: true,
      ingredients: ['Mozzarella', 'Domates sosu', 'Fesleğen'],
    ),
    Product(
      id: 'p5',
      storeId: 's5',
      name: 'Tiramisu',
      description: 'Ev yapımı, mascarpone kremalı',
      price: 54.00,
      isPopular: true,
      ingredients: ['Mascarpone', 'Kahve', 'Kakao', 'Kedi dili'],
    ),
    Product(
      id: 'p6',
      storeId: 's5',
      name: 'San Sebastian Cheesecake',
      description: 'Karamelize üstü, yoğun krem peynir',
      price: 62.00,
      ingredients: ['Krem peynir', 'Krema', 'Şeker', 'Vanilya'],
    ),
  ];

  static List<Product> popularProducts =
      products.where((p) => p.isPopular).toList();

  static List<Store> storesByType(StoreType type) =>
      stores.where((s) => s.type == type).toList();

  static Store storeById(String id) =>
      stores.firstWhere((s) => s.id == id, orElse: () => stores.first);

  static List<Product> productsByStore(String storeId) =>
      products.where((p) => p.storeId == storeId).toList();

  static Product productById(String id) =>
      products.firstWhere((p) => p.id == id, orElse: () => products.first);
}
