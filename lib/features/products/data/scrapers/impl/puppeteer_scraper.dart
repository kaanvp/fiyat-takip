import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:puppeteer/puppeteer.dart';
import '../scraper_interface.dart';

/// Puppeteer-based scraper that uses headless Chrome for JavaScript execution
/// Only supported on Desktop platforms (Windows, macOS, Linux).
class PuppeteerScraper extends ProductScraper {
  @override
  bool canHandle(Uri url) {
    // Puppeteer requires native Chrome binary execution & packageConfig isolates,
    // which is not supported on Android, iOS, or Web.
    if (kIsWeb) return false;
    if (Platform.isAndroid || Platform.isIOS) return false;
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
      // Strategy 1: JSON-LD
      final jsonLdData = await page.evaluate('''() => {
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        const results = [];
        scripts.forEach(script => {
          try {
            const data = JSON.parse(script.textContent);
            results.push(data);
          } catch(e) {}
        });
        return results;
      }''');

      for (var scriptData in jsonLdData) {
        try {
          final product = _parseProductFromJsonLd(scriptData);
          if (product != null) return product;
        } catch (e) {}
      }

      // Strategy 2: Enhanced Meta tags + Global State
      final enhancedData = await page.evaluate('''() => {
        const results = {};
        
        // Meta tags - comprehensive
        const metaPriceSelectors = [
          'meta[property="product:price:amount"]',
          'meta[property="product:sale_price:amount"]',
          'meta[property="og:price:amount"]',
          'meta[name="twitter:data1"]',
          '[itemprop="price"]'
        ];
        
        const metaNameSelectors = [
          'meta[property="og:title"]',
          'meta[name="twitter:title"]',
          'meta[name="title"]',
          'meta[property="product:name"]',
          '[itemprop="name"]'
        ];
        
        const metaImageSelectors = [
          'meta[property="og:image"]',
          'meta[property="og:image:url"]',
          'meta[name="twitter:image"]',
          '[itemprop="image"]'
        ];
        
        const metaCurrencySelectors = [
          'meta[property="product:price:currency"]',
          'meta[property="og:price:currency"]'
        ];
        
        for (const sel of metaPriceSelectors) {
          const el = document.querySelector(sel);
          if (el && el.content) {
            results['price'] = el.content;
            break;
          }
        }
        
        for (const sel of metaNameSelectors) {
          const el = document.querySelector(sel);
          if (el && el.content) {
            results['name'] = el.content;
            break;
          }
        }
        
        for (const sel of metaImageSelectors) {
          const el = document.querySelector(sel);
          if (el && el.content) {
            results['image'] = el.content;
            break;
          }
        }
        
        for (const sel of metaCurrencySelectors) {
          const el = document.querySelector(sel);
          if (el && el.content) {
            results['currency'] = el.content;
            break;
          }
        }
        
        // Global state objects
        try {
          if (window.__NEXT_DATA__) results['__NEXT_DATA__'] = window.__NEXT_DATA__;
          if (window.__INITIAL_STATE__) results['__INITIAL_STATE__'] = window.__INITIAL_STATE__;
          if (window.__NUXT__) results['__NUXT__'] = window.__NUXT__;
          if (window.__PRELOADED_STATE__) results['__PRELOADED_STATE__'] = window.__PRELOADED_STATE__;
          if (window.__STATE__) results['__STATE__'] = window.__STATE__;
          if (window.pageData) results['pageData'] = window.pageData;
          if (window.__DATA__) results['__DATA__'] = window.__DATA__;
          if (window.APP_DATA) results['APP_DATA'] = window.APP_DATA;
          if (window.__APOLLO_STATE__) results['__APOLLO_STATE__'] = window.__APOLLO_STATE__;
          if (window.product) results['product'] = window.product;
          if (window._product) results['_product'] = window._product;
          if (window.item) results['item'] = window.item;
          if (window.__remixContext) results['__remixContext'] = window.__remixContext;
        } catch(e) {}
        
        return results;
      }''');

      // Try meta tags first
      if (enhancedData['name'] != null && enhancedData['price'] != null) {
        final price = _parsePrice(enhancedData['price'].toString());
        if (price != null) {
          return ScrapedProduct(
            name: enhancedData['name'].toString(),
            imageUrl: enhancedData['image']?.toString(),
            price: price.$1,
            currency: enhancedData['currency']?.toString() ?? price.$2,
          );
        }
      }

      // Try global state objects
      for (final key in ['__NEXT_DATA__', '__INITIAL_STATE__', '__NUXT__', '__PRELOADED_STATE__', '__STATE__', 'pageData', '__DATA__', 'APP_DATA', '__APOLLO_STATE__', 'product', '_product', 'item', '__remixContext']) {
        if (enhancedData[key] != null) {
          final product = _findProductInMap(enhancedData[key], url);
          if (product != null) return product;
        }
      }

      // Strategy 3: Comprehensive DOM selectors
      final domData = await page.evaluate('''() => {
        const results = {};
        
        const priceSelectors = [
          '[data-aut-id="itemPrice"]',
          '[data-aut-id*="price"]',
          '[data-aut-id*="fiyat"]',
          '[data-qa*="price"]',
          '[data-qa*="fiyat"]',
          '[data-testid*="price"]',
          '[data-testid*="fiyat"]',
          '[data-test*="price"]',
          '[data-test-id*="price"]',
          '[itemprop="price"]',
          'meta[property="product:price:amount"]',
          'meta[property="og:price:amount"]',
          '.newPrice ins',
          '.newPrice',
          '.prc-dsc',
          '.prc-slg', 
          '.prc-org',
          '.prc-hp',
          '.pdp-price',
          '.product-price-container .current',
          '[class*="current-price"]',
          '[class*="sale-price"]',
          '[class*="selling-price"]',
          '[class*="final-price"]',
          '[class*="special-price"]',
          '[class*="discounted-price"]',
          '[class*="product-price"]',
          '[class*="price-new"]',
          '[class*="price-box"]',
          '[class*="price-container"]',
          '[class*="price-tag"]',
          '[class*="price-tag-text"]',
          '[class*="price-display"]',
          '[class*="price-value"]',
          '[class*="price-text"]',
          '[class*="price-amount"]',
          '[class*="fiyat"]',
          '[class*="fiyat-kutu"]',
          '[class*="fiyat-bilgisi"]',
          '[class*="price"]',
          '.price',
          '.fiyat',
          '.offer-price',
          '.display-price',
          '.amount'
        ];
        
        priceSelectors.forEach(selector => {
          const el = document.querySelector(selector);
          if (el) {
            const text = el.content || el.textContent?.trim();
            if (text) results['price'] = text;
          }
        });
        
        const nameSelectors = [
          '[data-aut-id="itemTitle"]',
          '[data-aut-id*="title"]',
          '[data-aut-id*="name"]',
          '[data-qa*="title"]',
          '[data-qa*="name"]',
          '[data-qa="product-name"]',
          '[data-testid*="title"]',
          '[data-testid*="name"]',
          '[data-testid="product-name"]',
          '[data-test*="title"]',
          '[data-test-id*="title"]',
          '[data-test-id="product-name"]',
          'h1.product-name',
          'h1.pr-new-br',
          'h1.proName',
          'h1.pdp-title',
          'h1.pro-name',
          'h1[itemprop="name"]',
          '[itemprop="name"]',
          '.product-title-text',
          '.product-name-text',
          '.product-detail-name',
          '.product-detail-title',
          '.name-text',
          '.title-text',
          '.product-display-name',
          '.product-header-title',
          '.prd-title',
          '.product-header-title',
          'h1',
          'h2.product-title',
          'h2.product-name',
          '.product-title',
          '.product-name',
          '[class*="product-title"]',
          '[class*="product-name"]',
          '[class*="productTitle"]',
          '[class*="productName"]',
          '[class*="item-title"]',
          '[class*="item-name"]',
          '[class*="itemTitle"]',
          '[class*="itemName"]',
          '[class*="ad-title"]',
          '[class*="listing-title"]',
          '[class*="title"]',
          '[class*="heading"]'
        ];
        
        nameSelectors.forEach(selector => {
          const els = document.querySelectorAll(selector);
          if (els.length > 0) {
            results['name'] = els[0].textContent?.trim();
          }
        });
        
        const imageSelectors = [
          'meta[property="og:image"]',
          'meta[property="og:image:url"]',
          'meta[property="og:image:secure_url"]',
          'meta[name="twitter:image"]',
          '[data-aut-id="itemImage"] img',
          '[data-aut-id="itemImage"]',
          '[data-aut-id*="image"] img',
          '[data-aut-id*="image"]',
          '[data-aut-id*="photo"] img',
          '[data-qa*="image"] img',
          '[data-qa*="image"]',
          '[data-testid*="image"] img',
          '[data-testid*="image"]',
          '[data-test*="image"] img',
          '[itemprop="image"]',
          'img[itemprop="image"]',
          '[class*="gallery"] img',
          '[class*="photo"] img',
          '[class*="picture"] img',
          '[class*="slider"] img',
          '[class*="carousel"] img',
          '[class*="product-image"] img',
          '[class*="product-photo"] img',
          '[class*="pdp"] img',
          '[class*="detail"] img',
          '[class*="hero"] img',
          '[class*="main-image"] img',
          '[class*="zoom"] img',
          'img[src*="product"]',
          'img[src*="item"]',
          'img'
        ];
        
        const imgAttrs = ["content","data-zoom-image","data-high-res","data-original","data-full","data-large","data-src","data-lazy-src","data-lazy","srcset","src"];
        
        for (const selector of imageSelectors) {
          const els = document.querySelectorAll(selector);
          for (const el of els) {
            for (const attr of imgAttrs) {
              const val = el.getAttribute(attr);
              if (val && val.trim()) {
                results['image'] = val.trim();
                break;
              }
            }
            if (results['image']) break;
          }
          if (results['image']) break;
        }
        
        return results;
      }''');

      if (domData['name'] != null && domData['price'] != null) {
        final price = _parsePrice(domData['price'].toString());
        if (price != null) {
          return ScrapedProduct(
            name: domData['name'].toString(),
            imageUrl: domData['image']?.toString(),
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

  ScrapedProduct? _findProductInMap(dynamic data, Uri url) {
    try {
      if (data is! Map) return null;
      
      final nameKeys = ['name', 'title', 'productName', 'itemTitle', 'itemName', 'heading', 'subject', 'productTitle', 'listingTitle', 'adTitle'];
      final priceKeys = ['price', 'currentPrice', 'sellingPrice', 'discountedPrice', 'salePrice', 'listingPrice', 'amount', 'itemPrice', 'cost', 'formattedPrice', 'rawPrice', 'displayPrice'];
      
      String? foundName;
      for (final key in nameKeys) {
        final value = data[key];
        if (value is String && value.trim().length > 2) {
          foundName = value.trim();
          break;
        }
      }
      
      if (foundName == null) return null;
      
      double? foundPrice;
      String? foundCurrency;
      
      for (final key in priceKeys) {
        final value = data[key];
        if (value != null) {
          if (value is num && value > 0) {
            foundPrice = value.toDouble();
            break;
          } else if (value is String) {
            final parsed = _parsePrice(value);
            if (parsed != null && parsed.$1 > 0) {
              foundPrice = parsed.$1;
              foundCurrency = parsed.$2;
              break;
            }
          }
        }
      }
      
      if (foundPrice == null) {
        // Try offers object
        final offers = data['offers'];
        if (offers is Map) {
          final price = offers['price'];
          if (price is num && price > 0) {
            foundPrice = price.toDouble();
            foundCurrency = offers['priceCurrency']?.toString() ?? 'TRY';
          } else if (price is String) {
            final parsed = _parsePrice(price);
            if (parsed != null) {
              foundPrice = parsed.$1;
              foundCurrency = parsed.$2;
            }
          }
        }
      }
      
      if (foundPrice == null || foundPrice <= 0) return null;
      
      String? foundImage;
      final imageKeys = ['image', 'imageUrl', 'images', 'photo', 'photos', 'picture', 'pictures', 'itemImage', 'thumbnail', 'thumbnailUrl', 'mainImage', 'coverImage', 'media'];
      
      for (final key in imageKeys) {
        final value = data[key];
        if (value != null) {
          if (value is String && value.trim().isNotEmpty) {
            foundImage = value.trim();
            break;
          } else if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String) {
              foundImage = first;
              break;
            } else if (first is Map) {
              foundImage = first['url']?.toString() ?? first['src']?.toString();
              if (foundImage != null) break;
            }
          } else if (value is Map) {
            foundImage = value['url']?.toString() ?? value['src']?.toString();
            if (foundImage != null) break;
          }
        }
      }
      
      return ScrapedProduct(
        name: foundName.replaceAll(RegExp(r'\s+'), ' ').trim(),
        imageUrl: foundImage,
        price: foundPrice,
        currency: foundCurrency ?? 'TRY',
      );
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
    final cleanText = priceText.replaceAll(RegExp(r'[^\d.,]'), '');
    final normalizedText = cleanText.replaceAll(',', '.');
    final price = double.tryParse(normalizedText);
    
    if (price == null || price <= 0) return null;
    
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
  List<String> get supportedHosts => ['*'];
}
