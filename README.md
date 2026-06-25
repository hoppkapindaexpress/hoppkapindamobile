# Hopp Kapında — Faz 4: Laravel REST API + PostgreSQL

Premium teslimat uygulaması. Bu paket **iki bölümden** oluşur:

1. **`hopp_kapinda/`** → Flutter uygulaması (Faz 1-3 + Faz 4 API katmanı)
2. **`faz4/`** → Laravel 11 backend (migration · model · controller · resource · route · seeder)

Flutter tarafı şu an **mock veriyle çalışır** (kurulum gerektirmez). Tek bir
satırı değiştirip Laravel API'ye geçersin — aşağıda anlatılıyor.

---

## 🎨 Marka Kimliği

| Token | Değer |
|-------|-------|
| Primary Purple | `#5A00D6` |
| Secondary Orange | `#FF7A00` |
| Background | `#F8F8FA` |

Font: Plus Jakarta Sans · Tasarım: soft shadow, rounded corner, gradient, glassmorphism.

---

## 📁 Proje Yapısı

```
hopp_kapinda/lib/
├── theme/            # Renk, tipografi, boyut token'ları + Material 3 tema
├── widgets/          # Reusable bileşenler (buton, kart, nav, feedback...)
├── models/           # Store, Product, Campaign, CartItem (+ fromJson)
├── repositories/
│   ├── store_repository.dart       # Arayüz + MockStoreRepository
│   └── api_store_repository.dart   # Laravel'e bağlanan gerçek repo + DioFactory
├── services/
│   ├── providers.dart    # ⭐ MOCK/API geçiş anahtarı burada
│   └── mock_data.dart    # Sahte veri (seeder ile birebir)
├── features/         # Ekranlar: splash, onboarding, auth, home, cart, orders, profile
├── routes/           # go_router
└── main.dart

faz4/  (Laravel backend)
├── database/migrations/   # 6 migration (users → orders)
├── database/seeders/      # MockData ile birebir tohum veri
├── app/Models/            # 12 Eloquent model + ilişkiler
├── app/Http/Controllers/Api/V1/   # 8 controller
├── app/Http/Resources/    # 5 JSON resource (Flutter fromJson ile uyumlu)
├── routes/api.php         # Tüm v1 uçları
├── config/cors.php
└── .env.example
```

---

## 🚀 Bölüm 1 — Flutter Çalıştırma

```bash
cd hopp_kapinda
flutter pub get
flutter run
```

Açılış: Splash → Onboarding → Auth → Home. Sepet, kupon (`HOPP40`),
favoriler, dark mode — hepsi çalışır. Şu an **mock veri** kullanılır.

---

## 🗄️ Bölüm 2 — Laravel Backend Kurulumu

### Gereksinimler
PHP 8.2+ · Composer · PostgreSQL 14+ · (opsiyonel) Redis

```bash
# 1. Yeni Laravel 11 projesi
composer create-project laravel/laravel hopp-api
cd hopp-api

# 2. Sanctum
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# 3. Bu paketteki faz4/ dosyalarını kopyala
cp -r /yol/faz4/app/*                 app/
cp    /yol/faz4/database/migrations/* database/migrations/
cp    /yol/faz4/database/seeders/*    database/seeders/
cp    /yol/faz4/routes/api.php        routes/api.php
cp    /yol/faz4/config/cors.php       config/cors.php
cp    /yol/faz4/.env.example          .env

# 4. PostgreSQL sürücüsü (yoksa)
#    Ubuntu: sudo apt install php-pgsql

# 5. Anahtar + DB
php artisan key:generate
createdb hopp_kapinda          # ya da pgAdmin'den oluştur
# .env içindeki DB_USERNAME / DB_PASSWORD değerlerini düzenle

# 6. Migration + tohum veri
php artisan migrate --seed

# 7. API'yi başlat
php artisan serve
# → http://localhost:8000/api/v1/campaigns  (JSON dönmeli)
```

> **Not:** `routes/api.php`'nin yüklenmesi için Laravel 11'de
> `bootstrap/app.php` içinde `api: __DIR__.'/../routes/api.php'` satırının
> olduğundan emin ol (yeni kurulumda varsayılan gelir).

### Test kullanıcısı (seeder'dan)
```
e-posta: test@hopp.com.tr
şifre:   123456
```

---

## 🔌 Bölüm 3 — Flutter'ı Gerçek API'ye Bağlama

**Tek dosya, tek satır.** `hopp_kapinda/lib/services/providers.dart`:

```dart
// ÖNCE (mock):
const bool _useRealApi = false;

// SONRA (Laravel API):
const bool _useRealApi = true;
```

Ardından sunucu adresini ayarla — `lib/repositories/api_store_repository.dart`:

```dart
class DioFactory {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emülatör
  // iOS simülatör / web:   'http://localhost:8000/api/v1'
  // Gerçek cihaz:          'http://<bilgisayar-ip>:8000/api/v1'
}
```

> **Android emülatör** `localhost`'a `10.0.2.2` üzerinden ulaşır — bu yüzden
> `localhost` değil `10.0.2.2` yazılır.

Başka **hiçbir** Flutter dosyasına dokunmana gerek yok. Ekranlar yalnızca
`campaignsProvider`, `storesProvider` gibi provider'lara bağlı; repository'nin
mock mu API mi olduğunu bilmezler. **Clean Architecture** bunu garanti eder.

---

## 📡 API Uç Noktaları

Taban: `http://localhost:8000/api/v1`

### Kimlik Doğrulama
| Method | URL | Auth | Açıklama |
|--------|-----|:----:|----------|
| POST | `/auth/register` | — | Kayıt (token döner) |
| POST | `/auth/login` | — | Giriş (token döner) |
| POST | `/auth/logout` | ✓ | Çıkış |
| GET  | `/auth/me` | ✓ | Profil |
| POST | `/auth/otp/send` | — | 6 haneli OTP gönder |
| POST | `/auth/otp/verify` | — | OTP doğrula |

### Katalog (herkese açık)
| Method | URL | Açıklama |
|--------|-----|----------|
| GET | `/campaigns` | Kampanya slider |
| GET | `/stores?type=restaurant` | Mağaza listesi (type: restaurant·market·dessert) |
| GET | `/stores/{id}` | Mağaza detayı |
| GET | `/stores/{id}/products` | Mağaza ürünleri |
| GET | `/products/popular` | Popüler ürünler |
| GET | `/products/{id}` | Ürün detayı |
| POST | `/coupons/validate` | Kupon doğrula `{code, subtotal}` |

### Kullanıcı İşlemleri (Bearer token)
| Method | URL | Açıklama |
|--------|-----|----------|
| GET | `/orders` | Sipariş listesi |
| POST | `/orders` | Yeni sipariş `{store_id, items:[{product_id, quantity}], coupon_code?}` |
| GET | `/orders/{id}` | Sipariş detayı |
| GET | `/favorites` | Favori mağazalar |
| POST | `/favorites/{storeId}` | Favori toggle |

### Örnek: Giriş
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@hopp.com.tr","password":"123456"}'
# → { "data": { "user": {...}, "token": "1|abc..." } }
```

### Örnek: Sipariş oluştur
```bash
curl -X POST http://localhost:8000/api/v1/orders \
  -H "Authorization: Bearer 1|abc..." \
  -H "Content-Type: application/json" \
  -d '{"store_id":1,"coupon_code":"HOPP40","items":[{"product_id":1,"quantity":2}]}'
```

---

## 🗄️ Veritabanı Şeması

```
users              kimlik, telefon, Sanctum token'ları
otp_codes          6 haneli SMS doğrulama (5 dk geçerli)
stores             restoran / market / tatlıcı (type sütunu)
product_categories menü grupları (store'a bağlı)
products           ürünler (store + category'e bağlı)
campaigns          ana sayfa slider
coupons            indirim kodları (HOPP40, MARKET20, TATLI25)
addresses          kullanıcı adresleri
orders             siparişler (status: pending→...→delivered)
order_items        sipariş kalemleri (anlık fiyat snapshot'ı)
payments           ödeme kayıtları
favorites          kullanıcı–mağaza pivot
notifications      bildirimler
```

**Güvenlik notu:** Sipariş oluştururken fiyatlar **istemciden değil,
veritabanından** okunup sunucuda yeniden hesaplanır. İstemci yalnızca
ürün id + adet gönderir. Bu sayede fiyat manipülasyonu engellenir.

---

## ✅ Kalite Notları

- Tüm PHP dosyaları `php -l` ile söz dizimi doğrulamasından geçti (34 dosya).
- Tüm Flutter göreli import'ları otomatik doğrulandı (0 kırık).
- Laravel Resource'ları, Flutter modellerinin `fromJson` alan adlarıyla
  (snake_case) birebir eşleşir.
- Mock veri (`mock_data.dart`) ile seeder (`DatabaseSeeder.php`) aynı içeriği
  üretir; API'ye geçişte aynı ekranı görürsün.

> Flutter SDK bu ortamda olmadığı için `flutter analyze` çalıştırılamadı;
> Dart tarafı el ile + import taramasıyla doğrulandı. Kendi makinende
> `flutter pub get` sonrası uyarı çıkarsa bildir.

---

## 🗺️ Yol Haritası

- **Faz 1** — Temel + tasarım sistemi ✅
- **Faz 2** — Akış ekranları ✅
- **Faz 3** — Riverpod state + repository ✅
- **Faz 4** — Laravel REST API + PostgreSQL ✅ *(bu paket)*
- **Faz 5** — React admin panel (sırada)

### Henüz placeholder olan ekranlar
Restaurant Detail · Product Detail · Order Tracking — altyapı (provider,
API, model) hazır; yalnızca UI bekliyor. Faz 5'te ya da ek bir turda yapılabilir.
