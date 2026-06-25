import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_item.dart';
import '../../models/store.dart';
/// Sepetin tüm anlık durumu.
class CartState extends Equatable {
  const CartState({this.items = const [], this.coupon});
  final List<CartItem> items;
  final Coupon? coupon;
  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get discount => coupon?.discountFor(subtotal) ?? 0;
  double get deliveryFee {
    if (items.isEmpty) return 0;
    return subtotal >= 150 ? 0 : 19.90;
  }
  double get total => subtotal - discount + deliveryFee;
  bool get isEmpty => items.isEmpty;
  CartState copyWith({
    List<CartItem>? items,
    Coupon? coupon,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
    );
  }
  @override
  List<Object?> get props => [items, coupon];
}
/// Sepet işlemlerini yöneten Notifier.
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();
  /// Ürünü sepete ekler.
  /// [selectedOptions] seçimlerdir — varsa seçenekli, yoksa seçeneksiz ürün.
  void add(
    Product product, {
    int quantity = 1,
    String? note,
    Map<String, dynamic> selectedOptions = const {},
    double? unitPrice,
  }) {
    final items = [...state.items];
    final effectivePrice = unitPrice ?? product.price;
    // Seçenekler varsa seçenekli ürün, yoksa seçeneksiz
    if (selectedOptions.isEmpty) {
      // Seçeneksiz ürün — varsa adedini artır
      final index = items.indexWhere(
        (i) => i.product.id == product.id && i.selectedOptions.isEmpty,
      );
      if (index >= 0) {
        items[index] = items[index].copyWith(
          quantity: items[index].quantity + quantity,
        );
      } else {
        items.add(CartItem(
          product: product,
          quantity: quantity,
          unitPrice: effectivePrice,
        ));
      }
    } else {
      // Seçenekli ürün — aynı seçenekler varsa adedini artır, yoksa yeni kalem
      final index = items.indexWhere(
        (i) => i.product.id == product.id && 
              i.selectedOptions.toString() == selectedOptions.toString(),
      );
      if (index >= 0) {
        items[index] = items[index].copyWith(
          quantity: items[index].quantity + quantity,
          selectedOptions: selectedOptions,
        );
      } else {
        items.add(CartItem(
          product: product,
          quantity: quantity,
          note: note,
          selectedOptions: selectedOptions,
          unitPrice: effectivePrice,
        ));
      }
    }
    state = state.copyWith(items: items);
  }
  void decrement(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    final items = [...state.items];
    final current = items[index];
    if (current.quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    state = state.copyWith(items: items);
  }
  void remove(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }
  int quantityOf(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    return index >= 0 ? state.items[index].quantity : 0;
  }
  void setCoupon(Coupon coupon) => state = state.copyWith(coupon: coupon);
  void removeCoupon() => state = state.copyWith(clearCoupon: true);
  void clear() => state = const CartState();
}
final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
