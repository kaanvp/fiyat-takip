import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// LC Waikiki (lcw.com) scraper
/// LCW blocks desktop User-Agent but allows mobile User-Agent.
/// Product data is available in JSON-LD structured data.
class LcwScraper extends BaseScraper {
  LcwScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('lcw.com') || host.contains('lcwaikiki.com');
  }

  @override
  String get displayName => 'LCW Scraper';

  @override
  List<String> get supportedHosts => ['lcw.com', 'www.lcw.com', 'lcwaikiki.com'];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // LCW blocks desktop User-Agent, use mobile instead
    final mobileHeaders = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Referer': 'https://www.lcw.com/',
    };

    final response = await safeGet(url, extraHeaders: mobileHeaders);
    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: JSON-LD structured data (LCW has Product JSON-LD with mobile UA)
    final jsonLdProduct = _extractProductJsonLd(document, url);
    if (jsonLdProduct != null) return jsonLdProduct;

    // Strategy 2: Meta Tag extraction
    final metaProduct = _extractFromMetaTags(document, url);
    if (metaProduct != null) return metaProduct;

    // Strategy 3: HTML DOM parsing
    final name = _extractName(document);
    final priceResult = _extractPrice(document);

    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract required product information from LCW.',
        errorType: ScraperErrorType.parseError,
      );
    }

    return ScrapedProduct(
      name: name,
      imageUrl: _extractImageUrl(document, url),
      price: priceResult.$1,
      currency: priceResult.$2,
    );
  }

  /// Extract Product data from JSON-LD scripts (LCW has Product schema with mobile UA)
  ScrapedProduct? _extractProductJsonLd(html_dom.Document document, Uri url) {
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (final script in scripts) {
      try {
        final content = script.text.trim();
        if (content.isEmpty) continue;
        final data = jsonDecode(content);

        // Handle single object
        if (data is Map<String, dynamic>) {
          final product = _parseJsonLdProduct(data, url);
          if (product != null) return product;
        }
        // Handle array
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final product = _parseJsonLdProduct(item, url);
              if (product != null) return product;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  ScrapedProduct? _parseJsonLdProduct(Map<String, dynamic> json, Uri url) {
    final type = json['@type'];
    if (type == null || (type != 'Product' && (type is! List || !type.contains('Product')))) {
      return null;
    }

    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;

    double? price;
    String currency = 'TRY';
    final offers = json['offers'];
    if (offers is Map) {
      final priceVal = offers['price'];
      if (priceVal is num) {
        price = priceVal.toDouble();
      } else if (priceVal is String) {
        price = double.tryParse(priceVal.replaceAll(RegExp(r'[^\d.,]'), '').replaceFirst(',', '.'));
      }
      currency = offers['priceCurrency']?.toString() ?? 'TRY';
    }

    if (price == null || price <= 0) return null;

    String? imageUrl;
    final image = json['image'];
    if (image is String) {
      imageUrl = cleanAndNormalizeImageUrl(image, url);
    } else if (image is List && image.isNotEmpty) {
      imageUrl = cleanAndNormalizeImageUrl(image.first.toString(), url);
    }

    return ScrapedProduct(
      name: name,
      imageUrl: imageUrl,
      price: price,
      currency: currency,
    );
  }

  ScrapedProduct? _extractFromMetaTags(html_dom.Document document, Uri url) {
    String? name;
    for (final sel in [
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
      'meta[name="title"]',
    ]) {
      final el = document.querySelector(sel);
      if (el != null) {
        final content = el.attributes['content']?.trim();
        if (content != null && content.length > 2) {
          name = content.replaceAll(RegExp(r'\s+'), ' ').trim();
          break;
        }
      }
    }

    (double, String)? priceResult;
    for (final sel in [
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      '[itemprop="price"]',
    ]) {
      final el = document.querySelector(sel);
      if (el != null) {
        final priceText = el.attributes['content'] ?? el.text.trim();
        priceResult = parsePrice(priceText);
        if (priceResult != null) break;
      }
    }

    if (name != null && priceResult != null) {
      return ScrapedProduct(
        name: name,
        imageUrl: _extractImageUrl(document, url),
        price: priceResult.$1,
        currency: priceResult.$2,
      );
    }
    return null;
  }

  String? _extractName(html_dom.Document document) {
    final selectors = [
      'h1',
      '[class*="product-name"]',
      '[class*="productName"]',
      '.product-title',
      '[itemprop="name"]',
    ];
    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.text.trim();
        if (content.isNotEmpty && content.length > 2) {
          return content.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }
    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = [
      '[class*="price"]',
      '[class*="Price"]',
      '.price',
      '.product-price',
      '.current-price',
      '.sale-price',
      '[itemprop="price"]',
    ];
    final candidates = <html_dom.Element>[];
    final seen = <String>{};
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        final priceText = element.attributes['content'] ?? element.text.trim();
        if (priceText.isNotEmpty && !seen.contains(priceText)) {
          seen.add(priceText);
          candidates.add(element);
        }
      }
    }
    return findBestPrice(candidates);
  }

  String? _extractImageUrl(html_dom.Document document, Uri url) {
    final selectors = [
      'meta[property="og:image"]',
      'meta[property="og:image:secure_url"]',
      '[class*="product-image"] img',
      '[class*="gallery"] img',
      '[itemprop="image"]',
      'img[src*="product"]',
    ];
    final attributePriority = ['content', 'src', 'data-src', 'data-original'];
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        for (final attr in attributePriority) {
          final raw = element.attributes[attr];
          if (raw != null && raw.trim().isNotEmpty) {
            final cleaned = cleanAndNormalizeImageUrl(raw, url);
            if (cleaned != null) return cleaned;
          }
        }
      }
    }
    return null;
  }
}
