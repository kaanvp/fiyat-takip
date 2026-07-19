import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../scraper_interface.dart';

class WebViewScraper implements ProductScraper {
  final Duration _timeout;

  WebViewScraper({
    Duration timeout = const Duration(seconds: 30),
  }) : _timeout = timeout;

  @override
  bool canHandle(Uri url) {
    // WebView can handle any URL as a fallback
    return true;
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final completer = Completer<ScrapedProduct>();
    late WebViewController webViewController;

    try {
      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String urlString) async {
              // Start extraction immediately (SPA content handled with polling)
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Try to extract product information using JavaScript
              await _extractProductInfo(webViewController, completer, url);
            },
            onWebResourceError: (WebResourceError error) {
              if (!completer.isCompleted) {
                completer.completeError(
                  ScraperException(
                    'WebView resource error: ${error.description}',
                    errorType: _mapWebErrorToScraperError(error.errorType),
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url.toString()));

      // Set timeout for the entire operation
      _timeoutTimer(completer);

      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        throw ScraperException(
          'WebView error: ${e.toString()}',
          errorType: ScraperErrorType.unknown,
        );
      }
      rethrow;
    }
  }

  Future<void> _extractProductInfo(
    WebViewController controller,
    Completer<ScrapedProduct> completer,
    Uri url,
  ) async {
    try {
      // Strategy 1: Extract from __INITIAL_STATE__ (SPA sites like Hepsiburada)
      ScrapedProduct? product = await _extractFromInitialState(controller);
      if (product != null) {
        if (!completer.isCompleted) completer.complete(product);
        return;
      }

      // Strategy 2: Wait for SPA content + try multiple extraction approaches
      // Give SPA frameworks time to render product data
      for (int wait = 0; wait < 3; wait++) {
        await Future.delayed(const Duration(seconds: 3));

        // Try JSON-LD first (structured data)
        final jsonLdProduct = await _extractFromJsonLd(controller);
        if (jsonLdProduct != null) {
          if (!completer.isCompleted) completer.complete(jsonLdProduct);
          return;
        }

        // Try CSS selectors for price and name
        final priceResult = await _extractPrice(controller);
        final name = await _extractName(controller);
        final imageUrl = await _extractImageUrl(controller);

        if (priceResult != null && name != null && name.isNotEmpty) {
          if (!completer.isCompleted) {
            completer.complete(
              ScrapedProduct(
                name: name,
                imageUrl: imageUrl,
                price: priceResult.$1,
                currency: priceResult.$2,
              ),
            );
          }
          return;
        }
      }

      // All strategies failed
      if (!completer.isCompleted) {
        completer.completeError(
          const ScraperException(
            'Could not extract product info from page',
            errorType: ScraperErrorType.parseError,
          ),
        );
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(
          ScraperException(
            'JavaScript extraction error: ${e.toString()}',
            errorType: ScraperErrorType.parseError,
          ),
        );
      }
    }
  }

  /// Extract from window.__INITIAL_STATE__ (Hepsiburada, Trendyol SPA)
  Future<ScrapedProduct?> _extractFromInitialState(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''() => {
        try {
          const data = window.__INITIAL_STATE__;
          if (!data) return null;
          
          // Hepsiburada format
          if (data.productDetail) {
            const pd = data.productDetail;
            const name = pd.product?.name || null;
            const price = pd.listing?.price || null;
            const image = pd.product?.images?.[0] || null;
            if (name && price) {
              return JSON.stringify({ name, price: String(price), image, currency: 'TRY' });
            }
          }
          
          // Trendyol format
          if (data.product) {
            const p = data.product;
            const name = p.name || null;
            const price = p.price?.value || p.price?.amount || null;
            const image = p.images?.[0] || null;
            if (name && price) {
              return JSON.stringify({ name, price: String(price), image, currency: 'TRY' });
            }
          }
          
          return null;
        } catch(e) {
          return null;
        }
      }()''');
      
      if (result.toString().isNotEmpty && result.toString() != 'null') {
        final decoded = decodedJson(result.toString());
        if (decoded != null) {
          final priceStr = decoded['price'] ?? '';
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && decoded['name'] != null) {
            return ScrapedProduct(
              name: decoded['name']!,
              imageUrl: decoded['image'],
              price: price,
              currency: decoded['currency'] ?? 'TRY',
            );
          }
        }
      }
    } catch (e) {
      // Ignore, try next strategy
    }
    return null;
  }

  /// Extract from JSON-LD structured data
  Future<ScrapedProduct?> _extractFromJsonLd(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''() => {
        const script = document.querySelector('script[type="application/ld+json"]');
        if (!script) return null;
        try {
          const data = JSON.parse(script.textContent);
          const items = Array.isArray(data) ? data : [data];
          for (const item of items) {
            if (item['@type'] === 'Product' || (item['@type'] && item['@type'].includes && item['@type'].includes('Product'))) {
              const name = item.name || null;
              const price = item.offers?.price || item.offers?.[0]?.price || null;
              const currency = item.offers?.priceCurrency || item.offers?.[0]?.priceCurrency || 'TRY';
              const image = item.image || (Array.isArray(item.image) ? item.image[0] : null) || null;
              if (name && price) {
                return JSON.stringify({ name, price: String(price), image, currency });
              }
            }
          }
        } catch(e) {}
        return null;
      }()''');
      
      if (result.toString().isNotEmpty && result.toString() != 'null') {
        final decoded = decodedJson(result.toString());
        if (decoded != null) {
          final priceStr = decoded['price'] ?? '';
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && decoded['name'] != null) {
            return ScrapedProduct(
              name: decoded['name']!,
              imageUrl: decoded['image'],
              price: price,
              currency: decoded['currency'] ?? 'TRY',
            );
          }
        }
      }
    } catch (e) {
      // Ignore, try next strategy
    }
    return null;
  }

  /// Safely decode JSON string from JavaScript result
  Map<String, String>? decodedJson(String raw) {
    try {
      String cleaned = raw.trim();
      if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(1, cleaned.length - 1).replaceAll('\\"', '"');
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<String?> _extractName(WebViewController controller) async {
    // Try multiple JavaScript strategies to extract product name
    // Order: specific selectors first, then generic fallbacks
    final scripts = [
      // Hepsiburada specific
      "document.querySelector('[data-test-id=\"product-name\"]')?.innerText",
      "document.querySelector('[data-test-id=\"product-title\"]')?.innerText",
      "document.querySelector('h1[data-test-id=\"product-name\"]')?.innerText",
      // Generic meta tags
      "document.querySelector('meta[property=\"og:title\"]')?.getAttribute('content')",
      "document.querySelector('meta[name=\"twitter:title\"]')?.getAttribute('content')",
      // Trendyol specific
      "document.querySelector('.pr-new-br')?.innerText",
      // N11 specific
      "document.querySelector('.product-name')?.innerText",
      // Generic HTML
      "document.querySelector('h1')?.innerText",
      "document.querySelector('.product-title')?.innerText",
      "document.title",
    ];

    for (final script in scripts) {
      try {
        final result = await controller.runJavaScriptReturningResult(script);
        if (result.toString().isNotEmpty) {
          final name = result.toString().trim();
          if (name.isNotEmpty && name != 'null') {
            return name;
          }
        }
      } catch (e) {
        // Continue to next strategy
        continue;
      }
    }

    return null;
  }

  Future<(double, String)?> _extractPrice(WebViewController controller) async {
    // Try multiple JavaScript strategies to extract price
    // Order: specific selectors first, then generic fallbacks
    final scripts = [
      // JSON-LD (structured data, most reliable)
      """(() => { const s = document.querySelector('script[type="application/ld+json"]'); if(!s) return null; try { const d = JSON.parse(s.textContent); const p = d.offers?.price || d.offers?.[0]?.price; return p ? p.toString() : null; } catch(e){ return null; } })()""",
      // Hepsiburada specific
      "document.querySelector('[data-test-id=\"price-current\"]')?.innerText",
      "document.querySelector('[data-test-id=\"price\"]')?.innerText",
      "document.querySelector('[data-bind*=\"displayedPrice\"]')?.innerText",
      // Meta & itemprop
      "document.querySelector('meta[property=\"product:price:amount\"]')?.getAttribute('content')",
      "document.querySelector('meta[property=\"og:price:amount\"]')?.getAttribute('content')",
      "document.querySelector('[itemprop=\"price\"]')?.getAttribute('content')",
      // Trendyol specific
      "document.querySelector('.prc-dsc')?.innerText",
      // N11 specific
      "document.querySelector('.newPrice')?.innerText",
      // Generic class names
      "document.querySelector('.price')?.innerText",
      "document.querySelector('.product-price')?.innerText",
      "document.querySelector('.current-price')?.innerText",
      "document.querySelector('.sale-price')?.innerText",
    ];

    for (final script in scripts) {
      try {
        final result = await controller.runJavaScriptReturningResult(script);
        if (result.toString().isNotEmpty) {
          final priceText = result.toString().trim();
          if (priceText.isNotEmpty && priceText != 'null') {
            final parsed = _parsePrice(priceText);
            if (parsed != null) {
              return parsed;
            }
          }
        }
      } catch (e) {
        // Continue to next strategy
        continue;
      }
    }

    return null;
  }

  Future<String?> _extractImageUrl(WebViewController controller) async {
    // Try multiple JavaScript strategies to extract image URL
    final scripts = [
      // JSON-LD image
      """(() => { const s = document.querySelector('script[type="application/ld+json"]'); if(!s) return null; try { const d = JSON.parse(s.textContent); const img = d.image || d.image?.[0] || null; return img ? img.toString() : null; } catch(e){ return null; } })()""",
      // Meta tags
      "document.querySelector('meta[property=\"og:image\"]')?.getAttribute('content')",
      "document.querySelector('meta[name=\"twitter:image\"]')?.getAttribute('content')",
      // Hepsiburada specific
      "document.querySelector('[data-test-id=\"product-image\"] img')?.getAttribute('src')",
      "document.querySelector('.gallery-container img')?.getAttribute('src')",
      // Generic
      "document.querySelector('.product-image img')?.getAttribute('src')",
      "document.querySelector('.main-image img')?.getAttribute('src')",
      "document.querySelector('img[itemprop=\"image\"]')?.getAttribute('src')",
    ];

    for (final script in scripts) {
      try {
        final result = await controller.runJavaScriptReturningResult(script);
        if (result.toString().isNotEmpty) {
          final imageUrl = result.toString().trim();
          if (imageUrl.isNotEmpty && imageUrl != 'null') {
            return imageUrl;
          }
        }
      } catch (e) {
        // Continue to next strategy
        continue;
      }
    }

    return null;
  }

  (double, String)? _parsePrice(String priceText) {
    // Remove common currency symbols and whitespace
    final cleaned = priceText
        .replaceAll(RegExp(r'[^\d.,₺€$\£]'), '')
        .trim();

    if (cleaned.isEmpty) return null;

    String currency = 'TRY';
    String numberText = cleaned;

    if (priceText.contains('₺') || priceText.contains('TL')) {
      currency = 'TRY';
    } else if (priceText.contains('€')) {
      currency = 'EUR';
    } else if (priceText.contains('\$')) {
      currency = 'USD';
    } else if (priceText.contains('£')) {
      currency = 'GBP';
    }

    // Handle different number formats
    if (cleaned.contains(',') && cleaned.contains('.')) {
      // Assume last separator is decimal
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        numberText = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        numberText = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      // In Turkish format, comma is decimal separator
      numberText = cleaned.replaceAll(',', '.');
    }

    final price = double.tryParse(numberText);
    if (price != null && price > 0) {
      return (price, currency);
    }

    return null;
  }

  void _timeoutTimer(Completer<ScrapedProduct> completer) {
    Future.delayed(_timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          const ScraperException(
            'WebView scraping timeout',
            errorType: ScraperErrorType.networkError,
          ),
        );
      }
    });
  }

  ScraperErrorType _mapWebErrorToScraperError(WebResourceErrorType? errorType) {
    if (errorType == null) return ScraperErrorType.unknown;
    
    switch (errorType) {
      case WebResourceErrorType.hostLookup:
      case WebResourceErrorType.connect:
      case WebResourceErrorType.timeout:
        return ScraperErrorType.networkError;
      default:
        return ScraperErrorType.unknown;
    }
  }

  @override
  String get displayName => 'WebView Scraper';

  @override
  List<String> get supportedHosts => [];
}
