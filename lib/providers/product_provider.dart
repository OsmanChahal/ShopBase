import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/local_product_repository.dart';
import '../database/sync_queue_repository.dart';
import '../models/product.dart';
import 'auth_provider.dart';

/// Provides the SyncQueueRepository instance (shared across repos).
final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.watch(appDatabaseProvider));
});

/// Provides the LocalProductRepository instance.
final localProductRepositoryProvider = Provider<LocalProductRepository>((ref) {
  return LocalProductRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncQueueRepositoryProvider),
  );
});

/// Fetches the product list for the current business from the local database.
/// Use ref.invalidate(productListProvider) to refresh.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  final repo = ref.watch(localProductRepositoryProvider);
  final localProducts = await repo.getProducts(business.id);

  // Convert LocalProduct (drift row) → Product (app model)
  return localProducts.map(_localProductToModel).toList();
});

/// pROVIDER FOR THE CATEGORIES LIST
final productCategoryProvider = FutureProvider<List<String>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  final repo = ref.watch(localProductRepositoryProvider);
  final localCategories = await repo.getDistinctCategories(business.id);
  return localCategories.toList();
});

/// Shared search query state for product search across POS & Inventory screens.
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered product list provider sharing search-as-you-type logic.
final filteredProductListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productListProvider);
  final query = ref.watch(productSearchQueryProvider).trim().toLowerCase();

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              (p.category != null && p.category!.toLowerCase().contains(query)),
        )
        .toList();
  });
});

/// Helper class for product actions that operate on the local database.
class ProductActions {
  final Ref ref;

  ProductActions(this.ref);

  LocalProductRepository get _repo => ref.read(localProductRepositoryProvider);

  Future<Product> addProduct(Product product) async {
    final result = await _repo.addProduct(
      businessId: product.businessId,
      name: product.name,
      sku: product.sku,
      category: product.category,
      costPriceUsd: product.costPriceUsd,
      sellPriceUsd: product.sellPriceUsd,
      quantity: product.quantity,
      lowStockThreshold: product.lowStockThreshold,
    );
    ref.invalidate(productListProvider);
    return _localProductToModel(result);
  }

  Future<Product> updateProduct(Product product) async {
    final result = await _repo.updateProduct(
      id: product.id!,
      businessId: product.businessId,
      name: product.name,
      sku: product.sku,
      category: product.category,
      costPriceUsd: product.costPriceUsd,
      sellPriceUsd: product.sellPriceUsd,
      lowStockThreshold: product.lowStockThreshold,
    );
    ref.invalidate(productListProvider);
    return _localProductToModel(result);
  }

  Future<void> deleteProduct(String productId) async {
    await _repo.deleteProduct(productId);
    ref.invalidate(productListProvider);
  }

  Future<Product> adjustStock(String productId, int delta) async {
    final result = await _repo.adjustStock(productId, delta);
    ref.invalidate(productListProvider);
    return _localProductToModel(result);
  }
}

/// Provider for product actions.
final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref);
});

/// Convert a drift LocalProduct row into the app-level Product model.
Product _localProductToModel(LocalProduct lp) {
  return Product(
    id: lp.id,
    businessId: lp.businessId,
    name: lp.name,
    sku: lp.sku,
    category: lp.category,
    costPriceUsd: lp.costPriceUsd,
    sellPriceUsd: lp.sellPriceUsd,
    quantity: lp.quantity,
    lowStockThreshold: lp.lowStockThreshold,
    updatedAt: lp.updatedAt,
  );
}
