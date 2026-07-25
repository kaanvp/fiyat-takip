import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

class HepsiburadaScraper extends BaseScraper {
  HepsiburadaScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('hepsiburada.com');
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // Use non-www URL to avoid Akamai bot protection
    final normalizedUrl = url.host.startsWith('www.')
        ? url.replace(host: url.host.substring(4))
        : url;
    final response = await safeGet(normalizedUrl, extraHeaders: {
      'Referer': 'https://hepsiburada.com/',
    });

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: JSON-LD structured data
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null) return product;
    }

    // Strategy 2: Next.js / Initial State JSON
    final initialStateProduct = _extractFromInitialState(body, document, url);
    if (initialStateProduct != null) {
      return initialStateProduct;
    }

    // Strategy 3: Meta Tag extraction
    final metaProduct = _extractFromMetaTags(document, url);
    if (metaProduct != null) return metaProduct;

    // Strategy 4: HTML DOM parsing
    final name = _extractName(document);
    final priceResult = _extractPrice(document);

    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract required product information from Hepsiburada.',
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

  ScrapedProduct? _extractFromInitialState(String body, html_dom.Document document, Uri url) {
    try {
      // Check Next.js __NEXT_DATA__ script
      final nextDataScript = document.querySelector('script#__NEXT_DATA__');
      if (nextDataScript != null && nextDataScript.innerHtml.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(nextDataScript.innerHtml.trim());
          if (decoded is Map) {
            final product = _findProductInNextData(decoded, url);
            if (product != null) return product;
          }
        } catch (_) {}
      }

      // Check regex pattern for window.__INITIAL_STATE__
      final regex = RegExp(r'window\.__INITIAL_STATE__\s*=\s*(\{.+?\});', dotAll: true);
      final match = regex.firstMatch(body);
      if (match != null && match.groupCount >= 1) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map) {
            final product = _findProductInNextData(decoded, url);
            if (product != null) return product;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  ScrapedProduct? _findProductInNextData(Map<dynamic, dynamic> map, Uri url) {
    try {
      Map<dynamic, dynamic>? productObj;

      if (map['props'] is Map && map['props']['pageProps'] is Map) {
        final pageProps = map['props']['pageProps'];
        if (pageProps['product'] is Map) {
          productObj = pageProps['product'];
        } else if (pageProps['productDetail'] is Map) {
          productObj = pageProps['productDetail'];
        } else if (pageProps['initialState'] is Map) {
          final init = pageProps['initialState'];
          if (init['product'] is Map) productObj = init['product'];
        }
      }

      productObj ??= map['product'] ?? map['productDetail'];

      if (productObj != null) {
        String? name = productObj['name'] ?? productObj['title'] ?? productObj['productName'];
        double? price;
        String currency = 'TRY';
        String? imageUrl;

        if (productObj['price'] != null) {
          final p = productObj['price'];
          if (p is num) {
            price = p.toDouble();
          } else if (p is Map) {
            final rawPrice = p['currentPrice'] ?? p['value'] ?? p['amount'] ?? p['price'];
            if (rawPrice != null) {
              price = double.tryParse(rawPrice.toString());
            }
          } else {
            price = double.tryParse(p.toString());
          }
        } else if (productObj['listing'] is Map && productObj['listing']['price'] != null) {
          final p = productObj['listing']['price'];
          price = double.tryParse(p.toString());
        } else if (productObj['defaultListing'] is Map && productObj['defaultListing']['price'] != null) {
          final p = productObj['defaultListing']['price'];
          price = double.tryParse(p.toString());
        }

        final images = productObj['images'] ?? productObj['image'];
        if (images is List && images.isNotEmpty) {
          imageUrl = images.first.toString();
        } else if (images is String) {
          imageUrl = images;
        }

        if (imageUrl != null) {
          imageUrl = cleanAndNormalizeImageUrl(imageUrl, url);
        }

        if (name != null && name.isNotEmpty && price != null && price > 0) {
          return ScrapedProduct(
            name: name.replaceAll(RegExp(r'\s+'), ' ').trim(),
            imageUrl: imageUrl,
            price: price,
            currency: currency,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  ScrapedProduct? _extractFromMetaTags(html_dom.Document document, Uri url) {
    String? name;
    for (final sel in [
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
      'meta[name="title"]',
      'meta[property="product:name"]',
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
      'meta[name="twitter:data1"]',
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
      'h1[data-test-id="product-name"]',
      '[data-test-id="product-name"]',
      '[data-test-id="product-title"]',
      'h1.product-name',
      'h1[itemprop="name"]',
      'h1',
      '.product-title',
      '.product-name',
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
      // Hepsiburada variant box price (CSS modules, stable data-test-id)
      '[data-test-id="variant-box-price"]',
      '[data-test-id="price-current-price"]',
      '[data-test-id="default-price"]',
      '[data-test-id="price-current"]',
      '[data-test-id="price"]',
      '[itemprop="price"]',
      '[data-bind*="displayedPrice"]',
      '.price-current',
      '.product-price-new',
      '.price',
    ];

    final candidates = <html_dom.Element>[];
    final seen = <String>{};
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        final text = element.attributes['content'] ?? element.text.trim();
        if (text.isNotEmpty && !seen.contains(text)) {
          seen.add(text);
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
      'meta[name="twitter:image"]',
      '[data-test-id="product-image"] img',
      '.product-detail-image img',
      '.product-image img',
      '[itemprop="image"]',
      '.product-gallery img',
      '.main-image img',
    ];

    final attributePriority = [
      'content',
      'data-zoom-image',
      'data-original',
      'data-src',
      'src',
    ];

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

  @override
  String get displayName => 'Hepsiburada';

  @override
  List<String> get supportedHosts => ['hepsiburada.com', 'www.hepsiburada.com'];
}
