import 'package:puppeteer/puppeteer.dart';
import '../scraper_interface.dart';

/// Puppeteer-based scraper that uses headless Chrome for JavaScript execution
/// This can bypass Cloudflare and other modern anti-bot protections
class PuppeteerScraper extends ProductScraper {
  @override
  bool canHandle(Uri url) {
    // This is a fallback scraper that can handle any site
    // It's more resource-intensive but more reliable
    return true;
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    Browser? browser;
    try {
      // Launch headless Chrome with anti-detection measures
      browser = await puppeteer.launch(
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--disable-gpu',
          '--window-size=1920,1080',
          '--disable-blink-features=AutomationControlled',
        ],
      );

      final page = await browser.newPage();

      // Set realistic viewport and user agent
      await page.setViewport(DeviceViewport(width: 1920, height: 1080, deviceScaleFactor: 1));
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
      );

      // Set extra HTTP headers
      await page.setExtraHTTPHeaders({
        'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      });

      // Remove automation indicators
      await page.evaluateOnNewDocument('''() => {
        Object.defineProperty(navigator, 'webdriver', {
          get: () => undefined,
        });
        Object.defineProperty(navigator, 'plugins', {
          get: () => [1, 2, 3, 4, 5],
        });
        Object.defineProperty(navigator, 'languages', {
          get: () => ['tr-TR', 'tr', 'en-US', 'en'],
        });
      }''');

      // Visit homepage first for session establishment
      final host = url.host;
      try {
        await page.goto('https://$host', wait: Until.domContentLoaded);
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        // Homepage visit might fail, continue with product page
      }

      // Visit product page
      try {
        await page.goto(url.toString(), wait: Until.networkIdle, timeout: Duration(seconds: 30));
      } catch (e) {
        // Fallback to load event if networkIdle times out
        await page.goto(url.toString(), wait: Until.load);
      }

      // Wait for dynamic content
      await Future.delayed(const Duration(seconds: 3));

      // Handle cookie consent popups
      await _handlePopups(page);

      // Try to extract product data
      final product = await _extractProductData(page, url);
      
      if (product == null) {
        throw const ScraperException(
          'Could not extract product data using Puppeteer. The page structure might have changed.',
          errorType: ScraperErrorType.parseError,
        );
      }

      await browser.close();
      return product;

    } catch (e) {
      if (browser != null) {
        await browser.close();
      }
      throw ScraperException(
        'Puppeteer scraping failed: $e',
        errorType: ScraperErrorType.unknown,
      );
    }
  }

  Future<void> _handlePopups(Page page) async {
    try {
      // Hide all overlays and modals with CSS
      await page.evaluate('''() => {
        const style = document.createElement('style');
        style.textContent = `[class*="modal"], [class*="overlay"], [class*="popup"], [class*="dialog"], [class*="consent"], [class*="cookie"], [id*="modal"], [id*="overlay"], [id*="popup"], [id*="consent"], [id*="cookie"], [class*="privacy"] { display: none !important; visibility: hidden !important; opacity: 0 !important; }`;
        document.head.appendChild(style);
        
        // Try to click common cookie consent buttons
        const cookieSelectors = [
          'button[id*="cookie"]',
          'button[class*="cookie"]',
          'button[id*="consent"]',
          'button[class*="consent"]',
          'button[id*="accept"]',
          'button[class*="accept"]',
          '.cookie-accept',
          '.consent-accept',
          '#cookie-accept',
          '#consent-accept',
          '.cookie-btn',
          '.consent-btn',
          '#cookie-btn',
          '#consent-btn',
          '.btn-accept',
          '.btn-close',
          '#btn-accept',
          '#btn-close',
          'button[class*="modal"]',
          'button[class*="close"]',
          'button[aria-label*="close"]',
          'button[aria-label*="Close"]',
          '.modal-close',
          '#modal-close',
          '[class*="privacy"] button',
          '[class*="gizlilik"] button'
        ];
        
        cookieSelectors.forEach(selector => {
          const buttons = document.querySelectorAll(selector);
          buttons.forEach(button => {
            try {
              if (button.offsetParent !== null) {
                button.click();
              }
            } catch(e) {
              // Ignore errors
            }
          });
        });
      }''');

      // Scroll to trigger lazy loading
      await page.evaluate('''() => {
        window.scrollTo(0, document.body.scrollHeight / 2);
      }''');
      
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      // Popup handling might fail, continue anyway
    }
  }

  Future<ScrapedProduct?> _extractProductData(Page page, Uri url) async {
    try {
      // Strategy 1: JSON-LD (most reliable)
      final jsonLdData = await page.evaluate('''() => {
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        const results = [];
        scripts.forEach(script => {
          try {
            const data = JSON.parse(script.textContent);
            results.push(data);
          } catch(e) {
            // Ignore parse errors
          }
        });
        return results;
      }''');

      for (var scriptData in jsonLdData) {
        try {
          final product = _parseProductFromJsonLd(scriptData);
          if (product != null) return product;
        } catch (e) {
          // Continue to next script
        }
      }

      // Strategy 2: Meta tags
      final metaTags = await page.evaluate('''() => {
        const results = {};
        const priceAmount = document.querySelector('meta[property="product:price:amount"]');
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        
        if (priceAmount) results['price'] = priceAmount.content;
        if (ogTitle) results['title'] = ogTitle.content;
        if (ogImage) results['image'] = ogImage.content;
        
        return results;
      }''');

      if (metaTags['title'] != null && metaTags['price'] != null) {
        final price = _parsePrice(metaTags['price'].toString());
        if (price != null) {
          return ScrapedProduct(
            name: metaTags['title'].toString(),
            imageUrl: metaTags['image']?.toString(),
            price: price.$1,
            currency: price.$2,
          );
        }
      }

      // Strategy 3: DOM selectors
      final domData = await page.evaluate('''() => {
        const results = {};
        
        // Price selectors
        const priceSelectors = [
          '.prc-dsc',
          '.prc-slg', 
          '.prc-org',
          '.prc-hp',
          '.price',
          '.product-price',
          '[data-testid="price"]',
          '.current-price',
          '.final-price',
          '.discounted-price',
          '.selling-price',
          '.original-price'
        ];
        
        priceSelectors.forEach(selector => {
          const el = document.querySelector(selector);
          if (el) {
            results['price'] = el.textContent?.trim();
          }
        });
        
        // Name selectors
        const nameSelectors = [
          'h1',
          'h2',
          '.product-title',
          '.product-name',
          '[data-testid="product-title"]',
          '.prc-nm',
          '.prc-hd',
          '.product-detail-title',
          '.detail-title'
        ];
        
        nameSelectors.forEach(selector => {
          const els = document.querySelectorAll(selector);
          if (els.length > 0) {
            results['name'] = els[0].textContent?.trim();
          }
        });
        
        return results;
      }''');

      if (domData['name'] != null && domData['price'] != null) {
        final price = _parsePrice(domData['price'].toString());
        if (price != null) {
          return ScrapedProduct(
            name: domData['name'].toString(),
            price: price.$1,
            currency: price.$2,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  ScrapedProduct? _parseProductFromJsonLd(dynamic data) {
    try {
      Map<String, dynamic>? productData;
      
      if (data is Map && data['@type'] == 'Product') {
        productData = Map<String, dynamic>.from(data);
      } else if (data is List) {
        for (final item in data) {
          if (item is Map && item['@type'] == 'Product') {
            productData = Map<String, dynamic>.from(item);
            break;
          }
        }
      }
      
      if (productData == null) return null;

      final name = productData['name']?.toString();
      if (name == null || name.isEmpty) return null;

      double? price;
      String currency = 'TRY';

      final offers = productData['offers'];
      if (offers is Map) {
        price = double.tryParse(offers['price']?.toString() ?? '');
        currency = offers['priceCurrency']?.toString() ?? 'TRY';
      } else if (offers is List && offers.isNotEmpty) {
        final firstOffer = offers.first;
        if (firstOffer is Map) {
          price = double.tryParse(firstOffer['price']?.toString() ?? '');
          currency = firstOffer['priceCurrency']?.toString() ?? 'TRY';
        }
      }

      if (price == null || price <= 0) return null;

      String? imageUrl;
      final image = productData['image'];
      if (image is String) {
        imageUrl = image;
      } else if (image is List && image.isNotEmpty) {
        imageUrl = image.first.toString();
      }

      return ScrapedProduct(
        name: name,
        imageUrl: imageUrl,
        price: price,
        currency: currency,
      );
    } catch (e) {
      return null;
    }
  }

  (double, String)? _parsePrice(String priceText) {
    // Remove currency symbols and extract numbers
    final cleanText = priceText.replaceAll(RegExp(r'[^\d.,]'), '');
    final normalizedText = cleanText.replaceAll(',', '.');
    final price = double.tryParse(normalizedText);
    
    if (price == null || price <= 0) return null;
    
    // Detect currency from original text
    String currency = 'TRY';
    if (priceText.contains('\$') || priceText.contains('USD')) {
      currency = 'USD';
    } else if (priceText.contains('€') || priceText.contains('EUR')) {
      currency = 'EUR';
    }
    
    return (price, currency);
  }

  @override
  String get displayName => 'Puppeteer (Headless Chrome)';

  @override
  List<String> get supportedHosts => ['*']; // Fallback for all sites
}
