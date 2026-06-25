path = r'C:\hopp_kapinda\lib\main.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Import satirlarinin hemen oncesine yeni importlari ekle
for i, line in enumerate(lines):
    if line.startswith("import 'package:flutter/material.dart';"):
        lines.insert(i, "import 'package:firebase_core/firebase_core.dart';\n")
        lines.insert(i+1, "import 'package:firebase_messaging/firebase_messaging.dart';\n")
        print(f'Importlar eklendi - satir {i+1}')
        break

# 'routes/app_router.dart' importunun altina notification_service importu ekle
for i, line in enumerate(lines):
    if "routes/app_router.dart" in line:
        lines.insert(i+1, "import 'services/notification_service.dart';\n")
        print(f'notification_service importu eklendi - satir {i+2}')
        break

# main() fonksiyonu icine Firebase init ekle - "final prefs" satirinin oncesine
for i, line in enumerate(lines):
    if 'final prefs = await SharedPreferences.getInstance();' in line:
        lines.insert(i, '  await Firebase.initializeApp();\n')
        lines.insert(i+1, '  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);\n')
        lines.insert(i+2, '  await NotificationService.instance.init();\n')
        lines.insert(i+3, '\n')
        print(f'Firebase init eklendi - satir {i+1}')
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('TAMAM')
