import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as html_dom;
import 'scraper_interface.dart';

abstract class BaseScraper implements ProductScraper {
  final http.Client client;

  BaseScraper({http.Client? client}) : client = client ?? http.Client();

  static final List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
  ];

  /// Rotates User-Agent to avoid rate limiting / blocking
  String _randomUserAgent() {
    final index = DateTime.now().millisecondsSinceEpoch % _userAgents.length;
    return _userAgents[index];
  }

  /// Default headers to mimic a real browser and avoid anti-bot measures
  Map<String, String> buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'User-Agent': _randomUserAgent(),
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate',
      'Cache-Control': 'max-age=0',
      'Upgrade-Insecure-Requests': '1',
      'DNT': '1',
    };
    // Add referer for the target host
    if (extraHeaders?.containsKey('referer') != true) {
      headers['Referer'] = 'https://www.google.com/';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Safe HTTP GET request with timeout, retry on 403, and error handling
  Future<http.Response> safeGet(Uri url, {Map<String, String>? extraHeaders}) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final headers = buildHeaders(extraHeaders: extraHeaders);
        // On retry, use a mobile User-Agent to bypass desktop blocks
        if (attempt == 1) {
          headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36';
          headers['Referer'] = url.origin;
        }

        final response = await client.get(url, headers: headers)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 403 || response.statusCode == 429) {
          if (attempt == 0) continue; // Retry with different headers
          throw ScraperException(
            'Access denied or rate limited (HTTP ${response.statusCode})',
            errorType: ScraperErrorType.blocked,
          );
        }

        if (response.statusCode == 404) {
          throw ScraperException(
            'Product not found (HTTP 404)',
            errorType: ScraperErrorType.notFound,
          );
        }

        if (response.statusCode != 200) {
          throw ScraperException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            errorType: ScraperErrorType.networkError,
          );
        }
        return response;
      } on http.ClientException catch (e) {
        if (attempt == 0) continue;
        throw ScraperException(
          'Network error: ${e.message}',
          errorType: ScraperErrorType.networkError,
        );
      } catch (e) {
        if (e is ScraperException && attempt == 0) continue;
        if (e is ScraperException) rethrow;
        throw ScraperException(
          'Unknown network error: ${e.toString()}',
          errorType: ScraperErrorType.unknown,
        );
      }
    }
    throw ScraperException('Request failed after retries', errorType: ScraperErrorType.networkError);
  }

  /// Parses price string accurately handling common formats
  (double, String)? parsePrice(String priceText) {
    // Remove all characters except digits, dot, comma and common currency symbols
    final cleaned = priceText.replaceAll(RegExp(r'[^\d.,₺€$£]'), '').trim();
    if (cleaned.isEmpty) return null;

    String currency = 'TRY';
    if (priceText.contains('₺') || priceText.contains('TL') || priceText.toLowerCase().contains('try')) {
      currency = 'TRY';
    } else if (priceText.contains('€') || priceText.toLowerCase().contains('eur')) {
      currency = 'EUR';
    } else if (priceText.contains('\$') || priceText.toLowerCase().contains('usd')) {
      currency = 'USD';
    } else if (priceText.contains('£') || priceText.toLowerCase().contains('gbp')) {
      currency = 'GBP';
    }

    String numberText = cleaned.replaceAll(RegExp(r'[₺€$£]'), '').trim();

    // Handle different number formats (1.234,56 or 1,234.56 or 1234.56)
    if (numberText.contains(',') && numberText.contains('.')) {
      // Assume last separator is decimal
      if (numberText.lastIndexOf(',') > numberText.lastIndexOf('.')) {
        // format: 1.234,56
        numberText = numberText.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // format: 1,234.56
        numberText = numberText.replaceAll(',', '');
      }
    } else if (numberText.contains(',')) {
      // In Turkish format, comma is usually decimal separator if there's only one type of separator
      // However, it could be thousands separator if it's like 1,234
      // Heuristic: if comma is followed by exactly 3 digits and it's the only separator, it MIGHT be thousands, 
      // but standard Turkish uses dot for thousands. Let's assume it's decimal.
      numberText = numberText.replaceAll(',', '.');
    }

    final price = double.tryParse(numberText);
    if (price != null && price > 0) {
      return (price, currency);
    }

    return null;
  }

  /// Ensures URL is absolute
  String makeAbsoluteUrl(String url, Uri baseUri) {
    if (url.startsWith('//')) {
      return '${baseUri.scheme}:$url';
    } else if (url.startsWith('/')) {
      return '${baseUri.scheme}://${baseUri.host}$url';
    } else if (!url.startsWith('http')) {
       return '${baseUri.scheme}://${baseUri.host}/$url';
    }
    return url;
  }

  /// Extracts data from JSON-LD scripts (<script type="application/ld+json">)
  Map<String, dynamic>? extractJsonLdProduct(html_dom.Document document) {
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');
    
    for (final script in scripts) {
      try {
        final content = script.innerHtml.trim();
        if (content.isEmpty) continue;

        final decoded = jsonDecode(content);
        
        // Handle both single object and array of objects
        final List<dynamic> items = decoded is List ? decoded : [decoded];
        
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            // Check if it's a Product schema
            final type = item['@type'];
            if (type == 'Product' || (type is List && type.contains('Product'))) {
              return item;
            }
            
            // Check nested graph structure (sometimes used by Yoast SEO etc)
            if (item['@graph'] is List) {
              for (final graphItem in item['@graph']) {
                if (graphItem is Map<String, dynamic> && graphItem['@type'] == 'Product') {
                  return graphItem;
                }
              }
            }
          }
        }
      } catch (e) {
        // Ignore json decode errors and try next script
        continue;
      }
    }
    return null;
  }

  /// Extracts standard Product details from a JSON-LD Map
  ScrapedProduct? parseProductFromJsonLd(Map<String, dynamic> jsonLd) {
    try {
      String? name = jsonLd['name']?.toString();
      if (name == null || name.isEmpty) return null;

      String? imageUrl;
      if (jsonLd['image'] != null) {
        if (jsonLd['image'] is String) {
          imageUrl = jsonLd['image'];
        } else if (jsonLd['image'] is List && jsonLd['image'].isNotEmpty) {
          imageUrl = jsonLd['image'].first.toString();
        } else if (jsonLd['image'] is Map && jsonLd['image']['url'] != null) {
           imageUrl = jsonLd['image']['url'].toString();
        }
      }

      double? price;
      String currency = 'TRY';
      bool? availability;

      final offers = jsonLd['offers'];
      if (offers != null) {
        Map<String, dynamic>? offer;
        if (offers is Map<String, dynamic>) {
          offer = offers;
        } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
          // Find lowest price offer if multiple
          offer = offers.first;
          for (final o in offers) {
             if (o is Map<String, dynamic> && o['price'] != null && offer!['price'] != null) {
                final p1 = double.tryParse(o['price'].toString()) ?? double.maxFinite;
                final p2 = double.tryParse(offer['price'].toString()) ?? double.maxFinite;
                if (p1 < p2) offer = o;
             }
          }
        }

        if (offer != null) {
          if (offer['price'] != null) {
            price = double.tryParse(offer['price'].toString());
          }
          if (offer['priceCurrency'] != null) {
            currency = offer['priceCurrency'].toString();
          }
          if (offer['availability'] != null) {
             final availStr = offer['availability'].toString().toLowerCase();
             availability = availStr.contains('instock');
          }
        }
      }

      if (price != null && price > 0) {
        return ScrapedProduct(
          name: name,
          imageUrl: imageUrl,
          price: price,
          currency: currency,
          availability: availability,
        );
      }
    } catch (e) {
      // Ignore parsing errors and return null
    }
    return null;
  }
}
