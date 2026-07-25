import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:puppeteer/puppeteer.dart';
import '../scraper_interface.dart';
import '../base_scraper.dart';
import 'generic_html_scraper.dart';

/// Smart fallback scraper that tries HTTP first, then Puppeteer if available.
/// This handles sites that block plain HTTP (Cloudflare, Akamai) by using
/// headless Chrome as a fallback.
class SmartFallbackScraper extends BaseScraper {
  final GenericHtmlScraper _httpScraper;

  SmartFallbackScraper({http.Client? client})
      : _httpScraper = GenericHtmlScraper(client: client),
        super(client: client);

  @override
  bool canHandle(Uri url) => true;

  @override
  String get displayName => 'Smart Fallback Scraper';

  @override
  List<String> get supportedHosts => [];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    // Strategy 1: Try HTTP first (works for most sites)
    try {
      return await _httpScraper.scrape(url);
    } catch (e) {
      // If HTTP fails and it's a block/JS required, try Puppeteer
      if (e is ScraperException) {
        if (e.errorType == ScraperErrorType.blocked ||
            e.errorType == ScraperErrorType.jsRequired) {
          return await _scrapeWithPuppeteer(url);
        }
      }
      rethrow;
    }
  }

  Future<ScrapedProduct> _scrapeWithPuppeteer(Uri url) async {
    // Puppeteer only works on desktop (Windows, macOS, Linux)
    if (Platform.isAndroid || Platform.isIOS) {
      throw const ScraperException(
        'Puppeteer not available on this platform',
        errorType: ScraperErrorType.networkError,
      );
    }

    Browser? browser;
    try {
      browser = await puppeteer.launch(
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--disable-gpu',
          '--window-size=1920,1080',
          '--disable-blink-features=AutomationControlled',
        ],
      );

      final page = await browser.newPage();
      await page.setViewport(DeviceViewport(width: 1920, height: 1080));
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      );

      // Anti-detection
      await page.evaluateOnNewDocument('''() => {
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
        Object.defineProperty(navigator, 'languages', { get: () => ['tr-TR', 'tr', 'en-US', 'en'] });
      }''');

      // Visit homepage for session
      try {
        await page.goto('https://${url.host}', wait: Until.domContentLoaded,
            timeout: Duration(seconds: 10));
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {}

      // Visit product page
      try {
        await page.goto(url.toString(), wait: Until.networkIdle,
            timeout: Duration(seconds: 30));
      } catch (_) {
        await page.goto(url.toString(), wait: Until.load,
            timeout: Duration(seconds: 30));
      }

      await Future.delayed(const Duration(seconds: 3));

      // Extract product data from page
      final result = await page.evaluate('''() => {
        // Try JSON-LD
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        for (const script of scripts) {
          try {
            const data = JSON.parse(script.textContent);
            const items = Array.isArray(data) ? data : [data];
            for (const item of items) {
              if (item['@type'] === 'Product' && item.name) {
                const offers = item.offers;
                return JSON.stringify({
                  name: item.name,
                  price: offers?.price ? parseFloat(offers.price) : null,
                  currency: offers?.priceCurrency || 'TRY',
                  image: Array.isArray(item.image) ? item.image[0] : (item.image || null),
                });
              }
            }
          } catch(e) {}
        }
        
        // Try meta tags
        const ogTitle = document.querySelector('meta[property="og:title"]');
        const priceMeta = document.querySelector('meta[property="product:price:amount"]');
        const ogImage = document.querySelector('meta[property="og:image"]');
        
        if (ogTitle && priceMeta) {
          return JSON.stringify({
            name: ogTitle.content,
            price: parseFloat(priceMeta.content),
            currency: 'TRY',
            image: ogImage?.content || null,
          });
        }
        
        // Try DOM
        const h1 = document.querySelector('h1');
        const priceEl = document.querySelector('[class*="price"]') || 
                        document.querySelector('[itemprop="price"]') ||
                        document.querySelector('.product-price');
        
        return JSON.stringify({
          name: ogTitle?.content || h1?.textContent?.trim() || document.title,
          price: priceEl?.textContent?.trim() || null,
          currency: 'TRY',
          image: ogImage?.content || null,
        });
      }''');

      final data = result is String ? result : result.toString();
      final parsed = _parseExtractedData(data, url);
      
      await browser.close();
      
      if (parsed != null) return parsed;
      
      throw const ScraperException(
        'Could not extract product data with Puppeteer',
        errorType: ScraperErrorType.parseError,
      );
    } catch (e) {
      if (browser != null) await browser.close();
      if (e is ScraperException) rethrow;
      throw ScraperException(
        'Puppeteer failed: $e',
        errorType: ScraperErrorType.networkError,
      );
    }
  }

  ScrapedProduct? _parseExtractedData(String jsonStr, Uri url) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = data['name']?.toString();
      final price = data['price'];
      if (name == null || name.isEmpty || price == null) return null;

      double? priceNum;
      if (price is num) {
        priceNum = price.toDouble();
      } else if (price is String) {
        priceNum = double.tryParse(price.replaceAll(RegExp(r'[^\d.,]'), '').replaceFirst(',', '.'));
      }

      if (priceNum == null || priceNum <= 0) return null;

      return ScrapedProduct(
        name: name.replaceAll(RegExp(r'\s+'), ' ').trim(),
        price: priceNum,
        currency: data['currency']?.toString() ?? 'TRY',
        imageUrl: data['image']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
