import 'package:dio/dio.dart';
import '../../models/cart_item.dart';
import '../../repositories/api_store_repository.dart';

/// Kupon doğrulamasını gerçek API'ye bağlar.
///
/// `OrderService` ile aynı kalıbı izler: token'ı SharedPreferences'tan okuyan
/// [DioFactory.create] üzerinden çağrı yapar. Sunucu indirimi kendisi hesaplar;
/// biz sadece kodu ve sepet ara toplamını göndeririz.
class CouponService {
  /// POST /coupons/validate
  ///
  /// Geçerliyse [Coupon] döner, geçersiz/eksik tutar durumunda (422) `null`.
  static Future<Coupon?> validate(String code, double subtotal) async {
    final dio = await DioFactory.create();
    try {
      final res = await dio.post('/coupons/validate', data: {
        'code': code,
        'subtotal': subtotal,
      });
      final body = res.data as Map<String, dynamic>;
      if (body['valid'] == true && body['data'] != null) {
        return Coupon.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      // 422 → kupon geçersiz veya minimum tutar sağlanmadı.
      if (e.response?.statusCode == 422) return null;
      rethrow;
    }
  }
}
