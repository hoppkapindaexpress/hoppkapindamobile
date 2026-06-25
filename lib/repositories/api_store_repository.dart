import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';
import 'store_repository.dart';

/// Laravel REST API'ye bağlanan gerçek repository implementasyonu.
///
/// routes/api.php'deki v1 endpoint yapısını tam olarak yansıtır.
/// Endpoint grupları:
///   - Katalog (herkese açık)
///   - Kullanıcı işlemleri (auth:sanctum)
///   - Admin işlemleri (auth:sanctum + admin rolü)
class ApiStoreRepository implements StoreRepository {
  ApiStoreRepository(this._dio);

  final Dio _dio;

  // ───────────────────────────────────────────
  //  Katalog (herkese açık)
  // ───────────────────────────────────────────

  @override
  Future<List<Campaign>> getCampaigns() async {
    final res = await _dio.get('/campaigns');
    return _list(res.data, Campaign.fromJson);
  }

  @override
  Future<List<Store>> getStores({StoreType? type}) async {
    final res = await _dio.get('/stores',
        queryParameters: type == null ? null : {'type': type.name});
    return _list(res.data, Store.fromJson);
  }

  @override
  Future<Store> getStore(String id) async {
    final res = await _dio.get('/stores/$id');
    return Store.fromJson(res.data['data']);
  }

  @override
  Future<List<Product>> getProducts(String storeId) async {
    final res = await _dio.get('/stores/$storeId/products');
    return _list(res.data, Product.fromJson);
  }

  @override
  Future<Product> getProduct(String id) async {
    final res = await _dio.get('/products/$id');
    return Product.fromJson(res.data['data']);
  }

  @override
  Future<List<Product>> getPopularProducts() async {
    final res = await _dio.get('/products/popular');
    return _list(res.data, Product.fromJson);
  }

  // ───────────────────────────────────────────
  //  Kullanıcı işlemleri (auth:sanctum)
  // ───────────────────────────────────────────

  Future<List<dynamic>> getOrders() async {
    final res = await _dio.get('/orders');
    return (res.data['data'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    final res = await _dio.get('/orders/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final res = await _dio.post('/orders', data: payload);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getFavorites() async {
    final res = await _dio.get('/favorites');
    return (res.data['data'] as List?) ?? [];
  }

  Future<bool> toggleFavorite(String storeId) async {
    final res = await _dio.post('/favorites/$storeId');
    return res.data['favorited'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    final res = await _dio.post('/coupons/validate', data: {
      'code': code,
      'subtotal': subtotal,
    });
    return res.data as Map<String, dynamic>;
  }

  // ───────────────────────────────────────────
  //  Admin işlemleri (auth:sanctum + role=admin)
  //  PATCH /orders/{id}/status
  //  Store / Product / Campaign / Coupon CRUD
  // ───────────────────────────────────────────

  /// Sipariş durumunu günceller.
  /// [status]: pending | confirmed | preparing | on_the_way | delivered
  Future<Map<String, dynamic>> updateOrderStatus(String id, String status) async {
    final res = await _dio.patch('/orders/$id/status', data: {'status': status});
    return res.data['data'] as Map<String, dynamic>;
  }

  // ── Mağaza ──
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> data) async {
    final res = await _dio.post('/stores', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStore(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/stores/$id', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteStore(String id) async {
    await _dio.delete('/stores/$id');
  }

  // ── Ürün ──
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  // ── Kampanya ──
  Future<Map<String, dynamic>> createCampaign(Map<String, dynamic> data) async {
    final res = await _dio.post('/campaigns', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCampaign(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/campaigns/$id', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCampaign(String id) async {
    await _dio.delete('/campaigns/$id');
  }

  // ── Kupon ──
  Future<List<dynamic>> getCoupons() async {
    final res = await _dio.get('/coupons');
    return (res.data['data'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    final res = await _dio.post('/coupons', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCoupon(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/coupons/$id', data: data);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleCoupon(String id) async {
    final res = await _dio.patch('/coupons/$id/toggle');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCoupon(String id) async {
    await _dio.delete('/coupons/$id');
  }

  // ── Admin: Kullanıcılar ──
  Future<List<dynamic>> getAdminUsers() async {
    final res = await _dio.get('/admin/users');
    return (res.data['data'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> getAdminUser(String id) async {
    final res = await _dio.get('/admin/users/$id');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ───────────────────────────────────────────
  //  Helper
  // ───────────────────────────────────────────

  List<T> _list<T>(dynamic body, T Function(Map<String, dynamic>) fromJson) {
    final raw = (body is Map) ? body['data'] : body;
    return (raw as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ============================================================
//  Dio Factory — token yönetimi + interceptor'lar
// ============================================================

class DioFactory {
  DioFactory._();

  static const String baseUrl =
      'https://api.hoppkapinda.com/api/v1';

  static Future<Dio> create() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    // Debug modda tüm istek/yanıtları logla
    assert(() {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
      return true;
    }());

    // 401 → token geçersiz (session sona ermiş)
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response?.statusCode == 401) {
            // TODO: auth_provider'ı tetikle → login ekranına yönlendir
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }
}
