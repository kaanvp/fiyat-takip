import 'package:flutter_test/flutter_test.dart';
import 'package:fiyat_takip/features/products/data/scrapers/impl/n11_scraper.dart';

void main() {
  group('N11Scraper', () {
    late N11Scraper scraper;

    setUp(() {
      scraper = N11Scraper();
    });

    test('canHandle should return true for N11 URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.n11.com/product/test')), true);
      expect(scraper.canHandle(Uri.parse('https://n11.com/product/test')), true);
    });

    test('canHandle should return false for non-N11 URLs', () {
      expect(scraper.canHandle(Uri.parse('https://www.trendyol.com/product/test')), false);
      expect(scraper.canHandle(Uri.parse('https://www.amazon.com/product/test')), false);
    });

    test('displayName should be "N11"', () {
      expect(scraper.displayName, 'N11');
    });

    test('supportedHosts should contain N11 hosts', () {
      expect(scraper.supportedHosts, contains('n11.com'));
      expect(scraper.supportedHosts, contains('www.n11.com'));
    });
  });
}
