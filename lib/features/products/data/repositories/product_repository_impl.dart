import '../../domain/entities/product.dart' as domain;
import '../../domain/entities/price_history_entry.dart' as domain;
import '../../domain/entities/product_group.dart' as domain;
import '../../domain/entities/check_status.dart' as domain;
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../scrapers/scraper_interface.dart';
import '../scrapers/site_scraper_registry.dart';
import '../../../../core/database/database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;
  final SiteScraperRegistry scraperRegistry;
  final Uuid uuid;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.scraperRegistry,
    required this.uuid,
  });

  @override
  Future<List<domain.Product>> getAllProducts() async {
    final products = await localDataSource.getAllProducts();
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<List<domain.Product>> getActiveProducts() async {
    final products = await localDataSource.getActiveProducts();
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<List<domain.Product>> getArchivedProducts() async {
    final products = await localDataSource.getArchivedProducts();
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<domain.Product?> getProductById(String id) async {
    final product = await localDataSource.getProductById(id);
    return product != null ? _toProductEntity(product) : null;
  }

  @override
  Future<domain.Product> addProduct(domain.Product product) async {
    final productCompanion = _toProductCompanion(product);
    await localDataSource.addProduct(productCompanion);
    return product;
  }

  @override
  Future<domain.Product> updateProduct(domain.Product product) async {
    final productCompanion = _toProductCompanion(product);
    await localDataSource.updateProduct(productCompanion);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await localDataSource.deleteProduct(id);
  }

  @override
  Future<void> archiveProduct(String id) async {
    await localDataSource.archiveProduct(id);
  }

  @override
  Future<void> unarchiveProduct(String id) async {
    await localDataSource.unarchiveProduct(id);
  }

  @override
  Future<List<domain.PriceHistoryEntry>> getPriceHistory(String productId) async {
    final entries = await localDataSource.getPriceHistory(productId);
    return entries.map(_toPriceHistoryEntryEntity).toList();
  }

  @override
  Future<domain.PriceHistoryEntry> addPriceHistoryEntry(domain.PriceHistoryEntry entry) async {
    final entryCompanion = _toPriceHistoryEntryCompanion(entry);
    await localDataSource.addPriceHistoryEntry(entryCompanion);
    return entry;
  }

  @override
  Future<void> deletePriceHistory(String productId) async {
    await localDataSource.deletePriceHistory(productId);
  }

  @override
  Future<List<domain.ProductGroup>> getAllGroups() async {
    final groups = await localDataSource.getAllGroups();
    return groups.map(_toProductGroupEntity).toList();
  }

  @override
  Future<domain.ProductGroup?> getGroupById(String id) async {
    final group = await localDataSource.getGroupById(id);
    return group != null ? _toProductGroupEntity(group) : null;
  }

  @override
  Future<domain.ProductGroup> createGroup(domain.ProductGroup group) async {
    final groupCompanion = _toProductGroupCompanion(group);
    await localDataSource.createGroup(groupCompanion);
    return group;
  }

  @override
  Future<domain.ProductGroup> updateGroup(domain.ProductGroup group) async {
    final groupCompanion = _toProductGroupCompanion(group);
    await localDataSource.updateGroup(groupCompanion);
    return group;
  }

  @override
  Future<void> deleteGroup(String id) async {
    await localDataSource.deleteGroup(id);
  }

  @override
  Future<List<domain.Product>> getProductsByGroup(String groupId) async {
    final products = await localDataSource.getProductsByGroup(groupId);
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<List<domain.Product>> searchProducts(String query) async {
    final products = await localDataSource.searchProducts(query);
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<List<domain.Product>> getProductsByTag(String tag) async {
    final products = await localDataSource.getProductsByTag(tag);
    return products.map(_toProductEntity).toList();
  }

  @override
  Future<int> getTotalProductCount() async {
    return await localDataSource.getTotalProductCount();
  }

  @override
  Future<int> getActiveProductCount() async {
    return await localDataSource.getActiveProductCount();
  }

  @override
  Future<int> getPriceDropCount() async {
    return await localDataSource.getPriceDropCount();
  }

  @override
  Future<void> refreshProductPrice(String productId) async {
    await updateProductPrice(productId);
  }

  @override
  Future<List<domain.Product>> getStaleProducts(Duration threshold) async {
    final products = await getActiveProducts();
    final thresholdDate = DateTime.now().subtract(threshold);
    
    return products.where(
      (product) => 
        product.lastCheckedAt == null || 
        product.lastCheckedAt!.isBefore(thresholdDate),
    ).toList();
  }

  @override
  Future<domain.Product> addProductFromUrl(String productUrl, {double? targetPrice, String? notes}) async {
    final uri = Uri.parse(productUrl);
    
    // Try multiple scrapers in hierarchy
    final scrapers = _getScrapersInPriorityOrder(uri);
    
    if (scrapers.isEmpty) {
      throw Exception('No scraper available for this URL');
    }

    ScraperException? lastError;
    
    for (final scraper in scrapers) {
      try {
        print('Trying scraper: ${scraper.displayName}');
        final scrapedProduct = await scraper.scrape(uri);
        
        final product = domain.Product(
          id: uuid.v4(),
          name: scrapedProduct.name,
          imageUrl: scrapedProduct.imageUrl,
          productUrl: productUrl,
          siteHost: uri.host,
          siteDisplayName: _extractSiteDisplayName(uri, scraper),
          initialPrice: scrapedProduct.price,
          currentPrice: scrapedProduct.price,
          currency: scrapedProduct.currency,
          addedAt: DateTime.now(),
          lastCheckedAt: DateTime.now(),
          lastCheckStatus: domain.CheckStatus.ok,
          isArchived: false,
          targetPrice: targetPrice,
          notes: notes,
          tags: [],
        );

        return await addProduct(product);
      } on ScraperException catch (e) {
        print('Scraper ${scraper.displayName} failed: $e');
        lastError = e;
        // Try next scraper
        continue;
      }
    }
    
    // All scrapers failed
    throw lastError ?? Exception('All scrapers failed');
  }
  
  List<ProductScraper> _getScrapersInPriorityOrder(Uri uri) {
    final allScrapers = scraperRegistry.allScrapers;
    final prioritizedScrapers = <ProductScraper>[];
    
    final genericNames = {
      'Generic HTML Scraper',
      'WebView Scraper',
    };
    
    // 1. Site-specific scrapers (Trendyol, Hepsiburada, N11)
    for (final scraper in allScrapers) {
      if (scraper.canHandle(uri) && !genericNames.contains(scraper.displayName)) {
        prioritizedScrapers.add(scraper);
      }
    }
    
    // 2. Generic HTML Scraper (lightweight fallback)
    final generic = scraperRegistry.getScraperByDisplayName('Generic HTML Scraper');
    if (generic != null) {
      prioritizedScrapers.add(generic);
    }
    
    // 3. WebView Scraper (last resort, uses JS rendering)
    final webview = scraperRegistry.getScraperByDisplayName('WebView Scraper');
    if (webview != null) {
      prioritizedScrapers.add(webview);
    }
    
    return prioritizedScrapers;
  }

  /// Extracts a user-friendly site display name from the URL.
  /// For site-specific scrapers (Trendyol, Hepsiburada, N11), uses the scraper name.
  /// For generic scrapers, extracts a readable name from the domain.
  String _extractSiteDisplayName(Uri uri, ProductScraper scraper) {
    // Site-specific scrapers already have good display names
    if (scraper.displayName != 'Puppeteer (Headless Chrome)' &&
        scraper.displayName != 'Generic HTML Scraper' &&
        scraper.displayName != 'WebView Scraper') {
      return scraper.displayName;
    }

    // Extract main domain name (handles subdomains like "ty.trendyol.com")
    return domain.Product.extractDomainName(uri.host);
  }

  Future<domain.Product> updateProductPrice(String productId) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }

    final uri = Uri.parse(product.productUrl);
    final scrapers = _getScrapersInPriorityOrder(uri);
    
    if (scrapers.isEmpty) {
      throw Exception('No scraper available for this URL');
    }

    ScraperException? lastError;
    
    for (final scraper in scrapers) {
      try {
        print('Updating price with scraper: ${scraper.displayName}');
        final scrapedProduct = await scraper.scrape(uri);
        
        // Add price history entry if price changed
        if (scrapedProduct.price != product.currentPrice) {
          final historyEntry = domain.PriceHistoryEntry(
            id: uuid.v4(),
            productId: productId,
            price: scrapedProduct.price,
            checkedAt: DateTime.now(),
          );
          await addPriceHistoryEntry(historyEntry);
        }

        // Update product
        final updatedProduct = domain.Product(
          id: product.id,
          name: scrapedProduct.name,
          imageUrl: scrapedProduct.imageUrl ?? product.imageUrl,
          productUrl: product.productUrl,
          siteHost: product.siteHost,
          siteDisplayName: _extractSiteDisplayName(uri, scraper),
          initialPrice: product.initialPrice,
          currentPrice: scrapedProduct.price,
          currency: scrapedProduct.currency,
          targetPrice: product.targetPrice,
          addedAt: product.addedAt,
          lastCheckedAt: DateTime.now(),
          lastCheckStatus: domain.CheckStatus.ok,
          isArchived: product.isArchived,
          notes: product.notes,
          tags: product.tags,
          notifyThresholdPercent: product.notifyThresholdPercent,
          groupId: product.groupId,
        );

        return await updateProduct(updatedProduct);
      } on ScraperException catch (e) {
        print('Scraper ${scraper.displayName} failed for price update: $e');
        lastError = e;
        // Try next scraper
        continue;
      }
    }
    
    // All scrapers failed - update with error status
    final updatedProduct = domain.Product(
      id: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      productUrl: product.productUrl,
      siteHost: product.siteHost,
      siteDisplayName: product.siteDisplayName,
      initialPrice: product.initialPrice,
      currentPrice: product.currentPrice,
      currency: product.currency,
      targetPrice: product.targetPrice,
      addedAt: product.addedAt,
      lastCheckedAt: DateTime.now(),
      lastCheckStatus: _mapScraperErrorToCheckStatus(lastError?.errorType ?? ScraperErrorType.unknown),
      isArchived: product.isArchived,
      notes: product.notes,
      tags: product.tags,
      notifyThresholdPercent: product.notifyThresholdPercent,
      groupId: product.groupId,
    );

    return await updateProduct(updatedProduct);
  }

  domain.CheckStatus _mapScraperErrorToCheckStatus(ScraperErrorType errorType) {
    switch (errorType) {
      case ScraperErrorType.networkError:
        return domain.CheckStatus.networkError;
      case ScraperErrorType.parseError:
        return domain.CheckStatus.parseError;
      case ScraperErrorType.notFound:
        return domain.CheckStatus.notFound;
      case ScraperErrorType.blocked:
        return domain.CheckStatus.networkError; // Map blocked to networkError
      case ScraperErrorType.jsRequired:
        return domain.CheckStatus.parseError; // Map jsRequired to parseError
      case ScraperErrorType.unknown:
        return domain.CheckStatus.networkError; // Map unknown to networkError
    }
  }

  // Helper methods for entity conversion
  domain.Product _toProductEntity(Product product) {
    return domain.Product(
      id: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      productUrl: product.productUrl,
      siteHost: product.siteHost,
      siteDisplayName: product.siteDisplayName,
      initialPrice: product.initialPrice,
      currentPrice: product.currentPrice,
      currency: product.currency,
      targetPrice: product.targetPrice,
      addedAt: product.addedAt,
      lastCheckedAt: product.lastCheckedAt,
      lastCheckStatus: _convertCheckStatus(product.lastCheckStatus),
      isArchived: product.isArchived,
      notes: product.notes,
      tags: product.tags,
      notifyThresholdPercent: product.notifyThresholdPercent,
      groupId: product.groupId,
    );
  }

  domain.CheckStatus _convertCheckStatus(CheckStatus status) {
    switch (status) {
      case CheckStatus.ok:
        return domain.CheckStatus.ok;
      case CheckStatus.parseError:
        return domain.CheckStatus.parseError;
      case CheckStatus.networkError:
        return domain.CheckStatus.networkError;
      case CheckStatus.notFound:
        return domain.CheckStatus.notFound;
    }
  }

  CheckStatus _convertToDbCheckStatus(domain.CheckStatus status) {
    switch (status) {
      case domain.CheckStatus.ok:
        return CheckStatus.ok;
      case domain.CheckStatus.parseError:
        return CheckStatus.parseError;
      case domain.CheckStatus.networkError:
        return CheckStatus.networkError;
      case domain.CheckStatus.notFound:
        return CheckStatus.notFound;
    }
  }

  ProductsCompanion _toProductCompanion(domain.Product product) {
    return ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      imageUrl: Value(product.imageUrl),
      productUrl: Value(product.productUrl),
      siteHost: Value(product.siteHost),
      siteDisplayName: Value(product.siteDisplayName),
      initialPrice: Value(product.initialPrice),
      currentPrice: Value(product.currentPrice),
      currency: Value(product.currency),
      targetPrice: Value(product.targetPrice),
      addedAt: Value(product.addedAt),
      lastCheckedAt: Value(product.lastCheckedAt),
      lastCheckStatus: Value(_convertToDbCheckStatus(product.lastCheckStatus)),
      isArchived: Value(product.isArchived),
      notes: Value(product.notes),
      tags: Value(product.tags),
      notifyThresholdPercent: Value(product.notifyThresholdPercent),
      groupId: Value(product.groupId),
    );
  }

  domain.PriceHistoryEntry _toPriceHistoryEntryEntity(PriceHistoryEntry entry) {
    return domain.PriceHistoryEntry(
      id: entry.id,
      productId: entry.productId,
      price: entry.price,
      checkedAt: entry.checkedAt,
    );
  }

  PriceHistoryEntriesCompanion _toPriceHistoryEntryCompanion(domain.PriceHistoryEntry entry) {
    return PriceHistoryEntriesCompanion(
      id: Value(entry.id),
      productId: Value(entry.productId),
      price: Value(entry.price),
      checkedAt: Value(entry.checkedAt),
    );
  }

  domain.ProductGroup _toProductGroupEntity(ProductGroup group) {
    return domain.ProductGroup(
      id: group.id,
      name: group.name,
    );
  }

  ProductGroupsCompanion _toProductGroupCompanion(domain.ProductGroup group) {
    return ProductGroupsCompanion(
      id: Value(group.id),
      name: Value(group.name),
    );
  }

  @override
  Future<String> exportDataToJson() async {
    final products = await getAllProducts();
    final priceHistory = <String, List<domain.PriceHistoryEntry>>{};
    
    // Get price history for each product
    for (final product in products) {
      final history = await getPriceHistory(product.id);
      priceHistory[product.id] = history;
    }

    final groups = await getAllGroups();

    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'products': products.map((p) => _productToJson(p)).toList(),
      'priceHistory': priceHistory.map(
        (productId, history) => MapEntry(
          productId,
          history.map((h) => _priceHistoryToJson(h)).toList(),
        ),
      ),
      'groups': groups.map((g) => _groupToJson(g)).toList(),
    };

    return jsonEncode(exportData);
  }

  @override
  Future<void> importDataFromJson(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;
    
    // Clear existing data
    await clearAllData();

    // Import groups first
    if (data['groups'] != null) {
      final groupsData = data['groups'] as List;
      for (final groupData in groupsData) {
        final group = _groupFromJson(groupData as Map<String, dynamic>);
        await createGroup(group);
      }
    }

    // Import products
    if (data['products'] != null) {
      final productsData = data['products'] as List;
      for (final productData in productsData) {
        final product = _productFromJson(productData as Map<String, dynamic>);
        await addProduct(product);
      }
    }

    // Import price history
    if (data['priceHistory'] != null) {
      final historyData = data['priceHistory'] as Map<String, dynamic>;
      for (final entry in historyData.entries) {
        final productId = entry.key;
        final historyList = entry.value as List;
        for (final historyItem in historyList) {
          final history = _priceHistoryFromJson(historyItem as Map<String, dynamic>);
          final historyWithProductId = domain.PriceHistoryEntry(
            id: history.id,
            productId: productId,
            price: history.price,
            checkedAt: history.checkedAt,
          );
          await addPriceHistoryEntry(historyWithProductId);
        }
      }
    }
  }

  @override
  Future<void> clearAllData() async {
    // Delete all price history entries
    final allProducts = await getAllProducts();
    for (final product in allProducts) {
      await deletePriceHistory(product.id);
    }

    // Delete all products
    for (final product in allProducts) {
      await deleteProduct(product.id);
    }

    // Delete all groups
    final allGroups = await getAllGroups();
    for (final group in allGroups) {
      await deleteGroup(group.id);
    }
  }

  Map<String, dynamic> _productToJson(domain.Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'imageUrl': product.imageUrl,
      'productUrl': product.productUrl,
      'siteHost': product.siteHost,
      'siteDisplayName': product.siteDisplayName,
      'initialPrice': product.initialPrice,
      'currentPrice': product.currentPrice,
      'currency': product.currency,
      'targetPrice': product.targetPrice,
      'addedAt': product.addedAt.toIso8601String(),
      'lastCheckedAt': product.lastCheckedAt?.toIso8601String(),
      'lastCheckStatus': product.lastCheckStatus.name,
      'isArchived': product.isArchived,
      'notes': product.notes,
      'tags': product.tags,
      'notifyThresholdPercent': product.notifyThresholdPercent,
      'groupId': product.groupId,
    };
  }

  domain.Product _productFromJson(Map<String, dynamic> json) {
    return domain.Product(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      productUrl: json['productUrl'] as String,
      siteHost: json['siteHost'] as String,
      siteDisplayName: json['siteDisplayName'] as String,
      initialPrice: (json['initialPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      currency: json['currency'] as String,
      targetPrice: json['targetPrice'] != null 
          ? (json['targetPrice'] as num).toDouble() 
          : null,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastCheckedAt: json['lastCheckedAt'] != null 
          ? DateTime.parse(json['lastCheckedAt'] as String) 
          : null,
      lastCheckStatus: _parseCheckStatus(json['lastCheckStatus'] as String),
      isArchived: json['isArchived'] as bool,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      notifyThresholdPercent: json['notifyThresholdPercent'] as int?,
      groupId: json['groupId'] as String?,
    );
  }

  Map<String, dynamic> _priceHistoryToJson(domain.PriceHistoryEntry entry) {
    return {
      'id': entry.id,
      'productId': entry.productId,
      'price': entry.price,
      'checkedAt': entry.checkedAt.toIso8601String(),
    };
  }

  domain.PriceHistoryEntry _priceHistoryFromJson(Map<String, dynamic> json) {
    return domain.PriceHistoryEntry(
      id: json['id'] as String,
      productId: json['productId'] as String,
      price: (json['price'] as num).toDouble(),
      checkedAt: DateTime.parse(json['checkedAt'] as String),
    );
  }

  Map<String, dynamic> _groupToJson(domain.ProductGroup group) {
    return {
      'id': group.id,
      'name': group.name,
    };
  }

  domain.ProductGroup _groupFromJson(Map<String, dynamic> json) {
    return domain.ProductGroup(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  domain.CheckStatus _parseCheckStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
        return domain.CheckStatus.ok;
      case 'parseerror':
        return domain.CheckStatus.parseError;
      case 'networkerror':
        return domain.CheckStatus.networkError;
      case 'notfound':
        return domain.CheckStatus.notFound;
      default:
        return domain.CheckStatus.networkError;
    }
  }
}
