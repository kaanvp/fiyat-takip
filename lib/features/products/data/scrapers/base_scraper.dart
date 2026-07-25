import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as html_dom;
import 'scraper_interface.dart';

abstract class BaseScraper implements ProductScraper {
  final http.Client client;

  BaseScraper({http.Client? client}) : client = client ?? http.Client();

  /// Default headers to mimic a real browser
  Map<String, String> buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
      'Sec-Ch-Ua': '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
      'Sec-Ch-Ua-Mobile': '?0',
      'Sec-Ch-Ua-Platform': '"Windows"',
      'Upgrade-Insecure-Requests': '1',
      'Cache-Control': 'max-age=0',
    };
    
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Simple HTTP GET request with basic error handling
  Future<http.Response> safeGet(Uri url, {Map<String, String>? extraHeaders}) async {
    try {
      final headers = buildHeaders(extraHeaders: extraHeaders);
      final response = await client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 403 || response.statusCode == 429) {
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
      throw ScraperException(
        'Network error: ${e.message}',
        errorType: ScraperErrorType.networkError,
      );
    } catch (e) {
      if (e is ScraperException) rethrow;
      throw ScraperException(
        'Unknown error: $e',
        errorType: ScraperErrorType.unknown,
      );
    }
  }

  /// Get response body with proper encoding handling
  String getResponseBody(http.Response response) {
    try {
      // Try to decode as UTF-8 first
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      // Fallback to latin1 if UTF-8 fails
      try {
        return latin1.decode(response.bodyBytes);
      } catch (e2) {
        throw ScraperException(
          'Could not decode response body (invalid encoding)',
          errorType: ScraperErrorType.parseError,
        );
      }
    }
  }

  /// Extract JSON-LD product data from page
  Map<String, dynamic>? extractJsonLdProduct(html_dom.Document document) {
    final scripts = document.querySelectorAll('script[type="application/ld+json"]');
    
    for (final script in scripts) {
      try {
        final content = script.text.trim();
        if (content.isEmpty) continue;
        
        final jsonData = jsonDecode(content);
        
        // Handle both single object and array
        final List<dynamic> jsonList = jsonData is List 
            ? jsonData 
            : [jsonData];
        
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            // Check if this is a Product
            final type = item['@type'];
            if (type != null && 
                (type == 'Product' || 
                 (type is List && type.contains('Product')))) {
              return item;
            }
          }
        }
      } catch (e) {
        // Invalid JSON, continue to next script
        continue;
      }
    }
    return null;
  }

  /// Parse product from JSON-LD data
  ScrapedProduct? parseProductFromJsonLd(Map<String, dynamic> jsonLd, {required Uri baseUri}) {
    try {
      // Extract name
      String? name = jsonLd['name'];
      if (name == null || name.isEmpty) return null;
      
      // Extract price
      double? price;
      final offers = jsonLd['offers'];
      if (offers != null) {
        if (offers is Map) {
          price = _parsePriceFromMap(Map<String, dynamic>.from(offers));
        } else if (offers is List && offers.isNotEmpty) {
          if (offers.first is Map) {
            price = _parsePriceFromMap(Map<String, dynamic>.from(offers.first));
          }
        }
      }
      
      if (price == null || price <= 0) return null;
      
      // Extract currency
      String currency = 'TRY';
      if (offers is Map && offers['priceCurrency'] != null) {
        currency = offers['priceCurrency'];
      } else if (offers is List && offers.isNotEmpty && offers.first is Map) {
        final firstOffer = Map<String, dynamic>.from(offers.first);
        currency = firstOffer['priceCurrency'] ?? 'TRY';
      }
      
      // Extract image
      String? imageUrl;
      final image = jsonLd['image'];
      if (image != null) {
        if (image is String) {
          imageUrl = cleanAndNormalizeImageUrl(image, baseUri);
        } else if (image is List && image.isNotEmpty) {
          imageUrl = cleanAndNormalizeImageUrl(image.first.toString(), baseUri);
        }
      }
      
      // Extract availability
      bool? availability;
      if (offers is Map) {
        final offersMap = Map<String, dynamic>.from(offers);
        final availabilityStr = offersMap['availability'];
        if (availabilityStr != null) {
          availability = availabilityStr.toString().contains('InStock');
        }
      }
      
      return ScrapedProduct(
        name: name,
        imageUrl: imageUrl,
        price: price,
        currency: currency,
        availability: availability,
      );
    } catch (e) {
      return null;
    }
  }
  
  double? _parsePriceFromMap(Map<String, dynamic> map) {
    final price = map['price'];
    if (price != null) {
      if (price is num) {
        return price.toDouble();
      } else if (price is String) {
        return double.tryParse(price.replaceAll(RegExp(r'[^\d.,]'), '').replaceFirst(',', '.'));
      }
    }
    return null;
  }

  /// Clean and normalize image URL
  String? cleanAndNormalizeImageUrl(String rawUrl, Uri baseUri) {
    if (rawUrl.isEmpty) return null;
    
    try {
      // Remove protocol-relative URLs
      String url = rawUrl;
      if (url.startsWith('//')) {
        url = 'https:$url';
      }
      
      // If it's already a full URL, validate and return
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final uri = Uri.parse(url);
        if (uri.hasAuthority) {
          return uri.toString();
        }
      }
      
      // If it's a relative URL, resolve against base URI
      if (url.startsWith('/')) {
        return baseUri.resolve(url).toString();
      }
      
      // Try to construct absolute URL
      return Uri.parse(url).toString();
    } catch (e) {
      return null;
    }
  }

  /// Parse price text to double and currency
  (double, String)? parsePrice(String priceText) {
    if (priceText.isEmpty) return null;
    
    // Remove common currency symbols and whitespace
    String cleaned = priceText
        .replaceAll(RegExp(r'[^\d.,₺€$\£¥]'), '')
        .trim();
    
    if (cleaned.isEmpty) return null;
    
    // Detect currency
    String currency = 'TRY';
    if (priceText.contains('€') || priceText.contains('EUR')) {
      currency = 'EUR';
    } else if (priceText.contains('\$') || priceText.contains('USD')) {
      currency = 'USD';
    } else if (priceText.contains('£') || priceText.contains('GBP')) {
      currency = 'GBP';
    } else if (priceText.contains('₺') || priceText.contains('TL')) {
      currency = 'TRY';
    }
    
    // Remove currency symbols before parsing (₺, $, €, £, ¥)
    String digitsOnly = cleaned.replaceAll(RegExp(r'[₺€$\£¥]'), '');
    
    // Handle different decimal separators
    String normalized = digitsOnly;
    if (digitsOnly.contains(',') && digitsOnly.contains('.')) {
      // Both separators exist - assume last one is decimal
      final lastDot = digitsOnly.lastIndexOf('.');
      final lastComma = digitsOnly.lastIndexOf(',');
      if (lastComma > lastDot) {
        normalized = digitsOnly.replaceAll('.', '').replaceFirst(',', '.');
      } else {
        normalized = digitsOnly.replaceAll(',', '');
      }
    } else if (digitsOnly.contains(',')) {
      // Only comma - could be decimal or thousand separator
      // For Turkish prices, comma is typically decimal
      if (currency == 'TRY') {
        normalized = digitsOnly.replaceFirst(',', '.');
      } else {
        // For other currencies, comma might be thousand separator
        normalized = digitsOnly.replaceAll(',', '');
      }
    }
    
    final price = double.tryParse(normalized);
    if (price == null || price <= 0) return null;
    
    return (price, currency);
  }

  /// Check if a DOM element represents an old/original price (strikethrough).
  bool isOldPriceElement(html_dom.Element element) {
    // Check inline style for strikethrough/line-through
    final style = (element.attributes['style'] ?? '').toLowerCase();
    if (style.contains('line-through') || style.contains('text-decoration: line-through')) {
      return true;
    }
    // Check class name for old/original/list indicators
    final className = (element.attributes['class'] ?? '').toLowerCase();
    final oldPatterns = [
      'old-price', 'oldprice', 'old_price', 'old-', 'old_',
      'original-price', 'originalprice', 'original_price',
      'list-price', 'listprice', 'list_price',
      'was-price', 'was-price', 'wasprice', 'was_price',
      'strike', 'crossed', 'deleted', 'line-through',
      'eski', 'onceki',
      // camelCase variants (lowercase for matching)
      'oldprice', 'originalprice', 'listprice', 'wasprice',
    ];
    for (final pattern in oldPatterns) {
      if (className.contains(pattern)) return true;
    }
    // Check parent elements too
    var parent = element.parent;
    for (int i = 0; i < 3 && parent != null; i++) {
      final parentStyle = (parent.attributes['style'] ?? '').toLowerCase();
      if (parentStyle.contains('line-through')) return true;
      final parentClass = (parent.attributes['class'] ?? '').toLowerCase();
      for (final pattern in oldPatterns) {
        if (parentClass.contains(pattern)) return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  /// Check if a DOM element represents a sale/discounted/current price.
  bool isSalePriceElement(html_dom.Element element) {
    final className = (element.attributes['class'] ?? '').toLowerCase();
    final salePatterns = [
      'sale-price', 'sale_price', 'saleprice',
      'current-price', 'current_price', 'currentprice',
      'discounted-price', 'discounted_price',
      'special-price', 'special_price', 'specialprice',
      'selling-price', 'selling_price', 'sellingprice',
      'final-price', 'final_price', 'finalprice',
      'price-now', 'pricenow', 'price_now',
      'campaign-price', 'campaign_price', 'campaignprice',
      'discount-price', 'discount_price', 'discountprice',
      // camelCase variants (lowercase for matching)
      'saleprice', 'currentprice', 'discountedprice',
      'specialprice', 'sellingprice', 'finalprice',
      'pricenow', 'campaignprice', 'discountprice',
    ];
    for (final pattern in salePatterns) {
      if (className.contains(pattern)) return true;
    }
    return false;
  }

  /// Given a list of price elements, pick the most likely selling price.
  /// Returns the parsed price and currency of the best candidate, or null if none found.
  (double, String)? findBestPrice(List<html_dom.Element> elements) {
    double? bestPrice;
    String bestCurrency = 'TRY';
    int bestPriority = -1;

    for (final element in elements) {
      final priceText = element.attributes['content'] ?? element.text.trim();
      if (priceText.isEmpty) continue;
      
      // Try direct parse first
      var parsed = parsePrice(priceText);
      
      // If direct parse fails, the text might have multiple concatenated prices
      // (e.g. "65,00₺57,90₺"). Try to extract individual prices.
      if (parsed == null) {
        // Find all price patterns in the text
        final priceMatches = RegExp(
          r'(\d+[.,]\d{2})\s*(?:₺|TL|TRY|USD|\$|EUR|€)?',
          caseSensitive: false,
        ).allMatches(priceText);
        
        if (priceMatches.isNotEmpty) {
          // Take the LAST price match (usually the discounted/sale price)
          final lastMatch = priceMatches.last;
          final priceStr = lastMatch.group(1)!;
          final currency = 'TRY'; // Default for Turkish sites
          final normalized = priceStr.replaceAll(',', '.');
          final price = double.tryParse(normalized);
          if (price != null && price > 0) {
            // Treat concatenated prices as medium priority
            int priority = 2;
            if (isSalePriceElement(element)) priority = 3;
            else if (isOldPriceElement(element)) priority = 1;
            
            if (priority > bestPriority || 
                (priority == bestPriority && (bestPrice == null || price < bestPrice))) {
              bestPrice = price;
              bestCurrency = currency;
              bestPriority = priority;
            }
            continue;
          }
        }
        continue;
      }
      
      final price = parsed.$1;
      final currency = parsed.$2;
      
      // Priority: sale price > non-old price > any price
      int priority = 0;
      
      if (isSalePriceElement(element)) {
        priority = 3; // Highest: explicit sale/current price
      } else if (!isOldPriceElement(element)) {
        priority = 2; // Medium: regular price (not old)
      } else {
        priority = 1; // Low: old/original price
      }
      
      // Among same priority, prefer the lowest price (most likely the sale price)
      if (priority > bestPriority || 
          (priority == bestPriority && (bestPrice == null || price < bestPrice))) {
        bestPrice = price;
        bestCurrency = currency;
        bestPriority = priority;
      }
    }
    
    if (bestPrice != null && bestPrice > 0) {
      return (bestPrice, bestCurrency);
    }
    return null;
  }
}
