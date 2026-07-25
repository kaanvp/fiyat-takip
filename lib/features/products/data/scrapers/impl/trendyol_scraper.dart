import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

class TrendyolScraper extends BaseScraper {
  TrendyolScraper({http.Client? client}) : super(client: client) {
    // Override BaseScraper's client for Trendyol-specific handling
  }

  @override
  bool canHandle(Uri url) {
    final host = url.host.toLowerCase();
    return host.contains('trendyol.com');
  }

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // Use safeGet with Trendyol-specific headers
    final response = await safeGet(url, extraHeaders: {
      'Referer': 'https://www.trendyol.com/',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    });

    final body = getResponseBody(response);
    final document = html_parser.parse(body);

    // Strategy 1: JSON-LD
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null) return product;
    }

    // Strategy 2: Initial State JSON
    final initialStateProduct = _extractFromInitialState(body, url);
    if (initialStateProduct != null) {
       return initialStateProduct;
    }

    // Strategy 3: HTML Parsing as fallback (very fragile on Trendyol)
    final name = _extractName(document);
    final priceResult = _extractPrice(document);
    
    if (name == null || priceResult == null) {
      throw const ScraperException(
        'Could not extract required product information from Trendyol. The page might require JavaScript or is protected by anti-bot measures.',
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

  ScrapedProduct? _extractFromInitialState(String htmlBody, Uri url) {
    try {
      final regex = RegExp(r'window\.__PRODUCT_DETAIL_APP_INITIAL_STATE__\s*=\s*(\{.+?\});', dotAll: true);
      final match = regex.firstMatch(htmlBody);
      
      if (match != null && match.groupCount >= 1) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final decoded = jsonDecode(jsonStr);
          final product = decoded['product'];
          
          if (product != null) {
            String name = product['name'] ?? '';
            if (product['brand'] != null && product['brand']['name'] != null) {
              name = '${product['brand']['name']} $name'.trim();
            }

            double? price;
            if (product['price'] != null) {
               if (product['price']['discountedPrice'] != null) {
                 price = double.tryParse(product['price']['discountedPrice']['value'].toString());
               } else if (product['price']['sellingPrice'] != null) {
                 price = double.tryParse(product['price']['sellingPrice']['value'].toString());
               }
            }

            String? imageUrl;
            if (product['images'] != null && product['images'] is List && product['images'].isNotEmpty) {
              final rawFirst = product['images'].first.toString();
              final rawUrl = rawFirst.startsWith('http') ? rawFirst : (rawFirst.startsWith('//') ? 'https:$rawFirst' : 'https://cdn.dsmcdn.com$rawFirst');
              imageUrl = cleanAndNormalizeImageUrl(rawUrl, url);
            }

            bool? availability;
            if (product['inStock'] != null) {
               availability = product['inStock'] as bool;
            }

            if (name.isNotEmpty && price != null && price > 0) {
               return ScrapedProduct(
                 name: name,
                 imageUrl: imageUrl,
                 price: price,
                 currency: 'TRY', // Trendyol defaults to TRY
                 availability: availability,
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
      'meta[name="twitter:title"]',
      'h1.pr-new-br',
      'h1.product-name',
      '.pr-new-br',
      '.product-name',
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
      '.prc-dsc',
      '.product-price',
      '[class*="prc"]',
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
      '.product-detail-img img',
      '.gallery-container img',
      '[class*="product-image"] img',
      'img[src*="product"]',
    ];

    final attributePriority = [
      'content',
      'data-zoom-image',
      'data-original',
      'data-src',
      'srcset',
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
  String get displayName => 'Trendyol';

  @override
  List<String> get supportedHosts => ['trendyol.com', 'www.trendyol.com'];
}
