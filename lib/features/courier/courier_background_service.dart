import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kurye arka plan konum takibi.
///
/// Uygulama arka plana alındığında ya da ekran kapansa bile çalışmaya
/// devam etmesi için Android **Foreground Service** kullanılır (kalıcı
/// bir bildirim gösterir — bu sayede sistem servisi öldürmez ve kullanıcı
/// takibin aktif olduğunu görür).
///
/// ÖNEMLİ — bu dosyadaki [onBackgroundServiceStart] fonksiyonu AYRI bir
/// Dart isolate'ında çalışır: ana uygulamanın Riverpod state'ine,
/// BuildContext'ine ya da bellekteki hiçbir değişkenine erişemez.
/// Tüm veri (auth token, aktif sipariş id) SharedPreferences üzerinden
/// okunur/yazılır — bu, isolate'lar arasında paylaşılan tek güvenilir kanal.
const _intervalSeconds = 3;
const _baseUrl = 'https://api.hoppkapinda.com/api/v1';
const _orderIdPrefsKey = 'active_delivery_order_id';
const _notificationChannelId = 'hopp_courier_location';

/// main()'de bir kez çağrılır. Servisi YAPILANDIRIR ama BAŞLATMAZ.
/// Gerçek başlatma [startCourierLocationService] ile, kurye "Yola Çık"
/// dediğinde yapılır.
Future<void> initializeBackgroundService() async {
  // ÖNEMLİ — Bildirim kanalı service.configure()'dan ÖNCE elle
  // oluşturulmalı. Sadece notificationChannelId string'ini vermek bazı
  // cihazlarda (özellikle Xiaomi/MIUI) yetersiz kalıyor; kanal henüz
  // sistemde kayıtlı değilken startForeground() çağrılırsa
  // "CannotPostForegroundServiceNotificationException: Bad notification"
  // hatasıyla servis çöküyor. (notification_service.dart'taki FCM kanalı
  // kurulumuyla aynı pattern, farklı kanal id'siyle.)
  const channel = AndroidNotificationChannel(
    _notificationChannelId,
    'Kurye Konum Takibi',
    description: 'Teslimat sırasında canlı konum paylaşımı için kullanılır.',
    importance: Importance.low,
  );
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'Hopp Kapında',
      initialNotificationContent: 'Teslimat takibi hazır',
      foregroundServiceNotificationId: 911,
      // NOT: foregroundServiceTypes parametresi flutter_background_service
      // 5.x'te eklendi. `flutter pub get` sonrası derleme hatası verirse
      // (paket sürümü daha eskiyse) bu satırı kaldır — AndroidManifest.xml'deki
      // android:foregroundServiceType="location" tek başına da yeterlidir.
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onBackgroundServiceStart,
      onBackground: _onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Servisi başlatır (yoksa) ve aktif sipariş id'sini bildirir.
/// `courier_provider.dart` → `LocationStreamNotifier.startTracking()`
/// tarafından çağrılır.
Future<void> startCourierLocationService(String orderId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_orderIdPrefsKey, orderId);

  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  }
  service.invoke('setOrderId', {'orderId': orderId});
}

/// Servisi durdurur — teslimat tamamlandığında/iptal edildiğinde çağrılır.
/// `courier_provider.dart` → `LocationStreamNotifier.stopTracking()`
/// tarafından çağrılır.
Future<void> stopCourierLocationService() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_orderIdPrefsKey);

  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke('stopService');
  }
}

/// Arka plan isolate'ında çalışan giriş noktası.
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String? orderId;

  service.on('setOrderId').listen((event) {
    orderId = event?['orderId'] as String?;
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Servis yeniden başlatılmışsa (örn. sistem tarafından) son bilinen
  // sipariş id'sini SharedPreferences'tan oku.
  final prefs = await SharedPreferences.getInstance();
  orderId ??= prefs.getString(_orderIdPrefsKey);

  Timer.periodic(const Duration(seconds: _intervalSeconds), (timer) async {
    if (orderId == null) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      final freshPrefs = await SharedPreferences.getInstance();
      final token = freshPrefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ));

      await dio.post('/courier/location', data: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'speed': pos.speed * 3.6, // m/s → km/h
        'order_id': orderId,
      });

      // Kalıcı bildirimin içeriğini güncelle — kurye arka planda olsa da
      // takibin aktif ve çalıştığını görsün.
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'Hopp Kapında — Teslimat sürüyor',
          content: 'Sipariş #$orderId · Konum gönderiliyor',
        );
      }
    } catch (_) {
      // Tek bir başarısız gönderim servisi durdurmaz — sıradaki periyotta
      // tekrar denenir. Kalıcı bir hata olursa (örn. token geçersiz),
      // bu döngü 401 alıp sessizce yutar; kullanıcıya bunu yansıtmak için
      // ileride bir 'lastError' SharedPreferences anahtarı eklenebilir.
    }
  });
}
