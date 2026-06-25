# Canlı Güncelleme — Veri Artık Kendini Tazeliyor

## Sorun
Uygulama veriyi açılışta bir kez çekip cache'liyordu; admin panelden yapılan
fiyat/durum değişikliklerini görmek için uygulamayı kapatıp açmak gerekiyordu.

## Çözüm (WebSocket'siz, ücretsiz, "ekrana girince güncel" yaklaşımı)

### 1. Katalog verileri kısa ömürlü cache
`providers.dart` — kampanya/ürün/mağaza provider'ları artık veriyi 15-30 sn
tutup bırakıyor. Kullanıcı ekrandan çıkıp dönünce ya da süre dolunca veri
otomatik yeniden çekiliyor. Yani fiyat değişikliği, uygulamayı kapatmadan,
ekrana tekrar girince görünüyor.

### 2. Ana sayfada aşağı-çekince-yenile (pull-to-refresh)
`home_screen.dart` — kullanıcı ana sayfayı aşağı çekince kampanyalar,
popüler ürünler ve mağazalar anında tazeleniyor.

### 3. Sipariş takibinde otomatik yenileme
`order_tracking_screen.dart` — takip ekranı açıkken her 10 saniyede bir
sipariş durumunu otomatik çekiyor. Admin panelden "Hazırlanıyor → Yolda →
Teslim" dediğinde, kullanıcı hiçbir şey yapmadan, 10 sn içinde ekranında görür.
(Ayrıca sağ üstte manuel yenile butonu da var.)

### 4. Siparişlerim listesinde pull-to-refresh (zaten vardı)

## Değişen dosyalar
```
lib/services/providers.dart                      (kısa cache ömrü)
lib/features/home/home_screen.dart               (pull-to-refresh)
lib/features/orders/order_tracking_screen.dart   (10 sn otomatik yenileme)
```

## Bu "gerçek zamanlı (WebSocket)" değil — ve neden yeterli
Kullanıcı ekrana baktığında en fazla 10-30 sn içinde güncel veriyi görür;
ekrana tekrar girince anında. Bu, Yemeksepeti/Getir gibi uygulamaların ürün
fiyatları için yaptığıyla aynı yaklaşım. Saniyesinde canlı değişim (kullanıcı
hiç dokunmadan) için WebSocket (Firebase/Pusher) gerekir — onu istersen ayrı
bir turda ekleriz, ama çoğu senaryo için bu çözüm yeterli ve maliyetsiz.

## Test
1. flutter pub get && flutter run
2. Admin panelden bir ürünün fiyatını değiştir
3. Uygulamada o mağazadan çık, tekrar gir → yeni fiyat görünür
   (ya da ana sayfayı aşağı çek → tazelenir)
4. Sipariş takip ekranını aç, admin panelden durumu değiştir → 10 sn içinde
   takip ekranı kendiliğinden ilerler
