import 'package:equatable/equatable.dart';

/// Mağaza türü — yemek, market ve tatlı ayrımı için.
enum StoreType { restaurant, market, dessert }

extension StoreTypeX on StoreType {
  String get label => switch (this) {
        StoreType.restaurant => 'Yemek',
        StoreType.market => 'Market',
        StoreType.dessert => 'Tatlı',
      };
}

/// Bir restoran / market / tatlıcı.
class Store extends Equatable {
  const Store({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    required this.minOrder,
    required this.tags,
    this.coverColor,
    this.imageUrl,
    this.isFavorite = false,
  });

  /// API JSON'undan Store üretir (Laravel StoreResource çıktısı)
  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j['id'].toString(),
        name: j['name'] as String,
        type: _typeFromString(j['type'] as String?),
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
        deliveryTimeMinutes:
            (j['delivery_time_minutes'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['delivery_fee'] as num?)?.toDouble() ?? 0,
        minOrder: (j['min_order'] as num?)?.toDouble() ?? 0,
        tags: List<String>.from(j['tags'] ?? const []),
        coverColor: (j['cover_color_seed'] as num?)?.toInt(),
        imageUrl: (j['cover_image'] as String?) ?? (j['image'] as String?),
        isFavorite: j['is_favorite'] as bool? ?? false,
      );

  static StoreType _typeFromString(String? raw) => switch (raw) {
        'market' => StoreType.market,
        'dessert' => StoreType.dessert,
        _ => StoreType.restaurant,
      };

  final String id;
  final String name;
  final StoreType type;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMinutes;
  final double deliveryFee;
  final double minOrder;
  final List<String> tags;
  final int? coverColor;
  final String? imageUrl;
  final bool isFavorite;

  String get deliveryTimeLabel =>
      '$deliveryTimeMinutes-${deliveryTimeMinutes + 10} dk';
  String get deliveryFeeLabel => deliveryFee == 0
      ? 'Ücretsiz teslimat'
      : '₺${deliveryFee.toStringAsFixed(0)} teslimat';

  Store copyWith({bool? isFavorite}) => Store(
        id: id,
        name: name,
        type: type,
        rating: rating,
        reviewCount: reviewCount,
        deliveryTimeMinutes: deliveryTimeMinutes,
        deliveryFee: deliveryFee,
        minOrder: minOrder,
        tags: tags,
        coverColor: coverColor,
        imageUrl: imageUrl,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  List<Object?> get props => [id, isFavorite];
}

/// Ürün kategorisi (restoran içi menü grubu veya market kategorisi).
class ProductCategory extends Equatable {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.productIds,
  });

  final String id;
  final String name;
  final List<String> productIds;

  @override
  List<Object?> get props => [id];
}

/// Seçenek kalemi — isim + opsiyonel fiyat farkı.
class ProductOptionItem extends Equatable {
  const ProductOptionItem({required this.name, this.price = 0});

  /// JSON'dan üretir — eski format (string) ve yeni format (obje) desteklenir.
  factory ProductOptionItem.fromJson(dynamic raw) {
    if (raw is String) return ProductOptionItem(name: raw);
    final m = raw as Map<String, dynamic>;
    return ProductOptionItem(
      name: m['name'] as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (price > 0) 'price': price,
      };

  final String name;
  final double price; // 0 = ücretsiz

  bool get hasPriceAddon => price > 0;

  /// Gösterim etiketi: "Kola" veya "Kola  +₺25.00"
  String get label =>
      hasPriceAddon ? '\$name  +₺\${price.toStringAsFixed(2)}' : name;

  @override
  List<Object?> get props => [name, price];
}

/// Bir ürün seçenek grubu — örn. "Ekstra Malzeme" veya "İçecekler".
class ProductOptionGroup extends Equatable {
  const ProductOptionGroup({
    required this.group,
    required this.type,
    required this.items,
  });

  factory ProductOptionGroup.fromJson(Map<String, dynamic> j) =>
      ProductOptionGroup(
        group: j['group'] as String,
        type: j['type'] as String,
        items: (j['items'] as List? ?? [])
            .map((e) => ProductOptionItem.fromJson(e))
            .toList(),
      );

  final String group;
  final String type; // 'single' | 'multi'
  final List<ProductOptionItem> items;

  bool get isMulti => type == 'multi';
  bool get isSingle => type == 'single';

  @override
  List<Object?> get props => [group, type, items];
}

/// Tek bir ürün.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    this.ingredients = const [],
    this.options = const [],
    this.isPopular = false,
    this.imageUrl,
    this.storeName,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
  });

  /// API JSON'undan Product üretir (Laravel ProductResource çıktısı).
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'].toString(),
        storeId: j['store_id'].toString(),
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        oldPrice: (j['old_price'] as num?)?.toDouble(),
        ingredients: List<String>.from(j['ingredients'] ?? const []),
        options: (j['options'] as List<dynamic>? ?? [])
            .map((g) =>
                ProductOptionGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
        isPopular: j['is_popular'] as bool? ?? false,
        imageUrl: j['image'] as String?,
        storeName: j['store_name'] as String?,
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final List<String> ingredients;
  final List<ProductOptionGroup> options;
  final bool isPopular;
  final String? imageUrl;
  final String? storeName;
  final double rating;
  final int reviewCount;
  final bool isFavorite;

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Mağaza adını inject etmek için kullanılır (allProductsProvider'da).
  Product withStoreName(String name) => Product(
        id: id,
        storeId: storeId,
        name: this.name,
        description: description,
        price: price,
        oldPrice: oldPrice,
        ingredients: ingredients,
        options: options,
        isPopular: isPopular,
        imageUrl: imageUrl,
        storeName: name,
        rating: rating,
        reviewCount: reviewCount,
        isFavorite: isFavorite,
      );

  Product copyWith({bool? isFavorite, double? priceOverride}) => Product(
        id: id,
        storeId: storeId,
        name: name,
        description: description,
        price: priceOverride ?? price,
        oldPrice: oldPrice,
        ingredients: ingredients,
        options: options,
        isPopular: isPopular,
        imageUrl: imageUrl,
        storeName: storeName,
        rating: rating,
        reviewCount: reviewCount,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  @override
  List<Object?> get props => [id, isFavorite];
}

/// Ana ekran kampanya slider'ı için banner.
class Campaign extends Equatable {
  const Campaign({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.code,
  });

  factory Campaign.fromJson(Map<String, dynamic> j) => Campaign(
        id: j['id'].toString(),
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        code: j['code'] as String? ?? '',
      );

  final String id;
  final String title;
  final String subtitle;
  final String code;

  @override
  List<Object?> get props => [id];
}
