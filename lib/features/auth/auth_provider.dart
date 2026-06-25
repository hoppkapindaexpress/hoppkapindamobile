import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/providers.dart';
import '../address/address_provider.dart';
import 'auth_service.dart';

/// Basit kullanıcı modeli.
class AppUser extends Equatable {
  const AppUser({required this.name, required this.email, this.phone, this.role = 'user'});

  final String name;
  final String email;
  final String? phone;
  /// 'user', 'courier' veya 'admin' — API'den gelir, yönlendirme ve middleware için kontrol edilir.
  final String role;

  bool get isAdmin => role == 'admin';
  bool get isCourier => role == 'courier';

  @override
  List<Object?> get props => [email];
}

/// Oturum durumu. [error] son işlemin hata mesajını taşır (null = hata yok).
class AuthState extends Equatable {
  const AuthState({this.user, this.loading = false, this.error});

  final AppUser? user;
  final bool loading;
  final String? error;

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [user, loading, error];
}

/// Giriş / kayıt / çıkış işlemlerini gerçek Laravel API'ye bağlayan Notifier.
///
/// Token, AuthService tarafından SharedPreferences'a yazılır; başarılı
/// giriş sonrası [storeRepositoryProvider] invalidate edilir, böylece Dio
/// yeni token ile yeniden kurulur ve korumalı uçlar çalışır.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Uygulama açılışında kayıtlı oturumu geri yükle.
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final saved = await AuthService.restoreSession();
    if (saved != null) {
      state = AuthState(
        user: AppUser(name: saved.name, email: saved.email,
            phone: saved.phone, role: saved.role ?? 'user'),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final service = await AuthService.create();
      final r = await service.login(email, password);
      state = AuthState(
        user: AppUser(name: r.name, email: r.email, phone: r.phone, role: r.role ?? 'user'),
      );
      _refreshApiSession();
      await ref.read(addressProvider.notifier).load(); // ← giriş sonrası adresleri çek
      return true;
    } catch (e) {
      state = AuthState(error: AuthService.errorMessage(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? address,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final service = await AuthService.create();
      final r = await service.register(
        name: name, email: email, phone: phone, password: password,
        address: address,
      );
      state = AuthState(
        user: AppUser(name: r.name, email: r.email, phone: r.phone, role: r.role ?? 'user'),
      );
      _refreshApiSession();
      await ref.read(addressProvider.notifier).load(); // ← kayıt sonrası adresleri çek
      return true;
    } catch (e) {
      state = AuthState(error: AuthService.errorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    final service = await AuthService.create();
    final token = await _currentToken();
    await service.logout(token);
    await ref.read(addressProvider.notifier).clearAll();
    state = const AuthState();
    _refreshApiSession();
  }

  Future<String?> _currentToken() async {
    final saved = await AuthService.restoreSession();
    return saved?.token;
  }

  /// Token değişince repository'yi yenile (Dio yeni token ile kurulsun).
  void _refreshApiSession() {
    ref.invalidate(storeRepositoryProvider);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
