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
    final response = await safeGet(url, extraHeaders: {
      'Referer': 'https://www.n11.com/',
    });

    final document = html_parser.parse(response.body);

    // Strategy 1: JSON-LD
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd);
      if (product != null) return product;
    }

    // Strategy 2: HTML Parsing as fallback
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

  String? _extractName(html_dom.Document document) {
    final selectors = [
      'meta[property="og:title"]',
      'h1.proName',
      '[itemprop="name"]',
      '.proName',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'] ?? element.text.trim();
        if (content.isNotEmpty) return content;
      }
    }
    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = [
      'meta[property="product:price:amount"]',
      '[itemprop="price"]',
      '.newPrice ins', // N11 specific: the discounted price is usually inside an <ins> tag within .newPrice
      '.newPrice', // Fallback to full newPrice container if ins is not there
      '#productPrice',
      '.unf-p-box--price',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        // Prefer the last element if multiple (sometimes there's a list price and a sale price)
        // or just use the first if it's the exact specific selector
        final element = selector == '.newPrice ins' || selector == '[itemprop="price"]' 
            ? elements.first 
            : elements.last;
            
        final priceText = element.attributes['content'] ?? element.text.trim();
        final parsed = parsePrice(priceText);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String? _extractImageUrl(html_dom.Document document, Uri url) {
    final selectors = [
      'meta[property="og:image"]',
      '[itemprop="image"]',
      '.product-img img',
      '.detailPhotoImg img',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final imageUrl = element.attributes['content'] ?? element.attributes['src'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return makeAbsoluteUrl(imageUrl, url);
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
