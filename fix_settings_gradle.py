path = r'C:\hopp_kapinda\android\settings.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}"""

new = """plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
}"""

if old in content:
    content = content.replace(old, new)
    print('TAMAM')
else:
    print('BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
