import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

class GenericHtmlScraper extends BaseScraper {
  GenericHtmlScraper({http.Client? client}) : super(client: client);

  @override
  bool canHandle(Uri url) {
    // This is a fallback scraper that can handle any URL
    // It will be used explicitly as a fallback by the registry
    return false;
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final response = await safeGet(url);

    final document = html_parser.parse(response.body);

    // Strategy 1: JSON-LD (Best chance for arbitrary sites)
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
        'Could not extract required product information from this generic site.',
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
      'meta[name="twitter:title"]',
      'meta[name="title"]',
      '[itemprop="name"]',
      'h1.product-title',
      'h1.product-name',
      'h1',
      '.product-title',
      '.product-name',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'] ?? element.text.trim();
        if (content.isNotEmpty) return content;
      }
    }

    final title = document.querySelector('title');
    if (title != null) {
      final titleText = title.text.trim();
      if (titleText.isNotEmpty) return titleText;
    }

    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = [
      '[itemprop="price"]',
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      '.price',
      '.product-price',
      '.current-price',
      '.final-price',
      '.sale-price',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
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
      'meta[name="twitter:image"]',
      '[itemprop="image"]',
      '.product-image img',
      '.main-image img',
      '.product-photo img',
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
  String get displayName => 'Generic HTML Scraper';

  @override
  List<String> get supportedHosts => [];
}
