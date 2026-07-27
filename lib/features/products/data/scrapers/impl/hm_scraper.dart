import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// H&M-specific scraper for SPA site
class HmScraper extends BaseScraper {
  HmScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    return url.host.contains('hm.com');
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final response = await safeGet(url, extraHeaders: {
      'Referer': url.origin,
    });

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Try JSON-LD first
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null && product.price > 0) return product;
    }

    // Try SPA state extraction
    final stateProduct = _extractFromInitialState(body, document, url);
    if (stateProduct != null && stateProduct.price > 0) return stateProduct;

    // H&M-specific selectors
    final name = _extractName(document);
    final priceResult = _extractPrice(document);
    final imageUrl = _extractImageUrl(document, url);

    if (name != null && priceResult != null) {
      return ScrapedProduct(
        name: name,
        imageUrl: imageUrl,
        price: priceResult.$1,
        currency: priceResult.$2,
      );
    }

    throw const ScraperException(
      'Could not extract product information from H&M page.',
      errorType: ScraperErrorType.parseError,
    );
  }

  ScrapedProduct? _extractFromInitialState(String body, html_dom.Document document, Uri url) {
    try {
      // H&M uses various state objects
      for (final id in ['__NEXT_DATA__', '__STATE__', '__NUXT__', '__NUXT_DATA__', '__APOLLO_STATE__']) {
        final scriptEl = document.querySelector('script#$id');
        if (scriptEl != null && scriptEl.innerHtml.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(scriptEl.innerHtml.trim());
            if (decoded is Map) {
              final found = _findProductInMap(decoded, url);
              if (found != null) return found;
            }
          } catch (_) {}
        }
      }
    } catch (e) {}
    return null;
  }

  ScrapedProduct? _findProductInMap(Map<dynamic, dynamic> map, Uri url) {
    try {
      final nameKeys = ['name', 'title', 'productName', 'articleName', 'product'];
      final priceKeys = ['price', 'currentPrice', 'sellingPrice', 'amount', 'priceValue', 'whitePrice'];

      String? foundName;
      for (final key in nameKeys) {
        final value = map[key];
        if (value is String && value.trim().length > 2) {
          foundName = value.trim();
          break;
        }
      }

      if (foundName == null) return null;

      double? foundPrice;
      for (final key in priceKeys) {
        final value = map[key];
        if (value != null) {
          if (value is num && value > 0) {
            foundPrice = value.toDouble();
            break;
          } else if (value is String) {
            final parsed = parsePrice(value);
            if (parsed != null && parsed.$1 > 0) {
              foundPrice = parsed.$1;
              break;
            }
          }
        }
      }

      if (foundPrice == null || foundPrice <= 0) return null;

      String? foundImage;
      final imageKeys = ['image', 'imageUrl', 'images', 'media', 'articleMedia'];
      for (final key in imageKeys) {
        final value = map[key];
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
          }
        }
      }

      return ScrapedProduct(
        name: foundName.replaceAll(RegExp(r'\s+'), ' ').trim(),
        imageUrl: foundImage,
        price: foundPrice,
        currency: 'TRY',
      );
    } catch (e) {
      return null;
    }
  }

  String? _extractName(html_dom.Document document) {
    final selectors = [
      'h1',
      '[data-testid="product-name"]',
      '[data-qa="product-name"]',
      '.product-name',
      '.product-detail-title',
      '.product-name-text',
      'meta[property="og:title"]',
    ];

    for (final selector in selectors) {
      final el = document.querySelector(selector);
      if (el != null) {
        final text = el.attributes['content'] ?? el.text.trim();
        if (text.isNotEmpty && text.length > 3) {
          return text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }
    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = [
      '[data-testid="price"]',
      '[data-qa="price"]',
      '.price',
      '.product-price',
      '.current-price',
      '.selling-price',
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      '[itemprop="price"]',
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
      '[data-testid="product-image"]',
      '[data-qa="product-image"]',
      '.product-image img',
      '.product-detail-image img',
      '[itemprop="image"]',
    ];

    for (final selector in selectors) {
      final el = document.querySelector(selector);
      if (el != null) {
        final src = el.attributes['content'] ?? el.attributes['src'] ?? el.attributes['data-src'];
        if (src != null && src.isNotEmpty && src.startsWith('http')) {
          return src;
        }
      }
    }
    return null;
  }

  @override
  String get displayName => 'H&M Scraper';

  @override
  List<String> get supportedHosts => ['hm.com', 'www2.hm.com'];
}
