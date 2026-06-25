import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';
import '../repositories/store_repository.dart';
import '../repositories/mock_store_repository.dart';
import '../repositories/api_store_repository.dart';

// ============================================================
// FAZ 4 GEÇİŞ ANAHTARI
// ============================================================
//
// Mock'tan gerçek API'ye geçmek için:
//   1. useRealApi = true yap
//   2. DioFactory.baseUrl'i .env'den al (flutter_dotenv)
//   3. flutter pub get && flutter run
//
// ⚠️ Başka hiçbir dosyaya dokunmana gerek yok.
// ============================================================
const bool _useRealApi = false; // true → Laravel API, false → Mock

// ---------------------------------------------------------------
// Repository provider — tek geçiş noktası
// ---------------------------------------------------------------
final storeRepositoryProvider = FutureProvider<StoreRepository>((ref) async {
  if (_useRealApi) {
    final dio = await DioFactory.create();
    return ApiStoreRepository(dio);
  }
  return const MockStoreRepository();
});

// ---------------------------------------------------------------
// Aşağıdaki providerlar değişmedi — sadece repository'den okur
// ---------------------------------------------------------------

/// Kampanya listesi (Home slider).
final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getCampaigns();
});

/// Popüler ürünler (Home).
final popularProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getPopularProducts();
});

/// Tüm mağazalar (Home listesi).
final storesProvider = FutureProvider<List<Store>>((ref) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getStores();
});

/// Belirli bir mağazanın detayı (id'ye göre).
final storeProvider = FutureProvider.family<Store, String>((ref, id) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getStore(id);
});

/// Bir mağazanın ürünleri (restoran detay ekranı).
final storeProductsProvider = FutureProvider.family<List<Product>, String>((ref, storeId) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getProducts(storeId);
});

/// Tek bir ürün detayı.
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getProduct(id);
});
