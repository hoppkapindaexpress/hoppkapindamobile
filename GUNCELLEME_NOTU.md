# Hopp Kapında — Güncelleme: Sipariş Takibi Gerçek Duruma Bağlandı

## ✅ Bu turda yapılanlar

### Order Tracking → gerçek API durumuna bağlandı
- Takip ekranı artık `/api/v1/orders/{id}`'den **gerçek status**'ü çekiyor
- Timeline (sipariş alındı → onaylandı → hazırlanıyor → yolda → teslim) gerçek
  duruma göre doluyor; sahte sabit adım kaldırıldı
- Kurye kartı API'den gelen `courier_name`'i gösteriyor (yoksa "Henüz atanmadı")
- Sağ üstte **yenile** butonu — durumu tekrar çeker (admin ilerletmişse görünür)
- İptal edilen sipariş için özel ekran
- Yeni: `order_provider.dart`, `OrderDetail` modeli (order_service içinde)

### Siparişlerim ekranı → gerçek API'ye bağlandı
- Artık hardcoded değil; `/api/v1/orders`'tan gerçek siparişleri çekiyor
- Aktif / Geçmiş sekmeleri gerçek `status`'e göre ayrılıyor
- Giriş yapılmamışsa "Giriş yap" yönlendirmesi
- Aşağı çekince yenileme (pull-to-refresh)
- Gerçek sipariş id'siyle takip ekranına gidiyor

### Sepet
- Sipariş verince `ordersProvider` yenileniyor → yeni sipariş listede anında görünür

## 🧪 Durum değişimini test et

Şu an DB'deki siparişin `status = pending`. Takip ekranında "Sipariş alındı"
adımında görünür. Durumu değiştirip ekranın güncellendiğini görmek için:

Cloud SQL Studio'da şunu çalıştır:
```sql
UPDATE orders SET status = 'preparing' WHERE id = 1;
```

Sonra uygulamada takip ekranını aç (ya da yenile butonuna bas) → timeline
"Hazırlanıyor" adımına ilerlemiş olmalı. Diğer durumlar:
`confirmed`, `preparing`, `on_the_way`, `delivered`, `cancelled`

Kurye de eklemek istersen:
```sql
UPDATE orders SET status = 'on_the_way', courier_name = 'Mehmet K.',
  courier_phone = '5551234567' WHERE id = 1;
```

## ⚠️ Notlar
- Harita hâlâ stilize placeholder (gerçek harita = google_maps_flutter + API key)
- Durumu elle SQL'le değiştiriyoruz çünkü admin panel (Faz 5) henüz yok.
  Admin panel gelince bu tek tıkla yapılacak.

## 🔍 Doğrulama
- Tüm göreli import'lar: 0 kırık
- _currentStep (sahte) tamamen kaldırıldı, gerçek stepIndex'e bağlandı
