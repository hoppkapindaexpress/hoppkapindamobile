import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favori ürün id'lerini SharedPreferences'a kaydeden provider.
/// Mağaza favorilerinden (favoritesProvider) bağımsızdır.
class ProductFavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'product_favorites';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.toSet();
  }

  Future<void> toggle(String productId) async {
    final next = Set<String>.from(state);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final productFavoritesProvider =
    NotifierProvider<ProductFavoritesNotifier, Set<String>>(
  ProductFavoritesNotifier.new,
);
