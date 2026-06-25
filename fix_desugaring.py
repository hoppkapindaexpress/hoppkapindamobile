path = r'C:\hopp_kapinda\android\app\build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }"""

new = """    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }"""

if old in content:
    content = content.replace(old, new)
    print('ADIM1 TAMAM')
else:
    print('ADIM1 BULUNAMADI')

old2 = """dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-messaging")
}"""

new2 = """dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}"""

if old2 in content:
    content = content.replace(old2, new2)
    print('ADIM2 TAMAM')
else:
    print('ADIM2 BULUNAMADI')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
