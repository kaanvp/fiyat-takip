import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// Gratis-specific scraper for Turkish site
class GratisScraper extends BaseScraper {
  GratisScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    return url.host.contains('gratis.com');
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

    // Gratis-specific selectors
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
      'Could not extract product information from Gratis page.',
      errorType: ScraperErrorType.parseError,
    );
  }

  String? _extractName(html_dom.Document document) {
    final selectors = [
      'h1',
      '[data-test-id="product-name"]',
      '[data-testid="product-name"]',
      '.product-name',
      '.product-title',
      '.product-display-name',
      '.product-header-title',
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
      '[data-test-id="price-current"]',
      '[data-testid="price-current"]',
      '.price-current',
      '.current-price',
      '.product-price',
      '.product-price-container',
      '.price-box',
      '.price-tag',
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      '[itemprop="price"]',
      '.price',
      '.fiyat',
      '.offer-price',
      '.display-price',
      '.amount',
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
      '[data-test-id="product-image"]',
      '[data-testid="product-image"]',
      '.product-image img',
      '.main-image img',
      '.product-gallery img',
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
  String get displayName => 'Gratis Scraper';

  @override
  List<String> get supportedHosts => ['gratis.com'];
}
