import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/price_history_entry.dart';
import '../../domain/entities/product_group.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/providers/providers.dart';

// Products list provider
final productsListProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getActiveProducts();
});

// Archived products provider
final archivedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getArchivedProducts();
});

// Single product provider
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  final product = await repository.getProductById(id);
  if (product == null) {
    throw Exception('Product not found');
  }
  return product;
});

// Price history provider
final priceHistoryProvider = FutureProvider.family<List<PriceHistoryEntry>, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getPriceHistory(productId);
});

// Product groups provider
final productGroupsProvider = FutureProvider<List<ProductGroup>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getAllGroups();
});

// Products by group provider
final productsByGroupProvider = FutureProvider.family<List<Product>, String>((ref, groupId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByGroup(groupId);
});

// Search results provider
final searchResultsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.searchProducts(query);
});

// Products by tag provider
final productsByTagProvider = FutureProvider.family<List<Product>, String>((ref, tag) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByTag(tag);
});

// Statistics providers
final totalProductCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getTotalProductCount();
});

final activeProductCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getActiveProductCount();
});

final priceDropCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getPriceDropCount();
});

// Product operations notifier
class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getActiveProducts();
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _repository.addProduct(product);
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveProduct(String id) async {
    try {
      await _repository.archiveProduct(id);
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unarchiveProduct(String id) async {
    try {
      await _repository.unarchiveProduct(id);
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshProductPrices() async {
    try {
      final products = state.value ?? [];
      for (final product in products) {
        await (_repository as ProductRepositoryImpl).updateProductPrice(product.id);
      }
      await loadProducts();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Product notifier provider
final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(repository);
});
