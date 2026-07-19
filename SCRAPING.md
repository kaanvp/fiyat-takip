# Web Scraping Dokümantasyonu

Bu dokümantasyon fiyat takip uygulamasındaki web scraping stratejilerini ve teknik detaylarını açıklar.

## Scraping Stratejileri

Uygulama çok katmanlı bir yaklaşım kullanır:

### 1. Site-Specific Scrapers

Her e-ticaret sitesi için optimize edilmiş scraper'lar:

- **TrendyolScraper**: Trendyol'a özel selector'lar ve data extraction
- **HepsiburadaScraper**: Hepsiburada'ya özel implementasyon
- **N11Scraper**: N11'e özel implementasyon

Bu scraper'lar hızlı ve verimlidir çünkü site yapısına özel optimize edilmiştir.

### 2. Puppeteer (Headless Chrome)

Modern web korumalarını aşan en güçlü scraping yöntemi:

#### Özellikler

- **JavaScript Execution**: Dinamik içerikleri render edebilir
- **Cloudflare Bypass**: JavaScript challenge'ları çözebilir
- **Anti-Detection**: 
  - `navigator.webdriver` property'sini gizler
  - Gerçekçi plugins ve languages simülasyonu
  - Gerçekçi user agent ve viewport ayarları
- **Popup Handling**: Cookie consent popup'larını otomatik kapatır
- **Multi-Strategy Data Extraction**:
  1. JSON-LD (Structured Data) - En güvenilir
  2. Meta tags (Open Graph, Twitter Cards)
  3. DOM selector'lar (CSS selectors)
  4. Initial state data (React/Vue state)

#### Kullanım

Puppeteer scraper otomatik olarak fallback olarak kullanılır:

```dart
// Site-specific scraper önce denenir
// Başarısız olursa Puppeteer devreye girer
final scraper = scraperRegistry.getScraperForUrl(url);
final product = await scraper.scrape(url);
```

#### Avantajları

- Modern SPA (Single Page Application) sitelerde çalışır
- Anti-bot korumalarını aşabilir
- JSON-LD gibi structured data'ları güvenilir çeker
- Cookie ve session management otomatik

#### Dezavantajları

- HTTP scraping'e göre daha yavaştır
- Daha fazla kaynak kullanır (CPU, memory)
- Chrome binary gerektirir

### 3. WebView Scraping

Flutter WebView component'i ile JavaScript execution:

- Uygulama içinde web tabanlı scraping
- Puppeteer'a alternatif
- Platform-specific rendering

### 4. Generic HTML Scraper

Fallback yöntem olarak:

- Bilinmeyen siteler için genel scraping
- Standart HTML parsing teknikleri
- Site-specific olmadığında kullanılır

## Scraping Akışı

```
URL Input → SiteScraperRegistry → Scraper Selection → Data Extraction → Product Entity
                    ↓                                    ↓
              Priority System                    Multiple Strategies
                    ↓                                    ↓
        1. Site-Specific                    1. JSON-LD
        2. Puppeteer                       2. Meta Tags  
        3. WebView                        3. DOM Selectors
        4. Generic HTML                   4. Initial State
```

## Data Extraction Teknikleri

### JSON-LD (Structured Data)

En güvenilir yöntem:

```html
<script type="application/ld+json">
{
  "@type": "Product",
  "name": "Ürün Adı",
  "offers": {
    "price": "1234.56",
    "priceCurrency": "TRY"
  }
}
</script>
```

### Meta Tags

Open Graph ve Twitter Cards:

```html
<meta property="og:title" content="Ürün Adı">
<meta property="og:image" content="https://...">
<meta property="product:price:amount" content="1234.56">
```

### DOM Selectors

CSS selector'lar ile element seçimi:

```dart
final priceElement = document.querySelector('.prc-dsc');
final nameElement = document.querySelector('h1');
```

### Initial State Data

React/Vue/Angular state extraction:

```javascript
window.__PRODUCT_DETAIL_APP_INITIAL_STATE__ = {
  product: {
    name: "Ürün Adı",
    price: { discountedPrice: { value: 1234.56 } }
  }
}
```

## Anti-Bot Önlemleri

Modern sitelerdeki korumaları aşmak için:

### 1. User Agent Rotation

Farklı browser'ları simüle eden user agent'lar:

```dart
final userAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36...',
  // ...
];
```

### 2. Header Management

Gerçekçi HTTP headers:

```dart
{
  'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
  'Referer': 'https://www.site.com/',
  'Sec-Ch-Ua': '"Chromium";v="126", "Google Chrome";v="126"',
}
```

### 3. Rate Limiting

Polite scraping için bekleme süreleri:

```dart
await Future.delayed(Duration(seconds: 2)); // Between requests
await Future.delayed(Duration(milliseconds: 1500)); // After homepage
```

### 4. Session Establishment

Önce homepage ziyareti:

```dart
// Step 1: Visit homepage
await page.goto('https://site.com');

// Step 2: Visit product page
await page.goto('https://site.com/product');
```

### 5. Popup Handling

Cookie consent popup'larını kapatma:

```javascript
// CSS ile gizleme
const style = document.createElement('style');
style.textContent = `[class*="modal"] { display: none !important; }`;

// Button tıklama
document.querySelectorAll('button[id*="accept"]').forEach(btn => btn.click());
```

## Performans Optimizasyonu

### Scraping Hiyerarşisi

Hızdan güvenliğe doğru öncelik:

1. **Site-Specific HTTP Scraping** (En hızlı)
2. **Puppeteer** (Daha yavaş ama güvenilir)
3. **WebView** (Platform-dependent)
4. **Generic HTML** (Fallback)

### Caching

Farklı caching stratejileri:

- İstek başına caching
- Session persistence
- Cookie management

### Error Handling

Robust error handling:

```dart
try {
  final product = await scraper.scrape(url);
} on ScraperException catch (e) {
  switch (e.errorType) {
    case ScraperErrorType.blocked:
      // Try Puppeteer
      break;
    case ScraperErrorType.jsRequired:
      // Use WebView
      break;
    default:
      // Log error
  }
}
```

## Test Etme

### Test Script'leri

Proje scraping testleri için script'ler içerir:

```bash
# HTTP scraping testi
dart run test_scrapers.dart

# Puppeteer testi
dart run test_scrapers_puppeteer.dart
```

### Test Sonuçları

Güncel test sonuçları (Temmuz 2026):

| Site | HTTP Scraping | Puppeteer | Başarı Oranı |
|------|---------------|-----------|--------------|
| Trendyol | ❌ Blocked | ✅ Başarılı | %100 |
| Hepsiburada | ❌ 404 | ✅ Başarılı | %95 |
| N11 | ❌ Cloudflare | ✅ Başarılı | %90 |

## Sınırlamalar

### Teknik Sınırlamalar

- **Puppeteer**: Chrome binary gerektirir, daha fazla kaynak kullanır
- **WebView**: Platform-specific behavior
- **HTTP Scraping**: JavaScript gerektiren sitelerde çalışmaz

### Legal Sınırlamalar

- robots.txt kurallarına saygı
- Rate limiting ile polite scraping
- Kişisel kullanım için optimize edilmiş

## Gelecek Geliştirmeler

- [ ] Machine learning ile selector otomasyonu
- [ ] Distributed scraping support
- [ ] API integration (reseller API'leri)
- [ ] Real-time price monitoring
- [ ] Screenshot-based price extraction (OCR)

## Sorun Giderme

### Common Issues

**1. Puppeteer Launch Error**
```
Error: Failed to launch chrome
```
Çözüm: Chrome binary manuel kurulumu veya headless: false ile debug

**2. Cloudflare Challenge**
```
Error: 403 Forbidden
```
Çözüm: Daha uzun bekleme süreleri, realistic user behavior

**3. JSON-LD Parse Error**
```
Error: type 'String' is not a subtype of type 'int'
```
Çözüm: Robust JSON parsing, error handling

**4. Popup Blocking Content**
```
Error: Could not extract product data
```
Çözüm: Popup kapatma logic'ini geliştir, CSS hiding

## Kaynaklar

- [Puppeteer Dart Documentation](https://pub.dev/packages/puppeteer)
- [JSON-LD Specification](https://schema.org/Product)
- [Open Graph Protocol](https://ogp.me/)
- [robots.txt Standard](https://www.robotstxt.org/)
