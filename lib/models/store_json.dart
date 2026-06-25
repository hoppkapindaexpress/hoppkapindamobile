/// store_json.dart
/// Store, Product, Campaign modellerine fromJson factory'leri ekler.
/// Faz 4'te API geçişi için kullanılır; Faz 3 mock veriyle de uyumludur.

import 'store.dart';

// ---------------------------------------------------------------
// Campaign.fromJson
// ---------------------------------------------------------------
extension CampaignJson on Campaign {
  static Campaign fromJson(Map<String, dynamic> j) => Campaign(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        code: j['code'] as String,
      );
}

// ---------------------------------------------------------------
// Store.fromJson
// ---------------------------------------------------------------
extension StoreJson on Store {
  static Store fromJson(Map<String, dynamic> j) => Store(
        id: j['id'] as String,
        name: j['name'] as String,
        type: _storeType(j['type'] as String),
        rating: (j['rating'] as num).toDouble(),
        reviewCount: j['review_count'] as int,
        deliveryTimeMinutes: j['delivery_time_minutes'] as int,
        deliveryFee: (j['delivery_fee'] as num).toDouble(),
        minOrder: (j['min_order'] as num).toDouble(),
        tags: List<String>.from(j['tags'] ?? []),
        coverColor: j['cover_color_seed'] as int?,
        isFavorite: j['is_favorite'] as bool? ?? false,
      );

  static StoreType _storeType(String raw) => switch (raw) {
        'market'  => StoreType.market,
        'dessert' => StoreType.dessert,
        _         => StoreType.restaurant,
      };
}

// ---------------------------------------------------------------
// Product.fromJson
// ---------------------------------------------------------------
extension ProductJson on Product {
  static Product fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        storeId: j['store_id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        price: (j['price'] as num).toDouble(),
        oldPrice: j['old_price'] != null ? (j['old_price'] as num).toDouble() : null,
        ingredients: List<String>.from(j['ingredients'] ?? []),
        isPopular: j['is_popular'] as bool? ?? false,
      );
}
