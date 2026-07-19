import 'package:flutter_test/flutter_test.dart';
import 'package:fiyat_takip/features/products/data/scrapers/impl/generic_html_scraper.dart';

void main() {
  group('GenericHtmlScraper', () {
    late GenericHtmlScraper scraper;

    setUp(() {
      scraper = GenericHtmlScraper();
    });

    test('canHandle should return false (used as fallback)', () {
      expect(scraper.canHandle(Uri.parse('https://www.example.com/product/test')), false);
      expect(scraper.canHandle(Uri.parse('https://www.unknown-site.com/product/test')), false);
      expect(scraper.canHandle(Uri.parse('https://trendyol.com/product/test')), false);
    });

    test('displayName should be "Generic HTML Scraper"', () {
      expect(scraper.displayName, 'Generic HTML Scraper');
    });

    test('supportedHosts should be empty', () {
      expect(scraper.supportedHosts, isEmpty);
    });

    // Note: Actual scraping tests would require HTML fixtures or mocked HTTP responses
    // The price parsing logic would be tested through integration tests with actual HTML
  });
}
