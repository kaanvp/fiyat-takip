import 'package:flutter_test/flutter_test.dart';
import 'package:fiyat_takip/features/products/data/scrapers/impl/hepsiburada_scraper.dart';

void main() {
  group('HepsiburadaScraper', () {
    late HepsiburadaScraper scraper;

    setUp(() {
      scraper = HepsiburadaScraper();
    });

    test('canHandle should return true for Hepsiburada URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.hepsiburada.com/product/test')), true);
      expect(scraper.canHandle(Uri.parse('https://hepsiburada.com/product/test')), true);
    });

    test('canHandle should return false for non-Hepsiburada URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.trendyol.com/product/test')), false);
      expect(scraper.canHandle(Uri.parse('https://www.amazon.com/product/test')), false);
    });

    test('displayName should be "Hepsiburada"', () {
      expect(scraper.displayName, 'Hepsiburada');
    });

    test('supportedHosts should contain Hepsiburada hosts', () {
      expect(scraper.supportedHosts, contains('hepsiburada.com'));
      expect(scraper.supportedHosts, contains('www.hepsiburada.com'));
    });
  });
}
