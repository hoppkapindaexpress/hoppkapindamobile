path = r'C:\hopp_kapinda\android\app\build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_count = content.count('com.example.hopp_kapinda')
content = content.replace('com.example.hopp_kapinda', 'com.hoppkapinda.app')

print(f'{old_count} yerde degistirildi')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
