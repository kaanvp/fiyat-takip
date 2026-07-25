import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../background/background_service.dart';
import '../notifications/notification_service.dart';
import '../../features/products/data/datasources/local/product_local_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/data/scrapers/site_scraper_registry.dart';
import '../../features/products/data/scrapers/impl/trendyol_scraper.dart';
import '../../features/products/data/scrapers/impl/hepsiburada_scraper.dart';
import '../../features/products/data/scrapers/impl/n11_scraper.dart';
import '../../features/products/data/scrapers/impl/nike_scraper.dart';
import '../../features/products/data/scrapers/impl/mavi_scraper.dart';
import '../../features/products/data/scrapers/impl/smart_fallback_scraper.dart';
import '../../features/products/data/scrapers/impl/generic_html_scraper.dart';
import '../../features/products/data/scrapers/impl/webview_scraper.dart';
import '../../features/products/data/scrapers/impl/puppeteer_scraper.dart';
import '../../features/products/data/scrapers/impl/mediamarkt_scraper.dart';
import '../../features/products/data/scrapers/impl/migros_scraper.dart';
import '../../features/products/data/scrapers/impl/sokmarket_scraper.dart';
import '../../features/products/data/scrapers/impl/boyner_scraper.dart';
import '../../features/products/data/scrapers/impl/gratis_scraper.dart';
import '../../features/products/data/scrapers/impl/watsons_scraper.dart';
import '../../features/products/data/scrapers/impl/rossmann_scraper.dart';
import '../../features/products/data/scrapers/impl/flo_scraper.dart';
import '../../features/products/data/scrapers/impl/pazarama_scraper.dart';
import '../../features/products/data/scrapers/impl/zara_scraper.dart';
import '../../features/products/data/scrapers/impl/hm_scraper.dart';
import '../../features/products/data/scrapers/impl/pullandbear_scraper.dart';
import '../../features/products/data/scrapers/impl/bershka_scraper.dart';
import '../../features/products/data/scrapers/impl/lcw_scraper.dart';
import '../../features/products/domain/repositories/product_repository.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.create();
});

// UUID provider
final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

// Local datasource provider
final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return ProductLocalDataSource(database);
});

// Scrapers providers
final trendyolScraperProvider = Provider<TrendyolScraper>((ref) {
  return TrendyolScraper();
});

final hepsiburadaScraperProvider = Provider<HepsiburadaScraper>((ref) {
  return HepsiburadaScraper();
});

final n11ScraperProvider = Provider<N11Scraper>((ref) {
  return N11Scraper();
});

final genericHtmlScraperProvider = Provider<GenericHtmlScraper>((ref) {
  return GenericHtmlScraper();
});

final webviewScraperProvider = Provider<WebViewScraper>((ref) {
  return WebViewScraper();
});

final puppeteerScraperProvider = Provider<PuppeteerScraper>((ref) {
  return PuppeteerScraper();
});

final mediamarktScraperProvider = Provider<MediaMarktScraper>((ref) {
  return MediaMarktScraper();
});

final migrosScraperProvider = Provider<MigrosScraper>((ref) {
  return MigrosScraper();
});

final sokmarketScraperProvider = Provider<SokMarketScraper>((ref) {
  return SokMarketScraper();
});

final boynerScraperProvider = Provider<BoynerScraper>((ref) {
  return BoynerScraper();
});

final gratisScraperProvider = Provider<GratisScraper>((ref) {
  return GratisScraper();
});

final watsonsScraperProvider = Provider<WatsonsScraper>((ref) {
  return WatsonsScraper();
});

final rossmannScraperProvider = Provider<RossmannScraper>((ref) {
  return RossmannScraper();
});

final floScraperProvider = Provider<FloScraper>((ref) {
  return FloScraper();
});

final pazaramaScraperProvider = Provider<PazaramaScraper>((ref) {
  return PazaramaScraper();
});

final zaraScraperProvider = Provider<ZaraScraper>((ref) {
  return ZaraScraper();
});

final hmScraperProvider = Provider<HmScraper>((ref) {
  return HmScraper();
});

final pullAndBearScraperProvider = Provider<PullAndBearScraper>((ref) {
  return PullAndBearScraper();
});

final bershkaScraperProvider = Provider<BershkaScraper>((ref) {
  return BershkaScraper();
});

final lcwScraperProvider = Provider<LcwScraper>((ref) {
  return LcwScraper();
});

final nikeScraperProvider = Provider<NikeScraper>((ref) {
  return NikeScraper();
});

final maviScraperProvider = Provider<MaviScraper>((ref) {
  return MaviScraper();
});

final smartFallbackScraperProvider = Provider<SmartFallbackScraper>((ref) {
  return SmartFallbackScraper();
});

// Scraper registry provider
final scraperRegistryProvider = Provider<SiteScraperRegistry>((ref) {
  final scrapers = [
    ref.watch(trendyolScraperProvider),
    ref.watch(hepsiburadaScraperProvider),
    ref.watch(n11ScraperProvider),
    ref.watch(mediamarktScraperProvider),
    ref.watch(migrosScraperProvider),
    ref.watch(sokmarketScraperProvider),
    ref.watch(boynerScraperProvider),
    ref.watch(gratisScraperProvider),
    ref.watch(watsonsScraperProvider),
    ref.watch(rossmannScraperProvider),
    ref.watch(floScraperProvider),
    ref.watch(pazaramaScraperProvider),
    ref.watch(zaraScraperProvider),
    ref.watch(hmScraperProvider),
    ref.watch(pullAndBearScraperProvider),
    ref.watch(bershkaScraperProvider),
    ref.watch(lcwScraperProvider),
    ref.watch(nikeScraperProvider),
    ref.watch(maviScraperProvider),
    ref.watch(smartFallbackScraperProvider),
    ref.watch(genericHtmlScraperProvider),
    ref.watch(webviewScraperProvider),
  ];
  return SiteScraperRegistry(scrapers);
});

// Product repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final localDataSource = ref.watch(productLocalDataSourceProvider);
  final scraperRegistry = ref.watch(scraperRegistryProvider);
  final uuid = ref.watch(uuidProvider);
  
  return ProductRepositoryImpl(
    localDataSource: localDataSource,
    scraperRegistry: scraperRegistry,
    uuid: uuid,
  );
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Background service provider
final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return BackgroundService();
});

// Initialization provider - this will be used to initialize services on app startup
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize notification service
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.initialize();
  
  // Initialize background service
  BackgroundService.initializeWorkmanager();
  
  // Note: Background task registration should be done based on user settings
  // This can be called from settings screen when user enables background checks
});
