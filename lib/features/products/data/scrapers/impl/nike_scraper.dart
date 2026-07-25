import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// Nike (nike.com) scraper
/// Nike uses Next.js (__NEXT_DATA__) with product data in page props.
/// Desktop HTTP works fine - no bot protection.
class NikeScraper extends BaseScraper {
  NikeScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('nike.com');
  }

  @override
  String get displayName => 'Nike Scraper';

  @override
  List<String> get supportedHosts => ['nike.com', 'www.nike.com'];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final response = await safeGet(url, extraHeaders: {
      'Referer': 'https://www.nike.com/',
    });

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: Extract from __NEXT_DATA__ (Next.js)
    final nextDataProduct = _extractFromNextData(body, url);
    if (nextDataProduct != null) return nextDataProduct;

    // Strategy 2: JSON-LD
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null) return product;
    }

    // Strategy 3: Meta tags
    final metaProduct = _extractFromMetaTags(document, url);
    if (metaProduct != null) return metaProduct;

    // Strategy 4: HTML DOM
    final name = _extractName(document);
    final priceResult = _extractPrice(document);

    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract product information from Nike.',
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

  ScrapedProduct? _extractFromNextData(String body, Uri url) {
    try {
      final match = RegExp(
        r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
        dotAll: true,
      ).firstMatch(body);
      if (match == null) return null;

      final nextData = jsonDecode(match.group(1)!);
      
      // Navigate to product data in Nike's Next.js structure
      final props = nextData['props'];
      if (props == null) return null;
      
      final pageProps = props['pageProps'];
      if (pageProps == null) return null;
      
      // Try to find selected product
      final selectedProduct = pageProps['selectedProduct'];
      if (selectedProduct != null && selectedProduct is Map) {
        final p = _parseNikeProduct(selectedProduct, url);
        if (p != null) return p;
      }
      
      // Try product groups
      final productGroups = pageProps['productGroups'];
      if (productGroups is List && productGroups.isNotEmpty) {
        for (final group in productGroups) {
          if (group is Map) {
            final products = group['products'];
            if (products is Map) {
              for (final entry in products.entries) {
                if (entry.value is Map) {
                  final p = _parseNikeProduct(entry.value, url);
                  if (p != null) return p;
                }
              }
            }
          }
        }
      }
      
      // Try direct product data at other locations
      for (final key in ['product', 'productData', 'initialProduct', 'selectedProductData']) {
        final data = pageProps[key];
        if (data is Map) {
          final p = _parseNikeProduct(data, url);
          if (p != null) return p;
        }
      }
    } catch (_) {}
    return null;
  }

  ScrapedProduct? _parseNikeProduct(Map product, Uri url) {
    try {
      // Get name from productInfo (Nike uses productInfo.fullTitle/title)
      String? name;
      final productInfo = product['productInfo'];
      if (productInfo is Map) {
        name = productInfo['fullTitle']?.toString();
        name ??= productInfo['title']?.toString();
      }
      // Fallback to other fields
      name ??= product['productTitle']?.toString();
      name ??= product['title']?.toString();
      name ??= product['displayStyle']?.toString();
      
      if (name == null || name.isEmpty) return null;

      // Get price from prices object
      double? price;
      String currency = 'TRY';
      final prices = product['prices'];
      if (prices is Map) {
        final cp = prices['currentPrice'];
        if (cp is num && cp > 0) {
          price = cp.toDouble();
        }
        currency = prices['currency']?.toString() ?? 'TRY';
      }
      if (price == null || price <= 0) return null;

      // Get image from contentImages
      String? imageUrl;
      final contentImages = product['contentImages'];
      if (contentImages is List && contentImages.isNotEmpty) {
        final first = contentImages.first;
        if (first is String) {
          imageUrl = first;
        }
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUrl = cleanAndNormalizeImageUrl(imageUrl, url);
      }

      return ScrapedProduct(
        name: name.replaceAll(RegExp(r'\s+'), ' ').trim(),
        imageUrl: imageUrl,
        price: price,
        currency: currency,
      );
    } catch (_) {
      return null;
    }
  }

  ScrapedProduct? _extractFromMetaTags(html_dom.Document document, Uri url) {
    String? name;
    for (final sel in ['meta[property="og:title"]', 'meta[name="twitter:title"]']) {
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
    for (final sel in ['meta[property="product:price:amount"]', 'meta[property="og:price:amount"]']) {
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
    final selectors = ['h1', '[class*="product-title"]', '[class*="productTitle"]', '.product-name'];
    for (final sel in selectors) {
      final el = document.querySelector(sel);
      if (el != null) {
        final content = el.text.trim();
        if (content.isNotEmpty && content.length > 2) {
          return content.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }
    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = ['[class*="price"]', '.price', '.product-price', '[itemprop="price"]'];
    final candidates = <html_dom.Element>[];
    final seen = <String>{};
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final el in elements) {
        final text = el.attributes['content'] ?? el.text.trim();
        if (text.isNotEmpty && !seen.contains(text)) {
          seen.add(text);
          candidates.add(el);
        }
      }
    }
    return findBestPrice(candidates);
  }

  String? _extractImageUrl(html_dom.Document document, Uri url) {
    final selectors = ['meta[property="og:image"]', '[class*="product-image"] img', '[class*="gallery"] img'];
    final attrs = ['content', 'src', 'data-src'];
    for (final sel in selectors) {
      for (final el in document.querySelectorAll(sel)) {
        for (final attr in attrs) {
          final raw = el.attributes[attr];
          if (raw != null && raw.isNotEmpty) {
            final cleaned = cleanAndNormalizeImageUrl(raw, url);
            if (cleaned != null) return cleaned;
          }
        }
      }
    }
    return null;
  }
}
