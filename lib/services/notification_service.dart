import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/api_store_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Uygulama arka plandayken/kapalÄ±yken gelen FCM mesajlarÄ±nÄ± iÅŸler.
/// TOP-LEVEL (sÄ±nÄ±f dÄ±ÅŸÄ±) fonksiyon olmak zorunda â€” Flutter bunu izole bir
/// background isolate'te Ã§alÄ±ÅŸtÄ±rÄ±r.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Arka plan] Bildirim alindi: ${message.notification?.title}');
}

/// Push notification (FCM) yÃ¶netimi: izin isteme, token alma,
/// foreground/background/terminated durumlarÄ±nda bildirim gÃ¶sterme.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// main()'de bir kez Ã§aÄŸrÄ±lÄ±r.
  Future<void> init() async {
    // 1) Izin iste (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Yerel bildirim (uygulama Ã¶n plandayken banner gÃ¶stermek iÃ§in) kurulumu
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'hopp_kapinda_default',
        'Hopp Kapinda Bildirimleri',
        description: 'Siparis ve kampanya bildirimleri',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 3) FCM token al
    _fcmToken = await _fcm.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Token yenilenirse, kullanici zaten giris yapmissa backend'e hemen gÃ¶nder.
    _fcm.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('FCM Token yenilendi: $newToken');

      final prefs = await SharedPreferences.getInstance();
      // Bu key AuthService.tokenKey ('auth_token') ile ayni olmak zorunda.
      final authToken = prefs.getString('auth_token');
      if (authToken != null) {
        await sendTokenToBackend(authToken);
      }
    });

    // 4) Uygulama Ã¶n plandayken gelen mesajlarÄ± yerel bildirim olarak gÃ¶ster
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[On plan] Bildirim alindi: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'hopp_kapinda_default',
              'Hopp Kapinda Bildirimleri',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5) Kullanici bildirime tiklayip uygulamayi actiginda (arka plandan)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Bildirime tiklandi (arka plandan acildi): ${message.data}');
      // TODO: message.data['action_route'] varsa o sayfaya yÃ¶nlendir.
    });
  }

  /// Login sonrasi FCM token'i backend'e gÃ¶nderir.
  Future<void> sendTokenToBackend(String authToken) async {
    if (_fcmToken == null) return;
    try {
      final dio = dio_pkg.Dio(dio_pkg.BaseOptions(
        baseUrl: DioFactory.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ));
      await dio.post('/fcm-token', data: {'fcm_token': _fcmToken});
      debugPrint('FCM token backend\'e gÃ¶nderildi.');
    } catch (e, st) {
      debugPrint('FCM token gÃ¶nderilemedi: $e');
      debugPrint('Stack: $st');
    }
  }

  /// Uygulamanin tamamen kapaliyken bir bildirime tiklanarak acilip
  /// acilmadigini kontrol eder (login sonrasi vb. Ã§aÄŸrÄ±labilir).
  Future<RemoteMessage?> getInitialMessage() {
    return _fcm.getInitialMessage();
  }
}
