import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../scraper_interface.dart';
import '../base_scraper.dart';

/// Universal Generic HTML Scraper — works on any e-commerce, classifieds, or
/// marketplace site that serves product data in server-rendered HTML.
///
/// Strategy order:
///   1. JSON-LD structured data (schema.org)
///   2. SPA initial state (`__NEXT_DATA__`, `__NUXT__`, Redux, etc.)
///   3. Open Graph / Twitter / product meta tags
///   4. Microdata (`itemprop`)
///   5. Heuristic DOM selectors (data-attributes, semantic classes, heading tags)
///   6. Text-node currency regex fallback
///
/// Sites that serve challenge/captcha pages or client-only SPAs will
/// propagate a `jsRequired` error so the WebView scraper can take over.
class GenericHtmlScraper extends BaseScraper {
  GenericHtmlScraper({http.Client? client}) : super(client: client);

  // ─────────────────────── Filter Lists ───────────────────────

  /// Short title text matching any of these → not a product name.
  static const List<String> _ignoredNameWords = [
    'kargo', 'garanti', 'kupon', 'taksit', 'teslimat', 'iade', 'sepet',
    'giriş', 'login', 'register', 'kaydol', 'arama', 'search', 'filtre',
    'kategori', 'category', 'yardım', 'help', 'iletişim', 'contact',
    'hakkımızda', 'about', 'gizlilik', 'privacy', 'çerez', 'cookie',
    'ekstra', 'challenge', 'captcha', 'verify', 'doğrulama',
  ];

  /// CSS class substrings that indicate a non-current (old/strike/installment)
  /// price element — skip these when searching for the real selling price.
  static const List<String> _ignoredPriceClasses = [
    'old', 'strike', 'was', 'regular', 'original', 'list-price', 'market-price',
    'taksit', 'installment', 'shipping', 'kargo', 'discount-rate', 'percent',
    'crossed', 'line-through', 'deleted', 'before', 'eski', 'prev',
  ];

  /// Patterns in the text of a price element that mean it's not a product price.
  static const List<String> _ignoredPriceTexts = [
    'taksit', 'kargo', '/ay', 'ücretsiz', 'bedava', 'free', 'aylık',
    'monthly', 'ayda', 'x ay', 'sipariş', 'indirim oranı', 'puan',
  ];

  // ─────────────────────── Interface ───────────────────────

  @override
  bool canHandle(Uri url) => true;

  @override
  String get displayName => 'Generic HTML Scraper';

  @override
  List<String> get supportedHosts => [];

  // ─────────────────────── Main ───────────────────────

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final response = await safeGet(url, extraHeaders: {
      'Referer': '${url.origin}/',
    });

    final body = getResponseBody(response);

    // Detect anti-bot / challenge pages → let WebView handle it
    if (_isChallengeOrCaptchaPage(body)) {
      throw const ScraperException(
        'Page requires JavaScript challenge validation.',
        errorType: ScraperErrorType.jsRequired,
      );
    }

    final document = html_parser.parse(body);

    // Strategy 1: JSON-LD structured data (schema.org)
    final jsonLd = extractJsonLdProduct(document);
    if (jsonLd != null) {
      final product = parseProductFromJsonLd(jsonLd, baseUri: url);
      if (product != null && _isValidProduct(product)) return product;
    }

    // Strategy 2: SPA initial state objects
    final stateProduct = _extractFromInitialState(body, document, url);
    if (stateProduct != null && _isValidProduct(stateProduct)) return stateProduct;

    // Strategy 3: Meta tags (OG / Twitter / product:* / microdata)
    final metaProduct = _extractFromMetaTags(document, url);
    if (metaProduct != null && _isValidProduct(metaProduct)) return metaProduct;

    // Strategy 4: Heuristic DOM selectors + text regex
    final domProduct = _extractUniversalDomData(document, url);
    if (domProduct != null && _isValidProduct(domProduct)) return domProduct;

    throw const ScraperException(
      'Could not extract product information from this page.',
      errorType: ScraperErrorType.parseError,
    );
  }

  // ─────────────────────── Challenge detection ───────────────────────

  bool _isChallengeOrCaptchaPage(String body) {
    final lower = body.toLowerCase();
    // Incapsula / Imperva / PerimeterX / Cloudflare / Akamai challenge pages
    if (lower.contains('challenge validation') ||
        lower.contains('challenge content') ||
        lower.contains('sec-cpt-if') ||
        lower.contains('sec-container') ||
        lower.contains('cf-challenge') ||
        lower.contains('challenge-platform') ||
        lower.contains('px-captcha') ||
        lower.contains('captcha-delivery') ||
        lower.contains('blocked by') ||
        lower.contains('just a moment') ||
        lower.contains('verify you are human') ||
        lower.contains('checking your browser') ||
        lower.contains('attention required')) {
      return true;
    }
    // Very short body with no product-like content often = challenge
    if (body.length < 2000 && !lower.contains('price') && !lower.contains('product')) {
      return true;
    }
    return false;
  }

  // ─────────────────────── Validation ───────────────────────

  bool _isValidProduct(ScrapedProduct product) {
    if (product.name.trim().length < 3) return false;
    if (_isIgnoredName(product.name)) return false;
    if (product.price <= 0) return false;
    return true;
  }

  bool _isIgnoredName(String name) {
    final lower = name.toLowerCase();
    // Only reject if it's a short string dominated by an ignored word
    if (name.length < 40) {
      for (final word in _ignoredNameWords) {
        if (lower.contains(word)) return true;
      }
    }
    return false;
  }

  bool _isIgnoredPriceElement(html_dom.Element element) {
    final classAttr = (element.attributes['class'] ?? '').toLowerCase();
    for (final ig in _ignoredPriceClasses) {
      if (classAttr.contains(ig)) return true;
    }
    // Check ancestor up to 2 levels for strikethrough
    html_dom.Element? parent = element.parent;
    for (int i = 0; i < 2 && parent != null; i++) {
      final pc = (parent.attributes['class'] ?? '').toLowerCase();
      if (pc.contains('strike') || pc.contains('old') || pc.contains('crossed') ||
          pc.contains('line-through') || pc.contains('deleted') || pc.contains('eski')) {
        return true;
      }
      final style = (parent.attributes['style'] ?? '').toLowerCase();
      if (style.contains('line-through')) return true;
      parent = parent.parent;
    }
    // Check inline style
    final style = (element.attributes['style'] ?? '').toLowerCase();
    if (style.contains('line-through')) return true;
    return false;
  }

  bool _isIgnoredPriceText(String text) {
    final lower = text.toLowerCase();
    for (final ig in _ignoredPriceTexts) {
      if (lower.contains(ig)) return true;
    }
    return false;
  }

  // ─────────────────────── Strategy 2: SPA initial state ───────────────────────

  ScrapedProduct? _extractFromInitialState(String body, html_dom.Document document, Uri url) {
    try {
      // 2a. Script tags with known IDs
      for (final id in ['__NEXT_DATA__', '__NUXT_DATA__', '__NUXT__', '__PRELOADED_STATE__', '__STATE__', '__APOLLO_STATE__', '__REMIX_CONTEXT__', '__REMIX_ROUTE__', '__INITIAL_COMPONENT_STATE__', '__DATA__', 'pageData', 'APP_DATA']) {
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

      // 2b. Regex extraction from inline <script> blocks
      final patterns = [
        RegExp(r'window\.__INITIAL_STATE__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__NUXT__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__NUXT_DATA__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'__NEXT_DATA__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__STATE__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__PRELOADED_STATE__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__APOLLO_STATE__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.product\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\._product\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.item\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.pageData\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__DATA__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.APP_DATA\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__remixContext\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__remixRoute__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
        RegExp(r'window\.__INITIAL_COMPONENT_STATE__\s*=\s*(\{.+?\});\s*(?:<|$)', dotAll: true),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(body);
        if (match != null) {
          try {
            final decoded = jsonDecode(match.group(1)!);
            if (decoded is Map) {
              final found = _findProductInMap(decoded, url);
              if (found != null) return found;
            }
          } catch (_) {}
        }
      }

      // 2c. Search ALL inline script blocks for JSON objects with product data
      final scriptElements = document.querySelectorAll('script:not([src])');
      for (final script in scriptElements) {
        final text = script.innerHtml.trim();
        if (text.length < 50 || text.length > 500000) continue;
        // Skip JSON-LD (handled separately)
        if (script.attributes['type'] == 'application/ld+json') continue;

        // Look for JSON object assignments
        final jsonPattern = RegExp(r'=\s*(\{[^;]{50,}?\});\s', dotAll: true);
        for (final match in jsonPattern.allMatches(text)) {
          try {
            final decoded = jsonDecode(match.group(1)!);
            if (decoded is Map) {
              final found = _findProductInMap(decoded, url);
              if (found != null) return found;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────── Strategy 3: Meta tags ───────────────────────

  ScrapedProduct? _extractFromMetaTags(html_dom.Document document, Uri url) {
    // Extract name from meta tags
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
        if (content != null && content.length > 2 && !_isIgnoredName(content)) {
          name = content.replaceAll(RegExp(r'\s+'), ' ').trim();
          break;
        }
      }
    }

    // Extract price from meta tags
    (double, String)? priceResult;
    String? metaCurrency;

    // Check for explicit currency meta tag first
    final currencyMeta = document.querySelector('meta[property="product:price:currency"]') ??
        document.querySelector('meta[property="og:price:currency"]');
    if (currencyMeta != null) {
      metaCurrency = currencyMeta.attributes['content']?.trim();
    }

    for (final sel in [
      'meta[property="product:price:amount"]',
      'meta[property="product:sale_price:amount"]',
      'meta[property="og:price:amount"]',
      'meta[name="twitter:data1"]',
      '[itemprop="price"]',
    ]) {
      final el = document.querySelector(sel);
      if (el != null) {
        final priceText = el.attributes['content'] ?? el.attributes['value'] ?? el.text.trim();
        priceResult = parsePrice(priceText);
        if (priceResult != null) {
          // Apply explicit currency if found
          if (metaCurrency != null && metaCurrency.isNotEmpty) {
            priceResult = (priceResult.$1, metaCurrency);
          }
          break;
        }
      }
    }

    // If we have name but no price from meta, try extracting price from DOM
    if (name != null && priceResult == null) {
      priceResult = _extractPrice(document);
    }

    // If we have price but no name from meta, try extracting name from DOM
    if (name == null && priceResult != null) {
      name = _extractName(document);
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

  // ─────────────────────── Map / State tree traversal ───────────────────────

  ScrapedProduct? _findProductInMap(Map<dynamic, dynamic> map, Uri url, {int depth = 0}) {
    if (depth > 12) return null;
    // Skip breadcrumb / navigation lists
    if (map.containsKey('itemListElement') && !map.containsKey('price')) return null;

    final String? name = _extractNameFromMap(map);

    if (name != null && name.length > 2 && !_isIgnoredName(name)) {
      double? price;
      String? currency;

      for (final key in _priceKeys) {
        if (map.containsKey(key)) {
          final result = _extractPriceFromValue(map[key]);
          if (result != null && result.$1 > 0) {
            price = result.$1;
            currency = result.$2;
            break;
          }
        }
      }
      if (price == null && map.containsKey('offers')) {
        final result = _extractPriceFromValue(map['offers']);
        if (result != null && result.$1 > 0) {
          price = result.$1;
          currency = result.$2;
        }
      }

      if (price != null && price > 0) {
        String? img = _extractImageFromMap(map, url);
        return ScrapedProduct(
          name: name.replaceAll(RegExp(r'\s+'), ' ').trim(),
          imageUrl: img,
          price: price,
          currency: currency ?? map['currency']?.toString() ??
              map['priceCurrency']?.toString() ?? 'TRY',
        );
      }
    }

    // Recurse into child maps and lists
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map) {
        final result = _findProductInMap(value, url, depth: depth + 1);
        if (result != null) return result;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final result = _findProductInMap(item, url, depth: depth + 1);
            if (result != null) return result;
          }
        }
      }
    }
    return null;
  }

  static const _nameKeys = [
    'name', 'title', 'productName', 'itemTitle', 'itemName',
    'heading', 'subject', 'productTitle', 'listingTitle', 'adTitle',
  ];

  static const _priceKeys = [
    'price', 'currentPrice', 'sellingPrice', 'discountedPrice',
    'salePrice', 'listingPrice', 'amount', 'itemPrice', 'cost',
    'formattedPrice', 'rawPrice', 'displayPrice',
    // Adidas / Next.js style nested pricing objects
    'pricing_information', 'price_information',
  ];

  String? _extractNameFromMap(Map<dynamic, dynamic> map) {
    for (final key in _nameKeys) {
      final v = map[key];
      if (v is String && v.trim().length > 2) {
        final val = v.trim();
        if (!val.startsWith('http') && !val.contains('{') && !_isIgnoredName(val)) {
          return val;
        }
      }
    }
    return null;
  }

  (double, String)? _extractPriceFromValue(dynamic val) {
    if (val == null) return null;
    if (val is num && val > 0) return (val.toDouble(), 'TRY');
    if (val is String && val.trim().isNotEmpty) {
      final lower = val.toLowerCase();
      if (lower.contains('taksit') || lower.contains('kargo') || lower.contains('indirim')) return null;
      final parsed = parsePrice(val);
      if (parsed != null && parsed.$1 > 0) return parsed;
    }
    if (val is Map) {
      // Direct price sub-keys
      for (final key in ['amount', 'value', 'price', 'raw', 'displayValue',
          'sellingPrice', 'discountedPrice', 'cost', 'currentPrice', 'text']) {
        if (val.containsKey(key)) {
          final res = _extractPriceFromValue(val[key]);
          if (res != null && res.$1 > 0) return res;
        }
      }
    }
    if (val is List && val.isNotEmpty) {
      // For price arrays, prefer "sale" type over "original", or pick the lowest price
      double? bestPrice;
      String? bestCurrency;
      for (final item in val) {
        if (item is Map) {
          final res = _extractPriceFromValue(item);
          if (res != null && res.$1 > 0) {
            final type = item['type']?.toString().toLowerCase();
            // Prefer sale/discounted prices; otherwise keep the lowest
            if (type == 'sale' || type == 'discounted' || type == 'current' ||
                bestPrice == null || res.$1 < bestPrice) {
              bestPrice = res.$1;
              bestCurrency = res.$2;
            }
          }
        } else if (item is num && item > 0) {
          if (bestPrice == null || item.toDouble() < bestPrice) {
            bestPrice = item.toDouble();
          }
        }
      }
      if (bestPrice != null) return (bestPrice, bestCurrency ?? 'TRY');
    }
    return null;
  }

  String? _extractImageFromMap(Map<dynamic, dynamic> map, Uri url) {
    for (final key in ['image', 'imageUrl', 'images', 'photo', 'photos',
        'picture', 'pictures', 'itemImage', 'thumbnail', 'thumbnailUrl',
        'mainImage', 'coverImage', 'galleryImages', 'media']) {
      final raw = map[key];
      if (raw == null) continue;

      String? candidate;
      if (raw is String && raw.trim().isNotEmpty) {
        candidate = raw;
      } else if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is String) {
          candidate = first;
        } else if (first is Map) {
          candidate = (first['url'] ?? first['src'] ?? first['original'] ??
              first['large'] ?? first['medium'])?.toString();
        }
      } else if (raw is Map) {
        candidate = (raw['url'] ?? raw['src'] ?? raw['original'] ??
            raw['large'] ?? raw['medium'])?.toString();
      }

      if (candidate != null && candidate.trim().isNotEmpty) {
        final cleaned = cleanAndNormalizeImageUrl(candidate, url);
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  // ─────────────────────── Strategy 4: Heuristic DOM ───────────────────────

  ScrapedProduct? _extractUniversalDomData(html_dom.Document document, Uri url) {
    final name = _extractName(document);
    final priceResult = _extractPrice(document);

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
      // data-attribute selectors (Letgo/OLX, modern SPAs)
      '[data-aut-id="itemTitle"]',
      '[data-aut-id*="title"]',
      '[data-aut-id*="name"]',
      '[data-qa*="title"]',
      '[data-qa*="name"]',
      '[data-qa="product-name"]',
      '[data-testid*="title"]',
      '[data-testid*="name"]',
      '[data-testid="product-name"]',
      '[data-test*="title"]',
      '[data-test-id*="title"]',
      '[data-test-id="product-name"]',
      // Specific class-based product name elements
      'h1.product-name',
      'h1.pr-new-br',
      'h1.proName',
      'h1.pdp-title',
      'h1.pro-name',
      'h1[itemprop="name"]',
      // Additional class-based selectors
      '.product-title-text',
      '.product-name-text',
      '.product-detail-name',
      '.product-detail-title',
      '.name-text',
      '.title-text',
      '.product-display-name',
      '.product-header-title',
      '.prd-title',
      '.product-header-title',
      // Generic heading
      'h1',
      'h2.product-title',
      'h2.product-name',
      // Microdata / schema
      '[itemprop="name"]',
      // Class-based
      '[class*="product-title"]',
      '[class*="product-name"]',
      '[class*="productTitle"]',
      '[class*="productName"]',
      '[class*="item-title"]',
      '[class*="item-name"]',
      '[class*="itemTitle"]',
      '[class*="itemName"]',
      '[class*="ad-title"]',
      '[class*="listing-title"]',
      // Fallback — broad class match (lower priority)
      '[class*="title"]',
      '[class*="heading"]',
      // Last resort: <title> tag
      'title',
    ];

    for (final selector in selectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          String content;
          if (selector.startsWith('meta')) {
            content = element.attributes['content'] ?? '';
          } else {
            content = element.text.trim();
          }
          if (content.isEmpty || content.length <= 2) continue;

          var cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();

          if (selector == 'title') {
            // Strip site name suffixes
            for (final sep in [' - ', ' | ', ' — ', ' :: ', ' » ']) {
              if (cleaned.contains(sep)) {
                cleaned = cleaned.split(sep).first.trim();
                break;
              }
            }
          }

          if (cleaned.length > 2 && cleaned.length < 500 && !_isIgnoredName(cleaned)) {
            return cleaned;
          }
        }
      } catch (_) {
        // Some selectors might fail on certain parsers
        continue;
      }
    }
    return null;
  }

  (double, String)? _extractPrice(html_dom.Document document) {
    final selectors = [
      // Data-attribute selectors (Letgo/OLX, modern SPAs)
      '[data-aut-id="itemPrice"]',
      '[data-aut-id*="price"]',
      '[data-aut-id*="fiyat"]',
      '[data-qa*="price"]',
      '[data-qa*="fiyat"]',
      '[data-qa="price"]',
      '[data-qa="fiyat"]',
      '[data-testid*="price"]',
      '[data-testid*="fiyat"]',
      '[data-testid="price-current"]',
      '[data-test*="price"]',
      '[data-test-id*="price"]',
      // Microdata
      '[itemprop="price"]',
      // Meta tags (some sites put price in meta in the body)
      'meta[property="product:price:amount"]',
      'meta[property="product:sale_price:amount"]',
      'meta[property="og:price:amount"]',
      'meta[name="twitter:data1"]',
      // Common e-commerce classes (specific → generic)
      '.newPrice ins',
      '.newPrice',
      '.prc-dsc',
      '.prc-slg',
      '.prc-org',
      '.prc-hp',
      '.pdp-price',
      '.product-price-container .current',
      '[class*="current-price"]',
      '[class*="sale-price"]',
      '[class*="selling-price"]',
      '[class*="final-price"]',
      '[class*="special-price"]',
      '[class*="discounted-price"]',
      '[class*="product-price"]',
      '[class*="price-new"]',
      '[class*="price-box"]',
      '[class*="price-container"]',
      '[class*="price-tag"]',
      '[class*="price-tag-text"]',
      '[class*="price-display"]',
      '[class*="price-value"]',
      '[class*="price-text"]',
      '[class*="price-amount"]',
      '[class*="fiyat"]',
      '[class*="fiyat-kutu"]',
      '[class*="fiyat-bilgisi"]',
      // Broader class patterns
      '[class*="price"]',
      '[class*="fiyat"]',
    ];

    final candidates = <html_dom.Element>[];
    final seen = <String>{};
    for (final selector in selectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          if (_isIgnoredPriceElement(element)) continue;

          final priceText = element.attributes['content'] ??
              element.attributes['value'] ?? element.text.trim();
          if (priceText.isEmpty) continue;
          if (_isIgnoredPriceText(priceText)) continue;
          if (seen.contains(priceText)) continue;

          seen.add(priceText);
          candidates.add(element);
        }
      } catch (_) {
        continue;
      }
    }

    final bestPrice = findBestPrice(candidates);
    if (bestPrice != null) return bestPrice;

    // Fallback: scan leaf text nodes for currency patterns
    final priceRegex = RegExp(
      r'(?:₺|TL|TRY|\$|USD|€|EUR|£)\s*[\d.,]+|\b[\d.,]+\s*(?:₺|TL|TRY|EUR|€|USD|\$|GBP|£)',
      caseSensitive: false,
    );

    final textCandidates = <html_dom.Element>[];
    final seenTexts = <String>{};
    for (final tag in ['span', 'div', 'p', 'b', 'strong', 'em', 'h1', 'h2', 'h3', 'h4', 'td']) {
      final elements = document.querySelectorAll(tag);
      for (final element in elements) {
        if (element.children.isNotEmpty) continue; // Only leaf nodes
        if (_isIgnoredPriceElement(element)) continue;

        final text = element.text.trim();
        if (text.isEmpty || text.length > 100) continue;
        if (_isIgnoredPriceText(text)) continue;
        if (seenTexts.contains(text)) continue;

        if (priceRegex.hasMatch(text)) {
          seenTexts.add(text);
          textCandidates.add(element);
        }
      }
    }

    return findBestPrice(textCandidates);
  }

  String? _extractImageUrl(html_dom.Document document, Uri url) {
    final selectors = [
      // Data-attribute selectors (Letgo/OLX)
      '[data-aut-id="itemImage"] img',
      '[data-aut-id="itemImage"]',
      '[data-aut-id*="image"] img',
      '[data-aut-id*="image"]',
      '[data-aut-id*="photo"] img',
      '[data-aut-id*="photo"]',
      '[data-qa*="image"] img',
      '[data-qa*="image"]',
      '[data-testid*="image"] img',
      '[data-testid*="image"]',
      '[data-test*="image"] img',
      // Meta tags (most reliable for images)
      'meta[property="og:image"]',
      'meta[property="og:image:url"]',
      'meta[property="og:image:secure_url"]',
      'meta[name="twitter:image"]',
      'meta[name="twitter:image:src"]',
      // Microdata
      '[itemprop="image"]',
      'img[itemprop="image"]',
      // Gallery / product image containers
      '[class*="gallery"] img',
      '[class*="photo"] img',
      '[class*="picture"] img',
      '[class*="slider"] img',
      '[class*="carousel"] img',
      '[class*="product-image"] img',
      '[class*="product-photo"] img',
      '[class*="pdp"] img',
      '[class*="detail"] img',
      '[class*="hero"] img',
      '[class*="main-image"] img',
      '[class*="zoom"] img',
      // Generic img as last resort
      'img[src*="product"]',
      'img[src*="item"]',
      'img',
    ];

    final attributePriority = [
      'content',
      'data-zoom-image',
      'data-high-res',
      'data-original',
      'data-full',
      'data-large',
      'data-src',
      'data-lazy-src',
      'data-lazy',
      'srcset',
      'src',
    ];

    for (final selector in selectors) {
      try {
        final elements = document.querySelectorAll(selector);
        for (final element in elements) {
          for (final attr in attributePriority) {
            final raw = element.attributes[attr];
            if (raw == null || raw.trim().isEmpty) continue;
            final cleaned = cleanAndNormalizeImageUrl(raw, url);
            if (cleaned != null) return cleaned;
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
