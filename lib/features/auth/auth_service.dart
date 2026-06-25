import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../repositories/api_store_repository.dart';
import '../../services/notification_service.dart';

/// Sunucudan dönen kullanıcı + token sonucu.
class AuthResult {
  const AuthResult({required this.name, required this.email, this.phone, this.token, this.role});
  final String name;
  final String email;
  final String? phone;
  final String? token;
  /// 'user', 'courier' veya 'admin' — API'den gelir, yönlendirme için kontrol edilir.
  final String? role;
}

/// Auth API çağrılarını yapan ve token'ı saklayan servis.
///
/// Token, DioFactory'nin okuduğu 'auth_token' anahtarına yazılır; böylece
/// sonraki tüm API istekleri otomatik olarak Authorization header'ı taşır.
class AuthService {
  AuthService._(this._dio);

  final Dio _dio;

  static const String tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _nameKey = 'auth_name';
  static const String _phoneKey = 'auth_phone';
  static const String _roleKey = 'auth_role';

  /// Token taşımayan ham Dio (login/register henüz token yokken çağrılır).
  static Future<AuthService> create() async {
    final dio = Dio(BaseOptions(
      baseUrl: DioFactory.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    return AuthService._(dio);
  }

  /// POST /auth/login
  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(res.data);
  }

  /// POST /auth/register
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      if (address != null && address.isNotEmpty) 'default_address': address,
    });
    return _handleAuthResponse(res.data);
  }

  /// POST /auth/logout — sunucudaki token'ı iptal eder, yereli temizler.
  Future<void> logout(String? token) async {
    try {
      if (token != null) {
        final authed = Dio(BaseOptions(
          baseUrl: DioFactory.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
        await authed.post('/auth/logout');
      }
    } catch (_) {
      // Sunucu hatası olsa bile yerel oturumu kapatmaya devam et.
    }
    await clearSession();
  }

  /// Sunucu yanıtını işler: token + kullanıcıyı kaydeder.
  Future<AuthResult> _handleAuthResponse(dynamic body) async {
    final data = body['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final token = data['token'] as String?;

    final result = AuthResult(
      name: user['name'] as String,
      email: user['email'] as String,
      phone: user['phone'] as String?,
      token: token,
      role: user['role'] as String? ?? 'user',
    );

    // API role göndermiyorsa courier endpoint'ini kontrol et
    final resolvedRole = await _resolveRole(result);
    final finalResult = AuthResult(
      name: result.name,
      email: result.email,
      phone: result.phone,
      token: result.token,
      role: resolvedRole,
    );

    await _persistSession(finalResult);
    return finalResult;
  }

  /// Login response'unda role yoksa /courier/orders endpoint'ine istek at.
  /// 200 → courier, aksi → mevcut role'ü koru.
  Future<String> _resolveRole(AuthResult r) async {
    final rawRole = r.role ?? 'user';
    if (rawRole == 'courier') return 'courier';
    if (r.token == null) return rawRole;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: DioFactory.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${r.token}',
        },
        validateStatus: (s) => s != null && s < 500,
      ));
      final res = await dio.get('/courier/orders');
      if (res.statusCode == 200) return 'courier';
      return 'status_${res.statusCode}';
    } catch (e) {
      return 'err_${e.runtimeType}';
    }
    return rawRole;
  }

  Future<void> _persistSession(AuthResult r) async {
    final prefs = await SharedPreferences.getInstance();
    if (r.token != null) await prefs.setString(tokenKey, r.token!);
    await prefs.setString(_emailKey, r.email);
    await prefs.setString(_nameKey, r.name);
    if (r.phone != null) await prefs.setString(_phoneKey, r.phone!);
    if (r.role != null) await prefs.setString(_roleKey, r.role!);

    // FCM token'ı backend'e gönder
    if (r.token != null) {
      final notif = NotificationService.instance;
      await notif.sendTokenToBackend(r.token!);
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
  }

  /// Kayıtlı oturumu okur (uygulama açılışında).
  static Future<AuthResult?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final name = prefs.getString(_nameKey);
    final token = prefs.getString(tokenKey);
    if (email == null || name == null) return null;
    return AuthResult(
      name: name,
      email: email,
      phone: prefs.getString(_phoneKey),
      token: token,
      role: prefs.getString(_roleKey) ?? 'user',
    );
  }

  /// Dio hatasını kullanıcı dostu Türkçe mesaja çevirir.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      if (code == 422 && data is Map) {
        // Laravel validation hatası: ilk mesajı al.
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (data['message'] != null) return data['message'].toString();
      }
      if (code == 401) return 'E-posta veya şifre hatalı.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Sunucuya bağlanılamadı. İnternet bağlantını kontrol et.';
      }
    }
    return 'Bir hata oluştu, lütfen tekrar dene.';
  }
}
