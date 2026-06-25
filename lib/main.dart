import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme_provider.dart';
import 'features/courier/courier_background_service.dart';
import 'features/profile/favorites_provider.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // ÖNEMLİ: Firebase init'i try/catch'siz bırakmak release modda
  // (Android/iOS) uygulamayı tamamen siyah ekranda donduruyordu —
  // hata fırlarsa main() hiç tamamlanmıyor, runApp() çağrılamıyor ve
  // release modda Flutter hata ekranı da göstermiyor. Diğer çalışan
  // uygulamalardaki (HataySepetim vb.) güvenli desenle aynı hale getirildi.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase hatası: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const HoppKapindaApp(),
    ),
  );

  // Bildirim servisi ve kurye arka plan servisi runApp()'tan SONRA
  // başlatılıyor — UI zaten ekranda, burada bir hata olsa bile
  // uygulama donmaz, sadece o özellik çalışmaz.
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Bildirim servisi hatası: $e');
  }

  try {
    // Kurye arka plan konum servisini yapılandır (henüz BAŞLATMAZ —
    // sadece kayıt eder; gerçek başlatma "Yola Çık" anında olur).
    await initializeBackgroundService();
  } catch (e) {
    debugPrint('Kurye arka plan servisi hatası: $e');
  }
}

class HoppKapindaApp extends ConsumerWidget {
  const HoppKapindaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hopp Kapında',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      // Web'de uygulamayı ortada telefon genişliğinde tut.
      // Mobilde ekran zaten dar olduğu için hiçbir etkisi olmaz.
      builder: (context, child) {
        if (!kIsWeb) return child ?? const SizedBox.shrink();
        return ColoredBox(
          color: const Color(0xFFE5E5E5),
          child: Center(
            child: ClipRect(
              child: SizedBox(
                width: 430,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
