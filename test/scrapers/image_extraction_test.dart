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
  group('BaseScraper - cleanAndNormalizeImageUrl', () {
    late TestScraper scraper;
    final baseUri = Uri.parse('https://www.example.com/product/123');

    setUp(() {
      scraper = TestScraper();
    });

    test('Standard absolute URL', () {
      final res = scraper.cleanAndNormalizeImageUrl('https://cdn.site.com/img.jpg', baseUri);
      expect(res, 'https://cdn.site.com/img.jpg');
    });

    test('Protocol-relative URL', () {
      final res = scraper.cleanAndNormalizeImageUrl('//cdn.site.com/img.webp', baseUri);
      expect(res, 'https://cdn.site.com/img.webp');
    });

    test('Root-relative path', () {
      final res = scraper.cleanAndNormalizeImageUrl('/images/product.png', baseUri);
      expect(res, 'https://www.example.com/images/product.png');
    });

    test('Relative path', () {
      final res = scraper.cleanAndNormalizeImageUrl('media/photo.avif', baseUri);
      expect(res, 'https://www.example.com/media/photo.avif');
    });

    test('srcset candidate resolution (picks highest w)', () {
      const srcset = 'https://img.com/a.jpg 300w, https://img.com/b.jpg 600w, https://img.com/c.jpg 1200w';
      final res = scraper.cleanAndNormalizeImageUrl(srcset, baseUri);
      expect(res, 'https://img.com/c.jpg');
    });

    test('srcset multiplier candidate resolution (picks highest x)', () {
      const srcset = 'https://img.com/low.jpg 1x, https://img.com/high.jpg 2x';
      final res = scraper.cleanAndNormalizeImageUrl(srcset, baseUri);
      expect(res, 'https://img.com/high.jpg');
    });

    test('Rejects data URI base64 placeholder', () {
      const dataUri = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
      final res = scraper.cleanAndNormalizeImageUrl(dataUri, baseUri);
      expect(res, isNull);
    });

    test('Rejects 1x1 / blank transparent gif placeholder', () {
      final res = scraper.cleanAndNormalizeImageUrl('https://site.com/assets/blank.gif', baseUri);
      expect(res, isNull);
    });

    test('CDN image URL with WebP format query parameter', () {
      final res = scraper.cleanAndNormalizeImageUrl('https://cdn.dsmcdn.com/product.jpg?format=webp&quality=80', baseUri);
      expect(res, 'https://cdn.dsmcdn.com/product.jpg?format=webp&quality=80');
    });

    test('Null or empty returns null', () {
      expect(scraper.cleanAndNormalizeImageUrl(null, baseUri), isNull);
      expect(scraper.cleanAndNormalizeImageUrl('   ', baseUri), isNull);
    });
  });
}
