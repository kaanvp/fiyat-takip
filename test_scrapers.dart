// Dart script to test scraping strategies on real sites
// Run with: dart run test_scrapers.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

// User Agent rotation for better bot detection bypass
final userAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
];

String getRandomUserAgent() {
  final random = Random();
  return userAgents[random.nextInt(userAgents.length)];
}

Map<String, String> getAdvancedHeaders({String? referer, String? host}) {
  final userAgent = getRandomUserAgent();
  final now = DateTime.now();
  
  return {
    'User-Agent': userAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Cache-Control': 'max-age=0',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Ch-Ua': '"Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"Windows"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': referer != null ? 'same-origin' : 'none',
    'Sec-Fetch-User': '?1',
    'DNT': '1',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Sec-Ch-Ua-Full-Version': '"126.0.6478.126"',
    'Sec-Ch-Ua-Full-Version-List': '"Not/A)Brand";v="8.0.0.0", "Chromium";v="126.0.6478.126", "Google Chrome";v="126.0.6478.126"',
    'Priority': 'u=0, i',
    if (referer != null) 'Referer': referer,
    if (host != null) 'Host': host,
  };
}

Future<void> testSite(String siteName, String url, {Map<String, String>? extraHeaders}) async {
  print('\n${'=' * 60}');
  print('🔍 Testing: $siteName');
  print('URL: $url');
  print('=' * 60);

  try {
    final client = http.Client();
    final uri = Uri.parse(url);
    final host = uri.host;
    
    // Step 1: First visit the homepage to establish session
    print('\n🌐 Step 1: Visiting homepage for session establishment...');
    final homepageUrl = 'https://$host';
    final homepageHeaders = getAdvancedHeaders(host: host);
    
    try {
      final homepageResponse = await client.get(Uri.parse(homepageUrl), headers: homepageHeaders)
          .timeout(const Duration(seconds: 15));
      print('   Homepage status: ${homepageResponse.statusCode}');
      
      // Extract cookies from homepage response
      final cookies = homepageResponse.headers['set-cookie'];
      if (cookies != null) {
        print('   ✅ Cookies received from homepage');
      }
      
      // Add delay to simulate human behavior
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      print('   ⚠️  Homepage visit failed: $e');
    }

    // Step 2: Visit the actual product page
    print('\n🛒 Step 2: Visiting product page...');
    final productHeaders = getAdvancedHeaders(referer: homepageUrl, host: host);
    final allHeaders = {...productHeaders, ...?extraHeaders};
    
    print('   User-Agent: ${allHeaders['User-Agent']?.substring(0, 50)}...');
    
    final response = await client.get(uri, headers: allHeaders)
        .timeout(const Duration(seconds: 20));

    print('📊 HTTP Status: ${response.statusCode}');
    print('📦 Response size: ${response.body.length} bytes');

    if (response.statusCode != 200) {
      print('❌ FAILED: Non-200 status code');
      print('   Response headers: ${response.headers.entries.take(5).toList()}');
      
      // Try to understand the error
      if (response.body.isNotEmpty) {
        print('   Response body preview: ${response.body.substring(0, 200)}...');
      }
      
      client.close();
      return;
    }

    final body = response.body;
    final document = html_parser.parse(body);

    // 1. Check JSON-LD
    print('\n📋 JSON-LD Check:');
    final jsonLdScripts = document.querySelectorAll('script[type="application/ld+json"]');
    print('   Found ${jsonLdScripts.length} JSON-LD scripts');
    for (int i = 0; i < jsonLdScripts.length; i++) {
      try {
        final content = jsonLdScripts[i].innerHtml.trim();
        final decoded = jsonDecode(content);
        final type = decoded['@type'] ?? (decoded is List ? decoded.map((e) => e['@type']).toList() : 'unknown');
        print('   Script[$i] @type: $type');
        
        bool isProduct = false;
        if (decoded is Map && decoded['@type'] == 'Product') isProduct = true;
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map && item['@type'] == 'Product') { isProduct = true; break; }
          }
        }
        
        if (isProduct) {
          final product = decoded is List 
              ? decoded.firstWhere((e) => e['@type'] == 'Product', orElse: () => {}) 
              : decoded;
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

    // 2. Check Initial State
    print('\n🔧 Initial State Check:');
    final initialStatePatterns = [
      '__PRODUCT_DETAIL_APP_INITIAL_STATE__',
      '__INITIAL_STATE__',
      'window.__STATE__',
      '__NEXT_DATA__',
    ];
    for (final pattern in initialStatePatterns) {
      if (body.contains(pattern)) {
        print('   ✅ Found: $pattern');
      } else {
        print('   ❌ Not found: $pattern');
      }
    }

    // 3. Check meta tags
    print('\n🏷️  Meta Tag Check:');
    final metaChecks = [
      ('product:price:amount', 'meta[property="product:price:amount"]'),
      ('og:title', 'meta[property="og:title"]'),
      ('og:image', 'meta[property="og:image"]'),
      ('twitter:title', 'meta[name="twitter:title"]'),
    ];
    for (final (name, selector) in metaChecks) {
      final el = document.querySelector(selector);
      if (el != null) {
        final val = el.attributes['content'] ?? '';
        print('   ✅ $name: ${val.substring(0, val.length > 80 ? 80 : val.length)}');
      } else {
        print('   ❌ $name: NOT FOUND');
      }
    }

    // 4. Check itemprop
    print('\n📌 Itemprop Check:');
    final itempropEl = document.querySelector('[itemprop="price"]');
    if (itempropEl != null) {
      print('   ✅ [itemprop="price"] content: ${itempropEl.attributes['content'] ?? itempropEl.text.trim()}');
    } else {
      print('   ❌ [itemprop="price"] NOT FOUND');
    }
    
    client.close();
    print('\n✅ Site test completed');
  } catch (e) {
    print('❌ ERROR: $e');
  }
}

void main() async {
  print('🚀 Advanced Web Scraper Test');
  print('Testing with user agent rotation, session management, and realistic delays');
  
  // Test URLs - güncel çalışan URL'ler
  final tests = [
    ('Trendyol', 'https://www.trendyol.com/relax/bluetoothlu-uzaktan-kumandali-portatif-yurume-ve-kosu-bandi-rl-890-p-1061070593?merchantId=759017&itemNumber=1467538377&boutiqueId=61'),
    ('Hepsiburada', 'https://www.hepsiburada.com/arcelik-gurme-steamfry-7-lt-kapasiteli-az-yagli-fritoz-tekil-urun-cikarilabilir-hazne-ile-fr-9374-p-HBCV0000AU07R8?magaza=Gürolcan%20Dayanıklı%20Tüketim&utm_source=akakce&utm_medium=cpc&utm_campaign=sc%3Ahb-ecom.sr%3Aakakce.md%3Apricecomp&utm_content=agnm%3Ahb&wt_pc=akakce&adj_t=1fmpah5v_1fmqteof&adj_campaign=akakce&v=1.1.1'),
    ('N11', 'https://www.n11.com/urun/grundig-si-6050-buharli-utu-100720614?magaza=grundig-turkiye'),
  ];

  for (int i = 0; i < tests.length; i++) {
    final test = tests[i];
    final name = test.$1;
    final url = test.$2;
    
    print('\n📝 Test ${i + 1}/${tests.length}');
    
    await testSite(name, url);
    
    // Be polite with random delays between requests
    if (i < tests.length - 1) {
      final delay = Duration(milliseconds: 2000 + Random().nextInt(3000));
      print('⏸️  Waiting ${delay.inSeconds} seconds before next request...');
      await Future.delayed(delay);
    }
  }

  print('\n\n${'=' * 60}');
  print('🏁 All tests completed');
  print('=' * 60);
}
