import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

enum CheckStatus {
  ok,
  parseError,
  networkError,
  notFound,
}

class Products extends Table {
  TextColumn get id => text()();
  
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get productUrl => text()();
  TextColumn get siteHost => text()();
  TextColumn get siteDisplayName => text()();
  RealColumn get initialPrice => real()();
  RealColumn get currentPrice => real()();
  TextColumn get currency => text().withDefault(const Constant('TRY'))();
  RealColumn get targetPrice => real().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
  TextColumn get lastCheckStatus => text().map(const CheckStatusConverter())();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().map(const TagsConverter())();
  IntColumn get notifyThresholdPercent => integer().nullable()();
  TextColumn get groupId => text().references(ProductGroups, #id).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceHistoryEntries extends Table {
  TextColumn get id => text()();
  
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get price => real()();
  DateTimeColumn get checkedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CheckStatusConverter extends TypeConverter<CheckStatus, String> {
  const CheckStatusConverter();

  @override
  CheckStatus fromSql(String fromDb) {
    try {
      return CheckStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == fromDb.toLowerCase(),
      );
    } catch (e) {
      return CheckStatus.networkError;
    }
  }

  @override
  String toSql(CheckStatus value) {
    return value.name;
  }
}

class TagsConverter extends TypeConverter<List<String>, String> {
  const TagsConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    return value.join(',');
  }
}

@DriftDatabase(tables: [Products, ProductGroups, PriceHistoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  static AppDatabase create() {
    final executor = LazyDatabase(() async {
      final dbDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbDir.path, 'fiyat_takip.db'));
      return NativeDatabase.createInBackground(file);
    });
    return AppDatabase(executor);
  }

  // Product queries
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<List<Product>> getActiveProducts() => 
      (select(products)..where((p) => p.isArchived.equals(false))).get();
  
  Future<List<Product>> getArchivedProducts() => 
      (select(products)..where((p) => p.isArchived.equals(true))).get();
  
  Future<Product?> getProductById(String id) => 
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  
  Future<void> updateProduct(ProductsCompanion product) => 
      update(products).replace(product);
  
  Future<void> deleteProduct(String id) => 
      (delete(products)..where((p) => p.id.equals(id))).go();
  
  Future<void> archiveProduct(String id) => 
      (update(products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(isArchived: Value(true)));
  
  Future<void> unarchiveProduct(String id) => 
      (update(products)..where((p) => p.id.equals(id)))
          .write(const ProductsCompanion(isArchived: Value(false)));

  // Price history queries
  Future<List<PriceHistoryEntry>> getPriceHistory(String productId) => 
      (select(priceHistoryEntries)..where((p) => p.productId.equals(productId)))
          .get();
  
  Future<void> deletePriceHistory(String productId) => 
      (delete(priceHistoryEntries)..where((p) => p.productId.equals(productId))).go();

  // Product group queries
  Future<List<ProductGroup>> getAllGroups() => select(productGroups).get();
  
  Future<ProductGroup?> getGroupById(String id) => 
      (select(productGroups)..where((g) => g.id.equals(id))).getSingleOrNull();
  
  Future<void> updateGroup(ProductGroupsCompanion group) => 
      update(productGroups).replace(group);
  
  Future<void> deleteGroup(String id) => 
      (delete(productGroups)..where((g) => g.id.equals(id))).go();
  
  Future<List<Product>> getProductsByGroup(String groupId) => 
      (select(products)..where((p) => p.groupId.equals(groupId))).get();

  // Search and filter
  Future<List<Product>> searchProducts(String query) => 
      (select(products)..where((p) => p.name.like('%$query%'))).get();
  
  Future<List<Product>> getProductsByTag(String tag) => 
      (select(products)..where((p) => p.tags.like('%$tag%'))).get();

  // Statistics
  Future<int> getTotalProductCount() => products.count().get().then((list) => list.length);
  
  Future<int> getActiveProductCount() => 
      (select(products)..where((p) => p.isArchived.equals(false))).get().then((list) => list.length);
  
  Future<int> getPriceDropCount() => 
      (select(products)..where((p) => p.currentPrice.isSmallerThan(p.initialPrice))).get().then((list) => list.length);
}
