import 'scraper_interface.dart';

class SiteScraperRegistry {
  final List<ProductScraper> _scrapers;

  SiteScraperRegistry(this._scrapers);

  /// Get the appropriate scraper for the given URL
  /// Returns null if no scraper can handle this URL
  ProductScraper? getScraperForUrl(Uri url) {
    // First try to find a specific scraper for this site
    for (final scraper in _scrapers) {
      if (scraper.canHandle(url) && scraper.displayName != 'Puppeteer (Headless Chrome)') {
        return scraper;
      }
    }
    
    // Fallback to Puppeteer if available (most reliable for modern sites)
    final puppeteer = getScraperByDisplayName('Puppeteer (Headless Chrome)');
    if (puppeteer != null) {
      return puppeteer;
    }
    
    // Final fallback to Generic HTML Scraper
    return getScraperByDisplayName('Generic HTML Scraper');
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
