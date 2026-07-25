import 'scraper_interface.dart';

class SiteScraperRegistry {
  final List<ProductScraper> _scrapers;

  SiteScraperRegistry(this._scrapers);

  /// Get the appropriate scraper for the given URL
  /// Returns null if no scraper can handle this URL
  ProductScraper? getScraperForUrl(Uri url) {
    // 1. Site-specific scrapers (Trendyol, Hepsiburada, N11)
    for (final scraper in _scrapers) {
      if (scraper.canHandle(url) &&
          scraper.displayName != 'Puppeteer (Headless Chrome)' &&
          scraper.displayName != 'Generic HTML Scraper' &&
          scraper.displayName != 'WebView Scraper' &&
          scraper.displayName != 'Smart Fallback Scraper') {
        return scraper;
      }
    }
    
    // 2. Fallback to Generic HTML Scraper (lightweight HTTP)
    final generic = getScraperByDisplayName('Generic HTML Scraper');
    if (generic != null) {
      return generic;
    }

    // 3. Fallback to Smart Fallback Scraper (HTTP → Puppeteer)
    final smart = getScraperByDisplayName('Smart Fallback Scraper');
    if (smart != null) {
      return smart;
    }

    // 4. Fallback to WebView Scraper (JS renderer, mobile only)
    final webview = getScraperByDisplayName('WebView Scraper');
    if (webview != null) {
      return webview;
    }
    
    // 4. Fallback to Puppeteer if available
    return getScraperByDisplayName('Puppeteer (Headless Chrome)');
  }

  /// Check if any scraper can handle the given URL
  bool canHandleUrl(Uri url) {
    return getScraperForUrl(url) != null;
  }

  /// Get all registered scrapers
  List<ProductScraper> get allScrapers => List.unmodifiable(_scrapers);

  /// Add a new scraper to the registry
  void addScraper(ProductScraper scraper) {
    _scrapers.add(scraper);
  }

  /// Get scraper by display name
  ProductScraper? getScraperByDisplayName(String displayName) {
    for (final scraper in _scrapers) {
      if (scraper.displayName == displayName) {
        return scraper;
      }
    }
    return null;
  }

  /// Get all supported hosts across all scrapers
  List<String> get allSupportedHosts {
    final hosts = <String>[];
    for (final scraper in _scrapers) {
      hosts.addAll(scraper.supportedHosts);
    }
    return hosts;
  }
}
