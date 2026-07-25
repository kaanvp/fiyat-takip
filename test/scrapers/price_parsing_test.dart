import 'package:flutter_test/flutter_test.dart';
import 'package:fiyat_takip/features/products/data/scrapers/base_scraper.dart';
import 'package:fiyat_takip/features/products/data/scrapers/scraper_interface.dart';

class TestScraper extends BaseScraper {
  @override
  bool canHandle(Uri url) => true;

  @override
  String get displayName => 'Test Scraper';

  @override
  List<String> get supportedHosts => [];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    throw UnimplementedError();
  }
}

void main() {
  group('BaseScraper - parsePrice', () {
    late TestScraper scraper;

    setUp(() {
      scraper = TestScraper();
    });

    test('Turkish thousand dot with decimal comma (1.234,50 ₺)', () {
      final res = scraper.parsePrice('1.234,50 ₺');
      expect(res, isNotNull);
      expect(res!.$1, 1234.50);
      expect(res.$2, 'TRY');
    });

    test('Turkish thousand dot without decimals (1.234 TL)', () {
      final res = scraper.parsePrice('1.234 TL');
      expect(res, isNotNull);
      expect(res!.$1, 1234.0);
      expect(res.$2, 'TRY');
    });

    test('Turkish 5-digit price with dot (14.999 ₺)', () {
      final res = scraper.parsePrice('14.999 ₺');
      expect(res, isNotNull);
      expect(res!.$1, 14999.0);
      expect(res.$2, 'TRY');
    });

    test('Turkish multi-million price (1.234.567 TL)', () {
      final res = scraper.parsePrice('1.234.567 TL');
      expect(res, isNotNull);
      expect(res!.$1, 1234567.0);
      expect(res.$2, 'TRY');
    });

    test('Turkish comma decimal only (1234,50 TRY)', () {
      final res = scraper.parsePrice('1234,50 TRY');
      expect(res, isNotNull);
      expect(res!.$1, 1234.50);
      expect(res.$2, 'TRY');
    });

    test('US price with comma thousand and dot decimal (\$1,234.50)', () {
      final res = scraper.parsePrice('\$1,234.50');
      expect(res, isNotNull);
      expect(res!.$1, 1234.50);
      expect(res.$2, 'USD');
    });

    test('Euro price (€1.234,00)', () {
      final res = scraper.parsePrice('€1.234,00');
      expect(res, isNotNull);
      expect(res!.$1, 1234.0);
      expect(res.$2, 'EUR');
    });

    test('GBP price (£59.99)', () {
      final res = scraper.parsePrice('£59.99');
      expect(res, isNotNull);
      expect(res!.$1, 59.99);
      expect(res.$2, 'GBP');
    });

    test('Plain integer (500 TL)', () {
      final res = scraper.parsePrice('500 TL');
      expect(res, isNotNull);
      expect(res!.$1, 500.0);
      expect(res.$2, 'TRY');
    });

    test('Decimal dot with 2 digits (14.99 ₺)', () {
      final res = scraper.parsePrice('14.99 ₺');
      expect(res, isNotNull);
      expect(res!.$1, 14.99);
      expect(res.$2, 'TRY');
    });

    test('Empty or invalid string returns null', () {
      expect(scraper.parsePrice(''), isNull);
      expect(scraper.parsePrice('Stokta yok'), isNull);
    });
  });
}
