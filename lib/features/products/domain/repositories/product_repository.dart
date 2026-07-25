import '../entities/product.dart';
import '../entities/price_history_entry.dart';
import '../entities/product_group.dart';

abstract class ProductRepository {
  // Product CRUD operations
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getActiveProducts();
  Future<Product?> getProductById(String id);
  Future<Product> addProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> deleteProduct(String id);


  // Scraping operation - adds a product by scraping the given URL
  Future<Product> addProductFromUrl(String productUrl, {double? targetPrice, String? notes, String? groupId});

  // Price history operations
  Future<List<PriceHistoryEntry>> getPriceHistory(String productId);
  Future<PriceHistoryEntry> addPriceHistoryEntry(PriceHistoryEntry entry);
  Future<void> deletePriceHistory(String productId);

  // Product group operations
  Future<List<ProductGroup>> getAllGroups();
  Future<ProductGroup?> getGroupById(String id);
  Future<ProductGroup> createGroup(ProductGroup group);
  Future<ProductGroup> updateGroup(ProductGroup group);
  Future<void> deleteGroup(String id);
  Future<List<Product>> getProductsByGroup(String groupId);

  // Search and filter
  Future<List<Product>> searchProducts(String query);
  Future<List<Product>> getProductsByTag(String tag);

  // Statistics
  Future<int> getTotalProductCount();
  Future<int> getActiveProductCount();
  Future<int> getPriceDropCount();

  // Export/Import operations
  Future<String> exportDataToJson();
  Future<void> importDataFromJson(String jsonData);
  Future<void> clearAllData();

  // Foreground refresh operations
  Future<void> refreshProductPrice(String productId);
  Future<List<Product>> getStaleProducts(Duration threshold);
}
