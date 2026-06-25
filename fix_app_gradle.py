path = r'C:\hopp_kapinda\android\app\build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}"""

new = """plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}"""

if old in content:
    content = content.replace(old, new)
    print('ADIM1 TAMAM')
else:
    print('ADIM1 BULUNAMADI')

old2 = """flutter {
    source = "../.."
}"""

new2 = """flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-messaging")
}"""

if old2 in content:
    content = content.replace(old2, new2)
    print('ADIM2 TAMAM')
else:
    print('ADIM2 BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
