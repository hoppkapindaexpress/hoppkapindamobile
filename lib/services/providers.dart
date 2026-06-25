import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';
import '../repositories/store_repository.dart';
import '../repositories/api_store_repository.dart';

// ============================================================
//  FAZ 4 — MOCK / GERÇEK API GEÇİŞ ANAHTARI
// ============================================================
//
//  Mock'tan gerçek Laravel API'ye geçmek için TEK satır:
//      _useRealApi = true
//
//  Ardından DioFactory.baseUrl'i kendi sunucuna göre ayarla
//  (api_store_repository.dart içinde, ya da flutter_dotenv ile).
//
//  ⚠️ Başka HİÇBİR dosyaya dokunmana gerek yok — ekranlar yalnızca
//  aşağıdaki provider'lara bağlı; repository'nin mock mu API mi
//  olduğunu bilmezler (Clean Architecture).
// ============================================================
const bool _useRealApi = true;

/// Repository'nin tek örneği — mock/API geçişinin yapıldığı tek nokta.
///
/// FutureProvider'dır çünkü gerçek API modunda Dio'nun async kurulumu
/// (SharedPreferences'tan token okuma) gerekir.
final storeRepositoryProvider = FutureProvider<StoreRepository>((ref) async {
  if (_useRealApi) {
    final dio = await DioFactory.create();
    return ApiStoreRepository(dio);
  }
  return const MockStoreRepository();
});

// ---------------------------------------------------------------
//  Veri provider'ları — repository'den okur, mock/API'den habersiz.
// ---------------------------------------------------------------

/// Provider'ı [seconds] saniye canlı tutar, sonra cache'i bırakır.
///
/// Böylece kullanıcı ekrandan ayrılıp geri döndüğünde (ya da süre dolunca
/// ekrana tekrar girince) veri YENİDEN çekilir — admin panelden yapılan
/// fiyat/içerik değişiklikleri uygulamayı kapatmadan görünür.
void _cacheFor(Ref ref, {int seconds = 30}) {
  final link = ref.keepAlive();
  final timer = Timer(Duration(seconds: seconds), link.close);
  ref.onDispose(timer.cancel);
}

/// Kampanya listesi (Home slider).
final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  _cacheFor(ref);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getCampaigns();
});

/// Popüler ürünler (Home).
final popularProductsProvider = FutureProvider<List<Product>>((ref) async {
  _cacheFor(ref);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getPopularProducts();
});

/// Tüm mağazalar (Home listesi).
final storesProvider = FutureProvider<List<Store>>((ref) async {
  _cacheFor(ref);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getStores();
});

/// Belirli bir mağazanın detayı (id'ye göre).
final storeProvider = FutureProvider.family<Store, String>((ref, id) async {
  _cacheFor(ref, seconds: 15);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getStore(id);
});

/// Bir mağazanın ürünleri (restoran detay ekranı).
final storeProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, storeId) async {
  _cacheFor(ref, seconds: 15);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getProducts(storeId);
});

/// Tüm mağazaların ürünleri birleşik (Home — Tüm Ürünler).
/// Her ürüne ait mağazanın adı [Product.storeName] alanına inject edilir.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  _cacheFor(ref);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getPopularProducts();
});

/// Tek bir ürün detayı.
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  _cacheFor(ref, seconds: 15);
  final repo = await ref.watch(storeRepositoryProvider.future);
  return repo.getProduct(id);
});
