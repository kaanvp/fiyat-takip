// Bulk scraper test — run with: dart run test_scrapers_bulk.dart
// Tests ALL URLs with GenericHtmlScraper logic and reports results

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

String bold(String text) => '\x1B[1m$text\x1B[0m';
String green(String text) => '\x1B[32m$text\x1B[0m';
String red(String text) => '\x1B[31m$text\x1B[0m';
String yellow(String text) => '\x1B[33m$text\x1B[0m';
String dim(String text) => '\x1B[2m$text\x1B[0m';

final client = http.Client();

final urls = [
  'https://www.amazon.com.tr/Xbox-Wireless-Controller-Microsoft-Garantili/dp/B0F2NCQYTX',
  'https://www.trendyol.com/xiaomi/power-bank-usb-ve-usb-c-portu-ve-usb-c-entegre-kablo-20000mah-33w-bhr8851gl-tan-p-877002459',
  'https://www.hepsiburada.com/samsung-vc07r302mvp-tr-toz-torbasiz-elektrikli-supurge-mor-p-HBV00000NXQ9F',
  'https://www.n11.com/urun/manyetik-fan-sarj-edilebilir-3-kademeli-5800-rpm-miknatisli-magsafe-telefon-vantilatoru-x6104-93104884',
  'https://www.ciceksepeti.com/hizli-kargo-isme-ozel-haki-deri-cuzdan-ve-anahtarlik-hediye-seti-kcm33495360',
  'https://www.teknosa.com/remington-s8598-keratin-protect-sac-duzlestirici-p-120203370',
  'https://www.mediamarkt.com.tr/tr/product/_apple-11-inc-ipad-11nesil-a16-wi-fi-128-gb-tablet-gumus-md3y4tua-1245605.html',
  'https://www.vatanbilgisayar.com/samsung-qe-55q7f5-55inc-138-cm-4k-uhd-smart-qled-tv-uydu-alicili.html',
  'https://www.koctas.com.tr/good-home-40-cm-kumandali-ayakli-vantilator-siyah/p/2000035184',
  'https://www.ikea.com.tr/urun/annons-cam-paslanmaz-celik-celik-tencere-seti-90207402',
  'https://www.migros.com.tr/namet-dana-doner-250-g-p-1853cbf',
  'https://www.carrefoursa.com/nescafe-gold-ekonomik-paket-100-gr-poset-p-30090954',
  'https://www.a101.com.tr/elektronik/philips-marathon-ultimate-xb9155-07-toz-torbasiz-elektrikli-supurge_p-26049525',
  'https://www.sokmarket.com.tr/anadolu-ciftligi-m-yumurta-30-lu-53-63-g-p-4948',
  'https://www.pttavm.com/huawei-freebuds-5-seramik-beyaz-p-544377349',
  'https://www.boyner.com.tr/calvin-klein-2li-siyah-beyaz-erkek-t-shirt-p-15825212',
  'https://www.lcw.com/regular-fit-gabardin-erkek-pantolon-lacivert-o-5317536',
  'https://www.defacto.com.tr/regular-fit-pamuklu-kisa-kollu-gomlek-3256694',
  'https://www.koton.com/regular-fit-devrik-yaka-pamuk-keten-karisimli-kisa-kollu-gomlek-antrasit-4186002/',
  'https://www.zara.com/tr/tr/vatkali-crop-blazer-p02796334.html',
  'https://www2.hm.com/tr_tr/productpage.1345281001.html',
  'https://shop.mango.com/tr/tr/p/erkek/gomlek/cizgili/100-pamuklu-cizgili-gomlek/27091286',
  'https://www.pullandbear.com/tr/denim-bermuda-sort-l03666502',
  'https://www.bershka.com/tr/zimba-detayli-fermuarli-kapusonlu-sweatshirt-c0p233488859.html',
  'https://www.nike.com/tr/t/sb-zoom-tennis-classic-kaykay-ayakkabisi-OBGThu7r/HF7386-004',
  'https://www.adidas.com.tr/tr/samba-og-ayakkabi/IG9030.html',
  'https://tr.puma.com/pounce-lite-kosu-ayakkabisi-310778-05.html',
  'https://www.ebay.com/p/10060675185',
  'https://www.walmart.com/ip/Oura-Ring-4-Black-Size-8/17927471359',
  'https://www.flo.com.tr/urun/nike-nike-cosmic-runner-siyah-unisex-kosu-ayakkabisi-102237358',
  'https://www.modanisa.com/orgu-detayli-triko-tesettur-elbise--haki--refka.html',
  'https://www.pazarama.com/turk-kahvesi-100-gr-paket-p-8690627021209',
  'https://www.dr.com.tr/kitap/mudurun-ucan-perugu/caner-sarioglu/urunno=0002228789001',
  'https://www.kitapyurdu.com/kitap/bas-belalari-ve-basyapitlari/755749.html',
  'https://www.gratis.com/erkek-sampuan/clear-men-kepege-karsi-etkili-sampuan-p-10335309',
  'https://www.watsons.com.tr/the-purest-solutions-yag-kontrol-nemlkrem-50-ml/p/BP_1460116',
  'https://www.rossmann.com.tr/cilt-bakimi/isana-hydro-booster-nemlendirici-jel-krem-p-sr17120204',
  'https://www.atasunoptik.com.tr/inesta-ao9027-06-4723150-unisex-gunes-gozlukleri_80186',
  'https://www.mavi.com/stretch-v-yaka-yesil-basic-tisort/p/061748-25752',
  'https://derimod.com.tr/products/beatrix-kadin-siyah-gomlek-yaka-kisa-deri-ceket-25wge56131m',
  'https://www.madamecoco.com/salentino-kizartma-tenceresi-kirmizi-22-cm-tncr0000000071-375/',
  'https://www.englishhome.com/winnie-porselen-4-parca-2-kisilik-kahve-fincan-takimi-90-ml-yesil-turuncu-26784',
  'https://www.karaca.com/urun/karaca-biodiamond-easy-clip-13-parca-tencere-seti',
  'https://www.bizimtoptan.com.tr/blade-cool-fresh-deodorant-150-ml',
  'https://www.temu.com/tr/24-cift-unisex-pamuklu-gunluk-terletmeyen-spor-corap-seti-g-604148519026663.html',
  'https://www.akakce.com/oyun-kolu/en-ucuz-sony-dualsense-beyaz-kablosuz-ps5-fiyati,1232989046.html',
  'https://www.cimri.com/monitor/en-ucuz-msi-mag-27c6pf-27-inc-180hz-0-5ms-curved-oyuncu-monitoru-fiyatlari,2389255338',
  'https://dolap.com/urun/diger-bej-diger-bebek-cocuk-gerecleri-az-kullanilmis-bugseakturk-458095738',
  'https://www.idefix.com/onvo-ovkc02-onvo-multi-dograyici-p-10950920',
  'https://www.farmasi.com.tr/farmasi/product-detail/dr-c-tuna-c-vitamini-serumu?pid=1002167',
];

int pass = 0, fail = 0, skipHttp = 0;

void main() async {
  print(bold('\n═══════════════════════════════════════════════'));
  print(bold('      TOPLU SCRAPING TESTİ — ${urls.length} URL'));
  print(bold('═══════════════════════════════════════════════\n'));

  for (int i = 0; i < urls.length; i++) {
    final url = urls[i];
    final uri = Uri.parse(url);
    final host = uri.host.replaceFirst('www.', '');
    print('${bold('${i + 1}')}/${urls.length} ${dim('[$host]')}');
    
    final siteType = _classifySite(host);
    await _testUrl(uri, host, siteType);
  }

  print(bold('\n═══════════════════════════════════════════════'));
  print(bold('      SONUÇ: $pass ✅  |  $fail ❌  |  $skipHttp ⏭️  HTTP-skipped'));
  print(bold('═══════════════════════════════════════════════\n'));

  client.close();
}

String _classifySite(String host) {
  if (host.contains('trendyol')) return 'Trendyol';
  if (host.contains('hepsiburada')) return 'Hepsiburada';
  if (host.contains('n11.com')) return 'N11';
  if (host.contains('amazon')) return 'Amazon';
  if (host.contains('ebay')) return 'eBay';
  if (host.contains('walmart')) return 'Walmart';
  if (host.contains('temu')) return 'Temu';
  if (host.contains('teknosa')) return 'Teknosa';
  if (host.contains('vatan')) return 'Vatan';
  if (host.contains('mediamarkt')) return 'MediaMarkt';
  if (host.contains('ciceksepeti')) return 'CicekSepeti';
  if (host.contains('akakce')) return 'Akakce';
  if (host.contains('cimri')) return 'Cimri';
  if (host.contains('dolap')) return 'Dolap';
  if (host.contains('pttavm')) return 'PttAVM';
  if (host.contains('pazarama')) return 'Pazarama';
  if (host.contains('koctas') || host.contains('koçtaş')) return 'Koctas';
  if (host.contains('ikea')) return 'IKEA';
  if (host.contains('migros')) return 'Migros';
  if (host.contains('carrefour')) return 'Carrefour';
  if (host.contains('a101')) return 'A101';
  if (host.contains('sokmarket') || host.contains('şok')) return 'Sok';
  if (host.contains('boyner')) return 'Boyner';
  if (host.contains('lcw') || host.contains('lcwaikiki')) return 'LCW';
  if (host.contains('defacto')) return 'Defacto';
  if (host.contains('koton')) return 'Koton';
  if (host.contains('zara')) return 'Zara';
  if (host.contains('hm.com')) return 'HM';
  if (host.contains('mango')) return 'Mango';
  if (host.contains('pullandbear')) return 'PullBear';
  if (host.contains('bershka')) return 'Bershka';
  if (host.contains('nike')) return 'Nike';
  if (host.contains('adidas')) return 'Adidas';
  if (host.contains('puma')) return 'Puma';
  if (host.contains('flo.com')) return 'Flo';
  if (host.contains('modanisa')) return 'Modanisa';
  if (host.contains('dr.com')) return 'DR';
  if (host.contains('kitapyurdu')) return 'KitapYurdu';
  if (host.contains('gratis')) return 'Gratis';
  if (host.contains('watsons')) return 'Watsons';
  if (host.contains('rossmann')) return 'Rossmann';
  if (host.contains('atasunoptik')) return 'Atasun';
  if (host.contains('mavi.com')) return 'Mavi';
  if (host.contains('derimod')) return 'Derimod';
  if (host.contains('madamecoco')) return 'MadameCoco';
  if (host.contains('englishhome')) return 'EnglishHome';
  if (host.contains('karaca')) return 'Karaca';
  if (host.contains('bizimtoptan')) return 'BizimToptan';
  if (host.contains('idefix')) return 'Idefix';
  if (host.contains('farmasi')) return 'Farmasi';
  return 'Genel';
}

Future<void> _testUrl(Uri uri, String host, String siteType) async {
  try {
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    };
    
    final response = await client.get(uri, headers: headers).timeout(Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      
      // Try to extract basic product info
      final name = _extractName(document);
      final price = _extractPrice(document);
      
      if (name != null && price != null) {
        print(green('✅  $name  |  $price'));
        pass++;
      } else {
        print(yellow('⚠️  HTML alındı ama ürün bilgisi bulunamadı'));
        fail++;
      }
    } else {
      print(red('❌  HTTP ${response.statusCode}'));
      fail++;
    }
  } catch (e) {
    print(red('❌  $e'));
    fail++;
  }
  
  // Delay between requests
  await Future.delayed(Duration(milliseconds: 500));
}

String? _extractName(html_dom.Document document) {
  final selectors = [
    'meta[property="og:title"]',
    'meta[name="twitter:title"]',
    'h1',
    '.product-name',
    '[itemprop="name"]',
  ];
  
  for (final selector in selectors) {
    final element = document.querySelector(selector);
    if (element != null) {
      final content = element.attributes['content'] ?? element.text.trim();
      if (content.isNotEmpty) return content;
    }
  }
  return null;
}

String? _extractPrice(html_dom.Document document) {
  final selectors = [
    'meta[property="product:price:amount"]',
    '[itemprop="price"]',
    '.price',
    '.product-price',
    '[class*="price"]',
  ];
  
  for (final selector in selectors) {
    final element = document.querySelector(selector);
    if (element != null) {
      final priceText = element.attributes['content'] ?? element.text.trim();
      if (priceText.isNotEmpty) return priceText;
    }
  }
  return null;
}
