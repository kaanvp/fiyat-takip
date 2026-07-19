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
import '../../features/products/data/scrapers/impl/generic_html_scraper.dart';
import '../../features/products/data/scrapers/impl/webview_scraper.dart';
import '../../features/products/data/scrapers/impl/puppeteer_scraper.dart';
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

// Scraper registry provider
final scraperRegistryProvider = Provider<SiteScraperRegistry>((ref) {
  final scrapers = [
    ref.watch(trendyolScraperProvider),
    ref.watch(hepsiburadaScraperProvider),
    ref.watch(n11ScraperProvider),
    ref.watch(genericHtmlScraperProvider),
    ref.watch(webviewScraperProvider), // WebView as fallback for JS-heavy sites
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
