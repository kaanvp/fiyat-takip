import 'package:flutter_test/flutter_test.dart';
import 'package:fiyat_takip/features/products/data/scrapers/impl/trendyol_scraper.dart';

void main() {
  group('TrendyolScraper', () {
    late TrendyolScraper scraper;

    setUp(() {
      scraper = TrendyolScraper();
    });

    test('canHandle should return true for Trendyol URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.trendyol.com/product/test')), true);
      expect(scraper.canHandle(Uri.parse('https://trendyol.com/product/test')), true);
    });

    test('canHandle should return false for non-Trendyol URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.hepsiburada.com/product/test')), false);
      expect(scraper.canHandle(Uri.parse('https://www.amazon.com/product/test')), false);
    });

    test('displayName should be "Trendyol"', () {
      expect(scraper.displayName, 'Trendyol');
    });

    test('supportedHosts should contain Trendyol hosts', () {
      expect(scraper.supportedHosts, contains('trendyol.com'));
      expect(scraper.supportedHosts, contains('www.trendyol.com'));
    });

    // Note: Actual scraping tests would require HTML fixtures or mocked HTTP responses
    // These would be added in a complete test suite
  });
}
