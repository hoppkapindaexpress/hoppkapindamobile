path = r'C:\hopp_kapinda\pubspec.yaml'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = "  dio: ^5.4.3+1"
new = """  dio: ^5.4.3+1
  firebase_core: ^3.8.0
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1"""

if old in content:
    content = content.replace(old, new)
    print('TAMAM')
else:
    print('BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
