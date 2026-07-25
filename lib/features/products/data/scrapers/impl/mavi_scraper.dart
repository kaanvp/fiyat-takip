import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// Mavi (mavi.com) scraper
/// Mavi blocks www but works without www.
/// Product data is embedded in page scripts.
class MaviScraper extends BaseScraper {
  MaviScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('mavi.com');
  }

  @override
  String get displayName => 'Mavi Scraper';

  @override
  List<String> get supportedHosts => ['mavi.com', 'www.mavi.com'];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // Use non-www URL to avoid bot protection
    final normalizedUrl = url.host.startsWith('www.')
        ? url.replace(host: url.host.substring(4))
        : url;

    final response = await safeGet(normalizedUrl, extraHeaders: {
      'Referer': 'https://mavi.com/',
    });

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: Extract from page scripts (JSON data)
    final pageDataProduct = _extractFromPageData(body, url);
    if (pageDataProduct != null) return pageDataProduct;

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
        'Could not extract product information from Mavi.',
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

  ScrapedProduct? _extractFromPageData(String body, Uri url) {
    try {
      // Extract name from og:title
      String? name;
      final ogMatch = RegExp(r'<meta[^>]*property="og:title"[^>]*content="([^"]+)"').firstMatch(body);
      if (ogMatch != null) {
        name = ogMatch.group(1)!.trim();
      }
      if (name == null || name.isEmpty) {
        // Fallback to title tag
        final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(body);
        if (titleMatch != null) name = titleMatch.group(1)!.trim();
      }
      if (name == null || name.length < 3) return null;

      // Find price in page data
      double? price;
      
      // Pattern: look for price in JSON-like structures
      final priceMatch = RegExp(r'"price":(\d+(?:\.\d+)?)').firstMatch(body);
      if (priceMatch != null) {
        price = double.tryParse(priceMatch.group(1)!);
      }

      if (price != null && price > 0) {
        return ScrapedProduct(name: name, price: price, currency: 'TRY');
      }
    } catch (_) {}
    return null;
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
    if (name == null) return null;

    (double, String)? priceResult;
    for (final sel in ['meta[property="product:price:amount"]', 'meta[property="og:price:amount"]']) {
      final el = document.querySelector(sel);
      if (el != null) {
        final priceText = el.attributes['content'] ?? el.text.trim();
        priceResult = parsePrice(priceText);
        if (priceResult != null) break;
      }
    }

    if (priceResult != null) {
      return ScrapedProduct(name: name, imageUrl: _extractImageUrl(document, url), price: priceResult.$1, currency: priceResult.$2);
    }
    return null;
  }

  String? _extractName(html_dom.Document document) {
    final selectors = ['h1', '[class*="product-name"]', '[class*="productName"]', 'meta[property="og:title"]'];
    for (final sel in selectors) {
      final el = document.querySelector(sel);
      if (el != null) {
        final content = el.attributes['content'] ?? el.text.trim();
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
      for (final el in document.querySelectorAll(selector)) {
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
