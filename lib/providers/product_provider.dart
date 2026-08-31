import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

/// Provides the ProductService instance.
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(supabaseClientProvider));
});

/// Fetches the product list for the current business.
/// Use ref.invalidate(productListProvider) to refresh.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ref.watch(productServiceProvider).getProducts(business.id);
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
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            (p.category != null && p.category!.toLowerCase().contains(query)))
        .toList();
  });
});

/// Helper class for product actions that need to invalidate the list.
class ProductActions {
  final Ref ref;

  ProductActions(this.ref);

  ProductService get _service => ref.read(productServiceProvider);

  Future<Product> addProduct(Product product) async {
    final result = await _service.addProduct(product);
    ref.invalidate(productListProvider);
    return result;
  }

  Future<Product> updateProduct(Product product) async {
    final result = await _service.updateProduct(product);
    ref.invalidate(productListProvider);
    return result;
  }

  Future<void> deleteProduct(String productId) async {
    await _service.deleteProduct(productId);
    ref.invalidate(productListProvider);
  }

  Future<Product> adjustStock(String productId, int delta) async {
    final result = await _service.adjustStock(productId, delta);
    ref.invalidate(productListProvider);
    return result;
  }
}

/// Provider for product actions.
final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref);
});
