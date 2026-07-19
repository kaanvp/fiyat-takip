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
    final response = await safeGet(url, extraHeaders: {
      'Referer': 'https://www.hepsiburada.com/',
    });

    final document = html_parser.parse(response.body);

    // Strategy 1: JSON-LD
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd);
      if (product != null) return product;
    }

    // Strategy 2: Initial State JSON
    final initialStateProduct = _extractFromInitialState(response.body);
    if (initialStateProduct != null) {
       return initialStateProduct;
    }

    // Strategy 3: HTML Parsing as fallback
    final name = _extractName(document);
    final priceResult = _extractPrice(document);
    
    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract required product information from Hepsiburada. The page might require JavaScript or is protected by anti-bot measures.',
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

  ScrapedProduct? _extractFromInitialState(String htmlBody) {
    try {
      final regex = RegExp(r'window\.__INITIAL_STATE__\s*=\s*(\{.+?\})', dotAll: true);
      final match = regex.firstMatch(htmlBody);
      
      if (match != null && match.groupCount >= 1) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          // Note: Initial state JSON for Hepsiburada can be very complex.
          // This is a basic attempt to parse it if available.
          final decoded = jsonDecode(jsonStr);
          final productDetail = decoded['productDetail'];
          
          if (productDetail != null) {
            String? name;
            double? price;
            String? imageUrl;

            if (productDetail['product'] != null) {
               name = productDetail['product']['name'];
               if (productDetail['product']['images'] != null && productDetail['product']['images'].isNotEmpty) {
                 imageUrl = productDetail['product']['images'].first;
               }
            }

            if (productDetail['listing'] != null && productDetail['listing']['price'] != null) {
               price = double.tryParse(productDetail['listing']['price'].toString());
            }

            if (name != null && name.isNotEmpty && price != null && price > 0) {
               return ScrapedProduct(
                 name: name,
                 imageUrl: imageUrl,
                 price: price,
                 currency: 'TRY', 
               );
            }
          }
        }
      }
    } catch (e) {
      // Ignore initial state extraction errors
    }
    return null;
  }

  String? _extractName(html_dom.Document document) {
    final selectors = [
      'meta[property="og:title"]',
      'h1[data-test-id="product-name"]',
      'h1.product-name',
      'h1[itemprop="name"]',
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
      '[data-test-id="price-current"]',
      '[itemprop="price"]',
      '[data-bind*="displayedPrice"]',
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
      '[data-test-id="product-image"] img',
      '.product-detail-image img',
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
  String get displayName => 'Hepsiburada';

  @override
  List<String> get supportedHosts => ['hepsiburada.com', 'www.hepsiburada.com'];
}
