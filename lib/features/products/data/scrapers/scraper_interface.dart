class ScrapedProduct {
  final String name;
  final String? imageUrl;
  final double price;
  final String currency;
  final bool? availability;

  const ScrapedProduct({
    required this.name,
    this.imageUrl,
    required this.price,
    required this.currency,
    this.availability,
  });

  @override
  String toString() {
    return 'ScrapedProduct(name: $name, imageUrl: $imageUrl, price: $price, currency: $currency, availability: $availability)';
  }
}

enum ScraperErrorType {
  networkError,
  parseError,
  notFound,
  blocked,
  jsRequired,
  unknown,
}

class ScraperException implements Exception {
  final String message;
  final ScraperErrorType errorType;

  const ScraperException(this.message, {this.errorType = ScraperErrorType.unknown});

  @override
  String toString() => 'ScraperException: $message (type: $errorType)';
}

abstract class ProductScraper {
  /// Check if this scraper can handle the given URL
  bool canHandle(Uri url);

  /// Scrape product information from the given URL
  /// Throws ScraperException if scraping fails
  Future<ScrapedProduct> scrape(Uri url);

  /// Get the display name for this scraper (e.g., "Trendyol")
  String get displayName;

  /// Get the host names this scraper handles (e.g., ["trendyol.com", "www.trendyol.com"])
  List<String> get supportedHosts;
}
