import 'package:equatable/equatable.dart';
import 'store.dart';

/// Sepetteki tek bir kalem: bir ürün + adedi + seçimler.
class CartItem extends Equatable {
  CartItem({
    required this.product,
    required this.quantity,
    this.note,
    this.selectedOptions = const {},
    double? unitPrice,
  }) : unitPrice = unitPrice ?? product.price;

  final Product product;
  final int quantity;
  final double unitPrice;

  /// Seçimlerden üretilen düz metin notu.
  final String? note;

  /// Ham seçimler — multi: List<String>, single: String?
  final Map<String, dynamic> selectedOptions;

  /// Bu kalemin toplam fiyatı (birim fiyat × adet).
  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    String? note,
    Map<String, dynamic>? selectedOptions,
  }) =>
      CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
        selectedOptions: selectedOptions ?? this.selectedOptions,
        unitPrice: unitPrice,
      );

  @override
  List<Object?> get props => [product.id, quantity, note, unitPrice, selectedOptions];
}

/// Uygulanan kupon.
class Coupon extends Equatable {
  const Coupon({
    required this.code,
    required this.discountRate,
    this.minOrder = 0,
  });

  final String code;
  final double discountRate;
  final double minOrder;

  double discountFor(double subtotal) =>
      subtotal >= minOrder ? subtotal * discountRate : 0;

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: j['code'] as String,
        discountRate: (j['discount_rate'] as num?)?.toDouble() ?? 0,
        minOrder: (j['min_order'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [code];
}
