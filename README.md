# Fiyat Takip

Kişisel kullanım için farklı e-ticaret sitelerinden ürün fiyatlarını takip eden Flutter uygulaması. Tüm veri cihazda saklanır, arka planda otomatik fiyat kontrolü yapılır.

## Özellikler

- **Çoklu Site Desteği**: Trendyol, Hepsiburada, N11 ve diğer siteler
- **Otomatik Fiyat Takibi**: Arka planda periyodik fiyat kontrolü
- **Fiyat Düşüş Bildirimleri**: Fiyat düştüğünde anlık bildirim
- **Fiyat Geçmişi Grafikleri**: Ürün fiyatlarının zaman içindeki değişimi
- **Paylaşımdan Ekleme**: Tarayıcıdan direkt link paylaşımı ile ürün ekleme
- **Veri Yedekleme**: JSON formatında export/import desteği
- **Hedef Fiyat Belirleme**: İstediğiniz fiyata ulaşıldığında bildirim
- **Ürün Gruplama**: Aynı ürünün farklı sitelerdeki fiyatlarını karşılaştırma

## Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| State Management | Riverpod |
| Veritabanı | Drift (SQLite) |
| Scraping | http, html, webview_flutter, puppeteer |
| Arka Plan Görevleri | workmanager |
| Bildirimler | flutter_local_notifications |
| Grafikler | fl_chart |
| Paylaşım | receive_sharing_intent, share_plus |
| Routing | go_router |

## Kurulum

### Gereksinimler

- Flutter SDK >= 3.11.1
- Dart SDK >= 3.11.1

### Adımlar

1. Depoyu klonlayın:
```bash
git clone <repository-url>
cd fiyat_takip
```

2. Bağımları yükleyin:
```bash
flutter pub get
```

3. Code generation için build_runner çalıştırın:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Uygulamayı çalıştırın:
```bash
flutter run
```

## Kullanım

### Ürün Ekleme

**Manuel Ekleme:**
1. Ekleme ekranına gidin
2. Ürün linkini yapıştırın
3. Uygulama otomatik ürün bilgilerini çeker

**Paylaşımdan Ekleme:**
1. Tarayıcıda veya uygulamada "Paylaş" seçeneğini kullanın
2. Fiyat Takip uygulamasını seçin
3. Link otomatik olarak ürün ekleme ekranına yönlendirilir

### Fiyat Takibi

Uygulama arka planda otomatik olarak fiyatları kontrol eder. Kontrol sıklığını ayarlardan değiştirebilirsiniz:
- 1 saat
- 3 saat
- 6 saat
- 12 saat
- 24 saat

### Bildirimler

Fiyat düşüşü tespit edildiğinde bildirim alırsınız. Bildirim formatı:
```
Ürün adı: 450₺ → 380₺ (%15 düşüş)
```

Hedef fiyat belirlediyseniz ve bu fiyata ulaşıldığında öncelikli bildirim alırsınız.

### Veri Yedekleme

**Backup:**
1. Ayarlar ekranına gidin
2. "Backup Data" seçeneğini seçin
3. Veriler JSON formatında paylaşılır

**Restore:**
1. Ayarlar ekranına gidin
2. "Restore Data" seçeneğini seçin
3. Backup dosyasını seçin

## Proje Yapısı

```
lib/
├── core/
│   ├── database/          # Drift veritabanı ve tablolar
│   ├── background/        # Workmanager entegrasyonu
│   ├── notifications/      # Local notification servisi
│   └── providers/         # Riverpod dependency injection
├── features/
│   ├── products/
│   │   ├── domain/        # Entity ve repository arayüzleri
│   │   ├── data/          # Scrapers ve repository implementasyonları
│   │   └── presentation/ # UI katmanı
│   ├── groups/           # Ürün grupları
│   └── settings/         # Ayarlar ekranı
└── shared/               # Ortak widget'lar
```

## Site Scraping

Uygulama **genel amaçlı** bir scraping sistemidir - sadece belirli siteler için değil, herhangi bir e-ticaret sitesinden link ekleyebilirsiniz.

### Genel Scraping Akışı

**Herhangi bir URL eklendiğinde sistem otomatik olarak:**

1. **Site-Specific Scraper Kontrolü**
   - Trendyol → TrendyolScraper (optimize edilmiş)
   - Hepsiburada → HepsiburadaScraper (optimize edilmiş)
   - N11 → N11Scraper (optimize edilmiş)
   - Diğer tanımlı siteler için özel scraper'lar

2. **Puppeteer Fallback** (Tüm siteler için)
   - Site-specific scraper yoksa veya başarısız olursa
   - Amazon, AliExpress, eBay, diğer tüm e-ticaret siteleri
   - JavaScript execution, Cloudflare bypass, popup handling
   - **Bu sayede yeni site eklemeden de çalışır**

3. **Generic HTML Scraper** (Son çare)
   - Puppeteer de başarısız olursa
   - Basit HTML parsing teknikleri

### Desteklenen Siteler

**Doğrudan Optimize Edilmiş:**
- ✅ Trendyol
- ✅ Hepsiburada  
- ✅ N11

**Puppeteer ile Otomatik Desteklenen:**
- ✅ Amazon
- ✅ AliExpress
- ✅ eBay
- ✅ Diğer tüm e-ticaret siteleri

### Kullanım Örnekleri

```dart
// Amazon linki ekleyebilirsin
final amazonUrl = 'https://www.amazon.com/product-url';
// → Site-specific scraper yok → Puppeteer devreye girer → Başarılı! ✅

// AliExpress linki ekleyebilirsin
final aliexpressUrl = 'https://www.aliexpress.com/item/url';
// → Site-specific scraper yok → Puppeteer devreye girer → Başarılı! ✅

// Trendyol linki ekleyebilirsin
final trendyolUrl = 'https://www.trendyol.com/product-url';
// → TrendyolScraper çalışır → Başarılı! ✅
```

### Scraping Hiyerarşisi

1. **Site-Specific Scrapers**: Her site için optimize edilmiş scraper'lar
   - Trendyol, Hepsiburada, N11 için özel implementasyonlar
   - Daha hızlı ve verimli çalışır

2. **Puppeteer (Headless Chrome)**: Genel amaçlı güçlü scraper
   - JavaScript execution desteği
   - Cloudflare ve diğer anti-bot korumalarını bypass edebilir
   - JSON-LD, meta tags ve DOM selector'ları ile data extraction
   - Cookie consent popup'larını otomatik kapatma
   - Gerçekçi browser simulation (user agent, viewport, headers)

3. **WebView Scraping**: Flutter WebView ile JavaScript execution
   - Uygulama içinde web tabanlı scraping
   - Puppeteer'a alternatif

4. **Generic HTML Scraper**: Fallback yöntem
   - Bilinmeyen siteler için genel scraping
   - Standart HTML parsing teknikleri

### Puppeteer Özellikleri

Puppeteer scraper modern e-ticaret sitelerinde başarılı şekilde çalışmaktadır:

- **Cloudflare Bypass**: Headless Chrome ile JavaScript challenge'ları çözebilir
- **Anti-Detection**: Automation indicators'ları gizler, gerçekçi browser davranışı
- **Popup Handling**: Cookie consent ve modal popup'ları otomatik kapatır
- **Multi-Strategy Data Extraction**:
  - JSON-LD (en güvenilir)
  - Meta tags
  - DOM selector'lar
  - Initial state data

### Test Edilen Siteler

Aşağıdaki sitelerde Puppeteer scraper başarıyla test edilmiştir:

- ✅ **Trendyol**: JSON-LD data extraction, price/name alımı başarılı
- ✅ **Hepsiburada**: JSON-LD data extraction, product name alımı başarılı
- ✅ **N11**: JSON-LD data extraction, product name alımı başarılı

### Yeni Site Ekleme

**Zorunlu değil ama optimize etmek isterseniz:**

Yeni bir site için özel scraper eklemek:

1. `lib/features/products/data/scrapers/impl/` altında yeni scraper sınıfı oluşturun
2. `ProductScraper` interface'ini implement edin
3. `lib/core/providers/providers.dart` içine provider ekleyin
4. `scraperRegistryProvider` içine scraper'ı kaydedin

**Alternatif olarak:**
Puppeteer scraper otomatik olarak bilinmeyen siteleri de handle eder, bu yüzden yeni site eklemek zorunlu değildir.

## Geliştirme

### Scraping Testleri

Proje farklı scraping yöntemlerini test etmek için script'ler içerir:

```bash
# Basit HTTP scraping testi
dart run test_scrapers.dart

# Puppeteer (headless Chrome) scraping testi
dart run test_scrapers_puppeteer.dart

# Flutter WebView scraping testi (uygulama içinde çalışır)
# test_scrapers_webview.dart dosyasına bakın
```

Bu test script'leri scraping stratejilerini geliştirmek ve debug etmek için kullanılabilir.

### Test Çalıştırma

```bash
flutter test
```

### Kod Analizi

```bash
flutter analyze
```

### Formatlama

```bash
dart format .
```

## Platform Spesifikasyonları

### Android
- Minimum SDK: 21
- Arka plan görevleri: 15 dakika minimum aralık
- Pil optimizasyonu: Battery not low constraint

### iOS
- Background task: BGAppRefreshTask (best-effort)
- Ek olarak foreground'a döndüğünde refresh
- Pil optimizasyonu otomatik

## Sınırlamalar

- Backend bulut senkronizasyonu yok
- Cihazlar arası otomatik senkronizasyon yok
- Kullanıcı hesabı/giriş sistemi yok
- iOS'de arka plan çalışma garantisi yok

## Gelecek Özellikler

- [ ] WebView scraper'lar için detaylı test
- [ ] Farklı ülke siteleri için desteği genişletme
- [ ] Fiyat trend analizi
- [ ] Birden fazla cihaz senkronizasyonu
- [ ] Widget desteği

## Lisans

Bu proje kişisel kullanım için geliştirilmiştir.

## İletişim

Sorular ve öneriler için GitHub issues kullanabilirsiniz.
