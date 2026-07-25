import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

class N11Scraper extends BaseScraper {
  N11Scraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('n11.com');
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // Try with mobile user-agent and non-www first
    Uri requestUrl = url;
    Map<String, String> extraHeaders = {
      'Referer': 'https://n11.com/',
    };

    // Try non-www first (avoids bot protection)
    if (url.host.startsWith('www.')) {
      requestUrl = url.replace(host: url.host.substring(4));
    }

    http.Response response;
    try {
      response = await safeGet(requestUrl, extraHeaders: extraHeaders);
    } catch (e) {
      // If non-www fails, try www
      if (requestUrl != url) {
        response = await safeGet(url, extraHeaders: extraHeaders);
      } else {
        rethrow;
      }
    }

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: JSON-LD structured data
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null) return product;
    }

    // Strategy 2: Extract from embedded page data (mobileWebPrice, product data)
    final pageDataProduct = _extractFromPageData(body, url);
    if (pageDataProduct != null) return pageDataProduct;

    // Strategy 3: Meta Tag extraction
    final metaProduct = _extractFromMetaTags(document, url);
    if (metaProduct != null) return metaProduct;

    // Strategy 4: HTML DOM parsing
    final name = _extractName(document);
    final priceResult = _extractPrice(document);

    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract required product information from N11.',
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

  /// Extract product data from embedded page JSON
  ScrapedProduct? _extractFromPageData(String body, Uri url) {
    try {
      // Extract name from HTML h1
      String? name;
      final h1Match = RegExp(r'<h1[^>]*>(.*?)</h1>', dotAll: true).firstMatch(body);
      if (h1Match != null) {
        name = h1Match.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }
      if (name == null || name.isEmpty || name.length < 3) return null;

      // Find price from variant JSON data (inStock variant's price)
      double? price;
      
      // Pattern: find inStock variant's price
      final variantRegex = RegExp(
        r'"outOfStock":(?:false|null).{0,200}"price":"(\d+(?:[.,]\d+)?)\s*(?:TL|₺)"',
        dotAll: true,
      );
      final variantMatch = variantRegex.firstMatch(body);
      if (variantMatch != null) {
        price = double.tryParse(variantMatch.group(1)!.replaceAll(',', '.'));
      }

      // Fallback: any "price":"... TL" pattern
      if (price == null || price <= 0) {
        final priceMatch = RegExp(r'"price":"(\d+(?:[.,]\d+)?)\s*(?:TL|₺)"').firstMatch(body);
        if (priceMatch != null) {
          price = double.tryParse(priceMatch.group(1)!.replaceAll(',', '.'));
        }
      }

      if (price != null && price > 0) {
        return ScrapedProduct(name: name, price: price, currency: 'TRY');
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
      'h1.proName',
      '[itemprop="name"]',
      '.proName',
      'h1.product-name',
      'h1',
      '.product-title',
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
      '.newPrice ins',
      '.newPrice',
      '[itemprop="price"]',
      '#productPrice',
      '.unf-p-box--price',
      '.priceContainer',
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
      '[itemprop="image"]',
      '.product-img img',
      '.detailPhotoImg img',
      '.product-image img',
      '.main-product-image img',
      '.gallery-image img',
    ];

    final attributePriority = [
      'content',
      'data-src',
      'data-original',
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
  String get displayName => 'N11';

  @override
  List<String> get supportedHosts => ['n11.com', 'www.n11.com'];
}
