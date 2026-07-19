// Advanced scraper using Puppeteer for headless Chrome automation
// This can bypass Cloudflare and other JavaScript-based protections
// Run with: dart run test_scrapers_puppeteer.dart

import 'package:puppeteer/puppeteer.dart';

Future<void> testSiteWithPuppeteer(String siteName, String url, {bool headless = true}) async {
  print('\n${'=' * 60}');
  print('🔍 Testing: $siteName');
  print('URL: $url');
  print('Mode: ${headless ? "Headless" : "Headful (visible)"}');
  print('=' * 60);

  try {
    // Launch browser with realistic settings
    print('\n🚀 Launching Chrome...');
    final browser = await puppeteer.launch(
      headless: headless,
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

    // Set realistic viewport and user agent
    await page.setViewport(DeviceViewport(width: 1920, height: 1080, deviceScaleFactor: 1));
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
    );
    
    // Set extra HTTP headers to bypass some bot detection
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    });

    // Remove automation indicators
    await page.evaluateOnNewDocument('''() => {
      Object.defineProperty(navigator, 'webdriver', {
        get: () => undefined,
      });
      Object.defineProperty(navigator, 'plugins', {
        get: () => [1, 2, 3, 4, 5],
      });
      Object.defineProperty(navigator, 'languages', {
        get: () => ['tr-TR', 'tr', 'en-US', 'en'],
      });
      
      // Auto-reject cookie consents
      window.addEventListener('load', function() {
        setTimeout(function() {
          const buttons = document.querySelectorAll('button');
          buttons.forEach(btn => {
            const text = btn.textContent.toLowerCase();
            if (text.includes('kabul') || text.includes('accept') || text.includes('tamam')) {
              btn.click();
            }
          });
        }, 1000);
      });
    }''');

    print('✅ Browser launched successfully');

    // First visit homepage to establish session
    final uri = Uri.parse(url);
    final homepageUrl = 'https://${uri.host}';
    
    print('\n🌐 Step 1: Visiting homepage...');
    try {
      await page.goto(homepageUrl, wait: Until.domContentLoaded);
      print('✅ Homepage loaded');
      
      // Wait to simulate human behavior
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('⚠️  Homepage visit failed: $e');
    }

    // Now visit the actual product page
    print('\n🛒 Step 2: Visiting product page...');
    try {
      await page.goto(url, wait: Until.networkIdle, timeout: Duration(seconds: 30));
      print('✅ Product page loaded');
      
      // Wait for dynamic content to load
      await Future.delayed(const Duration(seconds: 5));
      
      // Try to close cookie consent popups with more aggressive approach
      await page.evaluate('''() => {
        // Hide all overlays and modals with CSS
        const style = document.createElement('style');
        style.textContent = `[class*="modal"], [class*="overlay"], [class*="popup"], [class*="dialog"], [class*="consent"], [class*="cookie"], [id*="modal"], [id*="overlay"], [id*="popup"], [id*="consent"], [id*="cookie"], [class*="privacy"] { display: none !important; visibility: hidden !important; opacity: 0 !important; }`;
        document.head.appendChild(style);
        
        // Try to find and click common cookie consent buttons
        const cookieSelectors = [
          'button[id*="cookie"]',
          'button[class*="cookie"]',
          'button[id*="consent"]',
          'button[class*="consent"]',
          'button[id*="accept"]',
          'button[class*="accept"]',
          '.cookie-accept',
          '.consent-accept',
          '#cookie-accept',
          '#consent-accept',
          '.cookie-btn',
          '.consent-btn',
          '#cookie-btn',
          '#consent-btn',
          '.btn-accept',
          '.btn-close',
          '#btn-accept',
          '#btn-close',
          // Trendyol specific
          'button[class*="modal"]',
          'button[class*="close"]',
          'button[aria-label*="close"]',
          'button[aria-label*="Close"]',
          '.modal-close',
          '#modal-close',
          '[class*="privacy"] button',
          '[class*="gizlilik"] button'
        ];
        
        cookieSelectors.forEach(selector => {
          const buttons = document.querySelectorAll(selector);
          buttons.forEach(button => {
            try {
              if (button.offsetParent !== null) { // Visible check
                button.click();
              }
            } catch(e) {
              // Ignore errors
            }
          });
        });
      }''');
      
      // Scroll down to trigger lazy loading
      await page.evaluate('''() => {
        window.scrollTo(0, document.body.scrollHeight / 2);
      }''');
      await Future.delayed(const Duration(seconds: 2));
      
      // Additional wait to ensure any remaining popups are handled
      await Future.delayed(const Duration(seconds: 2));
      
      // Wait after closing popups
      await Future.delayed(const Duration(seconds: 3));
      
    } catch (e) {
      print('⚠️  Product page navigation issue: $e');
      // Try with different wait condition
      try {
        await page.goto(url, wait: Until.load);
        print('✅ Product page loaded (load event)');
        await Future.delayed(const Duration(seconds: 5));
        
        // Try to close cookie consent popups with more aggressive approach
        await page.evaluate('''() => {
          // Hide all overlays and modals with CSS
          const style = document.createElement('style');
          style.textContent = `[class*="modal"], [class*="overlay"], [class*="popup"], [class*="dialog"], [class*="consent"], [class*="cookie"], [id*="modal"], [id*="overlay"], [id*="popup"], [id*="consent"], [id*="cookie"], [class*="privacy"] { display: none !important; visibility: hidden !important; opacity: 0 !important; }`;
          document.head.appendChild(style);
          
          // Try to find and click common cookie consent buttons
          const cookieSelectors = [
            'button[id*="cookie"]',
            'button[class*="cookie"]',
            'button[id*="consent"]',
            'button[class*="consent"]',
            'button[id*="accept"]',
            'button[class*="accept"]',
            '.cookie-accept',
            '.consent-accept',
            '#cookie-accept',
            '#consent-accept',
            '.cookie-btn',
            '.consent-btn',
            '#cookie-btn',
            '#consent-btn',
            '.btn-accept',
            '.btn-close',
            '#btn-accept',
            '#btn-close',
            'button[class*="modal"]',
            'button[class*="close"]',
            'button[aria-label*="close"]',
            'button[aria-label*="Close"]',
            '.modal-close',
            '#modal-close',
            '[class*="privacy"] button',
            '[class*="gizlilik"] button'
          ];
          
          cookieSelectors.forEach(selector => {
            const buttons = document.querySelectorAll(selector);
            buttons.forEach(button => {
              try {
                if (button.offsetParent !== null) {
                  button.click();
                }
              } catch(e) {
                // Ignore errors
              }
            });
          });
        }''');
        
        // Scroll down to trigger lazy loading
        await page.evaluate('''() => {
          window.scrollTo(0, document.body.scrollHeight / 2);
        }''');
        await Future.delayed(const Duration(seconds: 2));
        
        // Additional wait to ensure any remaining popups are handled
        await Future.delayed(const Duration(seconds: 2));
        
        await Future.delayed(const Duration(seconds: 3));
        
      } catch (e2) {
        print('❌ Failed to load product page: $e2');
        await browser.close();
        return;
      }
    }

    // Extract page title
    final title = await page.evaluate<String>('() => document.title');
    print('\n📄 Page Title: $title');

    // Check for Cloudflare challenge
    final isCloudflare = await page.evaluate<bool>('''() => {
      return document.body.innerHTML.includes('Cloudflare') || 
             document.body.innerHTML.includes('Attention Required') ||
             document.body.innerHTML.includes('Checking your browser');
    }''');
    
    if (isCloudflare) {
      print('⚠️  Cloudflare challenge detected, waiting...');
      await Future.delayed(const Duration(seconds: 10));
      
      // Check if we passed the challenge
      final stillCloudflare = await page.evaluate<bool>('''() => {
        return document.body.innerHTML.includes('Cloudflare') || 
               document.body.innerHTML.includes('Attention Required');
      }''');
      
      if (stillCloudflare) {
        print('❌ Still blocked by Cloudflare');
        await browser.close();
        return;
      } else {
        print('✅ Cloudflare challenge passed');
      }
    }

    // Extract JSON-LD data
    print('\n📋 JSON-LD Extraction:');
    final jsonLdData = await page.evaluate('''() => {
      const scripts = document.querySelectorAll('script[type="application/ld+json"]');
      const results = [];
      scripts.forEach(script => {
        try {
          const data = JSON.parse(script.textContent);
          results.push(data);
        } catch(e) {
          // Ignore parse errors
        }
      });
      return results;
    }''');

    print('   Found ${jsonLdData.length} JSON-LD scripts');
    
    for (var i = 0; i < jsonLdData.length; i++) {
      final script = jsonLdData[i];
      try {
        final type = script['@type'];
        print('   Script[$i] @type: $type');
        
        bool isProduct = false;
        if (script is Map && script['@type'] == 'Product') isProduct = true;
        if (script is List) {
          for (final item in script) {
            if (item is Map && item['@type'] == 'Product') { 
              isProduct = true; 
              break; 
            }
          }
        }
        
        if (isProduct) {
          final product = script is List 
              ? script.firstWhere((e) => e['@type'] == 'Product', orElse: () => {}) 
              : script;
          print('   ✅ PRODUCT JSON-LD FOUND!');
          print('   Name: ${product['name']?.toString().substring(0, 60)}');
          final offers = product['offers'];
          if (offers is Map) {
            print('   Price: ${offers['price']} ${offers['priceCurrency']}');
          } else if (offers is List && offers.isNotEmpty) {
            print('   Price (first offer): ${offers.first['price']} ${offers.first['priceCurrency']}');
          }
          print('   Image: ${product['image']?.toString().substring(0, 60)}');
        }
      } catch (e) {
        print('   Script[$i] parse error: $e');
      }
    }

    // Extract meta tags
    print('\n🏷️  Meta Tag Extraction:');
    final metaTags = await page.evaluate('''() => {
      const results = {};
      const priceAmount = document.querySelector('meta[property="product:price:amount"]');
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const twitterTitle = document.querySelector('meta[name="twitter:title"]');
      
      if (priceAmount) results['product:price:amount'] = priceAmount.content;
      if (ogTitle) results['og:title'] = ogTitle.content;
      if (ogImage) results['og:image'] = ogImage.content;
      if (twitterTitle) results['twitter:title'] = twitterTitle.content;
      
      return results;
    }''');

    metaTags.forEach((key, value) {
      if (value != null) {
        final displayValue = value.toString().length > 80 
            ? value.toString().substring(0, 80) 
            : value.toString();
        print('   ✅ $key: $displayValue');
      } else {
        print('   ❌ $key: NOT FOUND');
      }
    });

    // Extract itemprop
    print('\n📌 Itemprop Extraction:');
    final itempropPrice = await page.evaluate('''() => {
      const priceEl = document.querySelector('[itemprop="price"]');
      if (priceEl) {
        return priceEl.content || priceEl.textContent?.trim();
      }
      return null;
    }''');

    if (itempropPrice != null) {
      print('   ✅ [itemprop="price"]: $itempropPrice');
    } else {
      print('   ❌ [itemprop="price"]: NOT FOUND');
    }

    // Check for initial state patterns
    print('\n🔧 Initial State Check:');
    final stateCheck = await page.evaluate('''() => {
      const patterns = [
        '__PRODUCT_DETAIL_APP_INITIAL_STATE__',
        '__INITIAL_STATE__',
        'window.__STATE__',
        '__NEXT_DATA__',
        '__APP_INITIAL_STATE__',
        '__REDUX_STATE__',
        '__NUXT__'
      ];
      const results = {};
      patterns.forEach(pattern => {
        if (window[pattern]) {
          results[pattern] = 'FOUND';
        } else {
          results[pattern] = 'NOT FOUND';
        }
      });
      return results;
    }''');

    stateCheck.forEach((key, value) {
      print('   $value: $key');
    });

    // Try to extract price from common DOM patterns
    print('\n💰 Price Extraction Attempts:');
    final priceExtraction = await page.evaluate('''() => {
      const results = {};
      
      // Try common price selectors
      const priceSelectors = [
        '.prc-dsc',
        '.prc-slg', 
        '.prc-org',
        '.prc-hp',
        '.price',
        '.product-price',
        '[data-testid="price"]',
        '.current-price',
        '.final-price',
        '.discounted-price',
        '.selling-price',
        '.original-price'
      ];
      
      priceSelectors.forEach(selector => {
        const el = document.querySelector(selector);
        if (el) {
          results[selector] = el.textContent?.trim();
        }
      });
      
      // Try to find price in text content
      const bodyText = document.body.textContent || '';
      // Find any numbers that might be prices
      const numbers = bodyText.match(/\d+[.,]\d+/g);
      if (numbers && numbers.length > 0) {
        results['potential_prices'] = numbers.slice(0, 10); // First 10 matches
      }
      
      return results;
    }''');

    if (priceExtraction.isNotEmpty) {
      priceExtraction.forEach((key, value) {
        print('   ✅ $key: $value');
      });
    } else {
      print('   ❌ No price data found');
    }

    // Try to extract product name
    print('\n📦 Product Name Extraction:');
    final nameExtraction = await page.evaluate('''() => {
      const results = {};
      
      const nameSelectors = [
        'h1',
        'h2',
        '.product-title',
        '.product-name',
        '[data-testid="product-title"]',
        '.prc-nm',
        '.prc-hd',
        '.product-detail-title',
        '.detail-title'
      ];
      
      nameSelectors.forEach(selector => {
        const els = document.querySelectorAll(selector);
        if (els.length > 0) {
          results[selector] = Array.from(els).map(el => el.textContent?.trim()).join(', ');
        }
      });
      
      return results;
    }''');

    if (nameExtraction.isNotEmpty) {
      nameExtraction.forEach((key, value) {
        final displayValue = value.toString().length > 80 
            ? value.toString().substring(0, 80) + '...' 
            : value.toString();
        print('   ✅ $key: $displayValue');
      });
    } else {
      print('   ❌ No product name found');
    }

    // Take screenshot for debugging
    print('\n📸 Taking screenshot...');
    try {
      final screenshot = await page.screenshot();
      // Save screenshot to file
      print('   ✅ Screenshot captured (${screenshot.length} bytes)');
    } catch (e) {
      print('   ⚠️  Screenshot failed: $e');
    }

    await browser.close();
    print('\n✅ Test completed successfully');

  } catch (e) {
    print('❌ ERROR: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

void main() async {
  print('🚀 Advanced Puppeteer Web Scraper');
  print('Testing with headless Chrome for JavaScript execution and Cloudflare bypass');
  
  // Test URLs - Updated with potentially working URLs
  final tests = [
    ('Trendyol', 'https://www.trendyol.com/relax/bluetoothlu-uzaktan-kumandali-portatif-yurume-ve-kosu-bandi-rl-890-p-1061070593?merchantId=759017&itemNumber=1467538377&boutiqueId=61'),
    ('Hepsiburada', 'https://www.hepsiburada.com/arcelik-gurme-steamfry-7-lt-kapasiteli-az-yagli-fritoz-tekil-urun-cikarilabilir-hazne-ile-fr-9374-p-HBCV0000AU07R8?magaza=Gürolcan%20Dayanıklı%20Tüketim&utm_source=akakce&utm_medium=cpc&utm_campaign=sc%3Ahb-ecom.sr%3Aakakce.md%3Apricecomp&utm_content=agnm%3Ahb&wt_pc=akakce&adj_t=1fmpah5v_1fmqteof&adj_campaign=akakce&v=1.1.1'), // Updated URL
    ('N11', 'https://www.n11.com/urun/grundig-si-6050-buharli-utu-100720614?magaza=grundig-turkiye'),
  ];

  for (int i = 0; i < tests.length; i++) {
    final test = tests[i];
    final name = test.$1;
    final url = test.$2;
    
    print('\n📝 Test ${i + 1}/${tests.length}');
    
    await testSiteWithPuppeteer(name, url, headless: true);
    
    // Be polite with delays between tests
    if (i < tests.length - 1) {
      print('⏸️  Waiting 5 seconds before next test...');
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  print('\n\n${'=' * 60}');
  print('🏁 All tests completed');
  print('=' * 60);
}
