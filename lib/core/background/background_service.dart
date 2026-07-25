import 'package:workmanager/workmanager.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/data/datasources/local/product_local_datasource.dart';
import '../../features/products/data/scrapers/site_scraper_registry.dart';
import '../../features/products/data/scrapers/impl/trendyol_scraper.dart';
import '../../features/products/data/scrapers/impl/hepsiburada_scraper.dart';
import '../../features/products/data/scrapers/impl/n11_scraper.dart';
import '../../features/products/data/scrapers/impl/generic_html_scraper.dart';
import '../../features/products/data/scrapers/impl/lcw_scraper.dart';
import '../../features/products/data/scrapers/impl/nike_scraper.dart';
import '../../features/products/data/scrapers/impl/mavi_scraper.dart';
import '../../features/products/data/scrapers/impl/smart_fallback_scraper.dart';
import '../database/database.dart';
import '../notifications/notification_service.dart';
import 'package:uuid/uuid.dart';

class BackgroundService {
  static const String priceCheckTask = 'priceCheckTask';
  
  static void initializeWorkmanager() {
    Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void registerPeriodicTask({
    required Duration interval,
    Duration? initialDelay,
  }) {
    Workmanager().registerPeriodicTask(
      priceCheckTask,
      priceCheckTask,
      frequency: interval,
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  static void cancelAllTasks() {
    Workmanager().cancelAll();
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        if (task == priceCheckTask) {
          await _performPriceCheck();
          return Future.value(true);
        }
        return Future.value(false);
      } catch (e) {
        return Future.value(false);
      }
    });
  }

  static Future<void> _performPriceCheck() async {
    // This will be called from background isolate
    // We need to initialize the database and dependencies here
    
    final database = AppDatabase.create();
    
    // Initialize scrapers - exclude WebViewScraper as it requires Flutter UI
    final scrapers = [
      TrendyolScraper(),
      HepsiburadaScraper(),
      N11Scraper(),
      LcwScraper(),
      NikeScraper(),
      MaviScraper(),
      SmartFallbackScraper(),
      GenericHtmlScraper(),
      // WebViewScraper is excluded - doesn't work in background isolate
    ];
    
    final scraperRegistry = SiteScraperRegistry(scrapers);
    
    // Create repository
    final repository = ProductRepositoryImpl(
      localDataSource: ProductLocalDataSource(database),
      scraperRegistry: scraperRegistry,
      uuid: const Uuid(),
    );
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Get all active products
    final products = await repository.getActiveProducts();
    
    int successCount = 0;
    int failureCount = 0;
    
    // Check each product
    for (final product in products) {
      try {
        final updatedProduct = await repository.updateProductPrice(product.id);
        successCount++;
        
        // Check if price dropped
        if (updatedProduct.currentPrice < updatedProduct.initialPrice) {
          final priceDropPercent = updatedProduct.priceChangePercent;
          
          // Check if notification should be sent
          final shouldNotify = _shouldNotifyForPriceDrop(
            product: updatedProduct,
            priceDropPercent: priceDropPercent,
          );
          
          if (shouldNotify) {
            await notificationService.showPriceDropNotification(
              productName: updatedProduct.name,
              oldPrice: updatedProduct.initialPrice,
              newPrice: updatedProduct.currentPrice,
              priceDropPercent: priceDropPercent,
              productId: updatedProduct.id,
            );
          }
          
          // Check if target price reached
          if (updatedProduct.targetPrice != null && 
              updatedProduct.currentPrice <= updatedProduct.targetPrice!) {
            await notificationService.showTargetPriceNotification(
              productName: updatedProduct.name,
              targetPrice: updatedProduct.targetPrice!,
              currentPrice: updatedProduct.currentPrice,
              productId: updatedProduct.id,
            );
          }
        }
      } catch (e) {
        failureCount++;
        // Log error but continue with other products
        // ignore: avoid_print
        print('Error checking product ${product.id}: $e');
      }
    }
    
    // Log summary
    // ignore: avoid_print
    print('Price check completed: $successCount succeeded, $failureCount failed');
    
    await database.close();
  }

  static bool _shouldNotifyForPriceDrop({
    required dynamic product,
    required double priceDropPercent,
  }) {
    // Check product-specific threshold
    if (product.notifyThresholdPercent != null) {
      return priceDropPercent.abs() >= product.notifyThresholdPercent!;
    }
    
    // Default threshold: 5% price drop
    return priceDropPercent.abs() >= 5.0;
  }
}


