import '../../../../../../core/database/database.dart';

class ProductLocalDataSource {
  final AppDatabase database;

  ProductLocalDataSource(this.database);

  // Product CRUD operations
  Future<List<Product>> getAllProducts() => database.getAllProducts();
  
  Future<List<Product>> getActiveProducts() => database.getActiveProducts();
  
  Future<Product?> getProductById(String id) => database.getProductById(id);
  
  Future<void> addProduct(ProductsCompanion product) => 
      database.into(database.products).insert(product);
  
  Future<void> updateProduct(ProductsCompanion product) => 
      database.updateProduct(product);
  
  Future<void> deleteProduct(String id) => database.deleteProduct(id);
  


  // Price history operations
  Future<List<PriceHistoryEntry>> getPriceHistory(String productId) => 
      database.getPriceHistory(productId);
  
  Future<void> addPriceHistoryEntry(PriceHistoryEntriesCompanion entry) => 
      database.into(database.priceHistoryEntries).insert(entry);
  
  Future<void> deletePriceHistory(String productId) => 
      database.deletePriceHistory(productId);

  // Product group operations
  Future<List<ProductGroup>> getAllGroups() => database.getAllGroups();
  
  Future<ProductGroup?> getGroupById(String id) => database.getGroupById(id);
  
  Future<void> createGroup(ProductGroupsCompanion group) => 
      database.into(database.productGroups).insert(group);
  
  Future<void> updateGroup(ProductGroupsCompanion group) => 
      database.updateGroup(group);
  
  Future<void> deleteGroup(String id) => database.deleteGroup(id);
  
  Future<List<Product>> getProductsByGroup(String groupId) => 
      database.getProductsByGroup(groupId);

  // Search and filter
  Future<List<Product>> searchProducts(String query) => 
      database.searchProducts(query);
  
  Future<List<Product>> getProductsByTag(String tag) => 
      database.getProductsByTag(tag);

  // Statistics
  Future<int> getTotalProductCount() => database.getTotalProductCount();
  
  Future<int> getActiveProductCount() => database.getActiveProductCount();
  
  Future<int> getPriceDropCount() => database.getPriceDropCount();
}
