path = r'C:\hopp_kapinda\lib\services\notification_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """      await _localNotifications
          .resolvePlatformSpecificImplementation
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);"""

new = """      await _localNotifications
          .resolvePlatformSpecificImplementation
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);"""

if old in content:
    content = content.replace(old, new)
    print('TAMAM')
else:
    print('BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
