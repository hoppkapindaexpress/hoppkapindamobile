import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/api_store_repository.dart';

// ============================================================
//  Model
// ============================================================

enum NotifType { orderStatus, campaign, system }

extension NotifTypeX on NotifType {
  String get icon => switch (this) {
        NotifType.orderStatus => '🛵',
        NotifType.campaign    => '🎁',
        NotifType.system      => 'ℹ️',
      };

  static NotifType fromString(String? s) => switch (s) {
        'order_status' => NotifType.orderStatus,
        'campaign'     => NotifType.campaign,
        _              => NotifType.system,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
  });

  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// Opsiyonel: bildirime tıklanınca gidilecek rota (örn: '/order/5/track')
  final String? actionRoute;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        actionRoute: actionRoute,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }

  /// API JSON'dan oluştur.
  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>?;
    return AppNotification(
      id:          j['id'].toString(),
      type:        NotifTypeX.fromString(j['type'] as String?),
      title:       j['title'] as String? ?? '',
      body:        j['body']  as String? ?? '',
      createdAt:   j['created_at'] != null
                       ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
                       : DateTime.now(),
      isRead:      j['is_read'] as bool? ?? false,
      actionRoute: data?['action_route'] as String?,
    );
  }
}

// ============================================================
//  Notifier — API'ye bağlı, kullanıcıya özel
// ============================================================

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

/// Okunmamış bildirim sayısı — badge için kullanılır.
final unreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .valueOrNull
      ?.where((n) => !n.isRead)
      .length ?? 0;
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  late Dio _dio;

  @override
  Future<List<AppNotification>> build() async {
    _dio = await DioFactory.create();
    return _fetchFromApi();
  }

  // ----------------------------------------------------------------
  //  API çağrıları
  // ----------------------------------------------------------------

  Future<List<AppNotification>> _fetchFromApi() async {
    final res = await _dio.get('/notifications');
    final raw = (res.data is Map) ? res.data['data'] : res.data;
    return (raw as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Bildirimleri API'den yenile.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFromApi);
  }

  // ----------------------------------------------------------------
  //  Okundu işaretleme
  // ----------------------------------------------------------------

  Future<void> markRead(String id) async {
    // Optimistic update
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (_) {
      // Hata olursa API'den tekrar çek
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((n) => n.copyWith(isRead: true))
          .toList(),
    );
    try {
      await _dio.post('/notifications/read-all');
    } catch (_) {
      await refresh();
    }
  }

  // ----------------------------------------------------------------
  //  Silme
  // ----------------------------------------------------------------

  Future<void> remove(String id) async {
    state = AsyncData(
      (state.valueOrNull ?? []).where((n) => n.id != id).toList(),
    );
    try {
      await _dio.delete('/notifications/$id');
    } catch (_) {
      await refresh();
    }
  }

  Future<void> clearAll() async {
    state = const AsyncData([]);
    try {
      await _dio.delete('/notifications');
    } catch (_) {
      await refresh();
    }
  }
}
