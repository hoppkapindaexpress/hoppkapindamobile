import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences örneğini sağlar.
///
/// `main()` içinde override edilir; böylece async başlatma tek seferde yapılır
/// ve provider'lar senkron erişebilir.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
);

/// Favori mağaza/ürün id'lerini yöneten ve kalıcı saklayan Notifier.
class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'favorites';

  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  void toggle(String id) {
    final updated = {...state};
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = updated;
    _persist();
  }

  bool isFavorite(String id) => state.contains(id);

  void _persist() {
    ref.read(sharedPrefsProvider).setStringList(_key, state.toList());
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
