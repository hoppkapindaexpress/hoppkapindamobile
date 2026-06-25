import '../models/store.dart';
import '../services/mock_data.dart';

/// Mağaza ve ürün verisine erişim arayüzü.
///
/// Şu an [MockData] döndürür; Faz 4'te bu metotların gövdesi Laravel API
/// çağrılarıyla değiştirilecek. Ekranlar yalnızca bu arayüze bağlı olduğu
/// için API'ye geçişte UI kodu değişmeyecek (Clean Architecture).
abstract interface class StoreRepository {
  Future<List<Campaign>> getCampaigns();
  Future<List<Store>> getStores({StoreType? type});
  Future<Store> getStore(String id);
  Future<List<Product>> getProducts(String storeId);
  Future<Product> getProduct(String id);
  Future<List<Product>> getPopularProducts();
}

/// Sahte veri ile çalışan repository implementasyonu.
///
/// Gerçek ağ gecikmesini taklit etmek için küçük bir delay eklenir;
/// böylece loading skeleton'ları test edilebilir.
class MockStoreRepository implements StoreRepository {
  const MockStoreRepository();

  static const _latency = Duration(milliseconds: 400);

  @override
  Future<List<Campaign>> getCampaigns() async {
    await Future.delayed(_latency);
    return MockData.campaigns;
  }

  @override
  Future<List<Store>> getStores({StoreType? type}) async {
    await Future.delayed(_latency);
    return type == null ? MockData.stores : MockData.storesByType(type);
  }

  @override
  Future<Store> getStore(String id) async {
    await Future.delayed(_latency);
    return MockData.storeById(id);
  }

  @override
  Future<List<Product>> getProducts(String storeId) async {
    await Future.delayed(_latency);
    return MockData.productsByStore(storeId);
  }

  @override
  Future<Product> getProduct(String id) async {
    await Future.delayed(_latency);
    return MockData.productById(id);
  }

  @override
  Future<List<Product>> getPopularProducts() async {
    await Future.delayed(_latency);
    return MockData.popularProducts;
  }
}
