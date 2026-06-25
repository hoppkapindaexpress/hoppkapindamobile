path = r'C:\hopp_kapinda\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme_provider.dart';
import 'features/profile/favorites_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  // SharedPreferences'\u0131 bir kez ba\u015flat; provider'lar senkron eri\u015fsin.
  final prefs = await SharedPreferences.getInstance();
  runApp("""

new = """import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme_provider.dart';
import 'features/profile/favorites_provider.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Firebase baslat + push notification servisini kur.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  // SharedPreferences'i bir kez baslat; provider'lar senkron erissin.
  final prefs = await SharedPreferences.getInstance();
  runApp("""

if old in content:
    content = content.replace(old, new)
    print('TAMAM')
else:
    print('BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
