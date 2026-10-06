import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/local_product_repository.dart';
import '../database/sync_queue_repository.dart';
import '../models/product.dart';
import 'inventory_provider.dart';
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

  final inventoryId = await ref.watch(currentInventoryIdProvider.future); // NEW
  final repo = ref.watch(localProductRepositoryProvider);

  if (inventoryId == null) {
    // No inventories pulled yet (offline right after upgrade): legacy read
    final localProducts = await repo.getProducts(business.id);
    return localProducts.map(_localProductToModel).toList();
  }
  final rows = await repo.getProductsForInventory(business.id, inventoryId);
  return rows.map(_joinedToModel).toList();
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

  Future<String?> _currentInventory() =>
      ref.read(currentInventoryIdProvider.future);

  Future<Product> _load(String id, String? inventoryId) async {
    if (inventoryId != null) {
      final joined = await _repo.getProductWithStock(id, inventoryId);
      if (joined != null) return _joinedToModel(joined);
    }
    return _localProductToModel((await _repo.getProductById(id))!);
  }

  Future<Product> addProduct(Product product) async {
    final inventoryId = product.inventoryId ?? await _currentInventory();
    final id = await _repo.addProduct(
      businessId: product.businessId,
      name: product.name,
      sku: product.sku,
      category: product.category,
      costPriceUsd: product.costPriceUsd,
      sellPriceUsd: product.sellPriceUsd,
      quantity: product.quantity,
      lowStockThreshold: product.lowStockThreshold,
      inventoryId: inventoryId,
    );
    ref.invalidate(productListProvider);
    return _load(id, inventoryId);
  }

  Future<Product> updateProduct(Product product) async {
    // Use the inventory this product was loaded from, not whatever is selected now
    final inventoryId = product.inventoryId ?? await _currentInventory();
    await _repo.updateProduct(
      id: product.id!,
      businessId: product.businessId,
      name: product.name,
      sku: product.sku,
      category: product.category,
      costPriceUsd: product.costPriceUsd,
      sellPriceUsd: product.sellPriceUsd,
      lowStockThreshold: product.lowStockThreshold,
      inventoryId: inventoryId,
    );
    ref.invalidate(productListProvider);
    return _load(product.id!, inventoryId);
  }

  Future<void> deleteProduct(String productId) async {
    await _repo.deleteProduct(productId);
    ref.invalidate(productListProvider);
  }

  Future<Product> adjustStock(
    String productId,
    int delta, {
    String? inventoryId,
  }) async {
    final inv = inventoryId ?? await _currentInventory();
    await _repo.adjustStock(productId, delta, inventoryId: inv);
    ref.invalidate(productListProvider);
    return _load(productId, inv);
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

/// NEW: catalog + per-inventory stock -> app model
Product _joinedToModel(ProductWithStock ps) {
  return Product(
    id: ps.product.id,
    inventoryId: ps.stock.inventoryId,
    businessId: ps.product.businessId,
    name: ps.product.name,
    sku: ps.product.sku,
    category: ps.product.category,
    costPriceUsd: ps.stock.costPriceUsd,
    sellPriceUsd: ps.stock.sellPriceUsd,
    quantity: ps.stock.quantity,
    lowStockThreshold: ps.stock.lowStockThreshold,
    updatedAt: ps.stock.updatedAt ?? ps.product.updatedAt,
  );
}
