import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';
import 'auth_provider.dart';
import 'customer_provider.dart';
import 'product_provider.dart';

/// Provides the SaleService instance.
final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(ref.watch(supabaseClientProvider));
});

/// Fetches the sales list for the current business.
final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ref.watch(saleServiceProvider).getSales(business.id);
});

/// Helper class for sale/checkout actions.
class SaleActions {
  final Ref ref;

  SaleActions(this.ref);

  SaleService get _saleService => ref.read(saleServiceProvider);
  ProductActions get _productActions => ref.read(productActionsProvider);

  /// Execute the checkout flow:
  /// 1. Re-validate stock for each cart item
  /// 2. Create the sale + sale_items
  /// 3. Decrement stock for each sold item
  /// 4. Return the completed Sale with items for the receipt
  ///
  /// On failure, throws and does NOT clear the cart.
  Future<Sale> checkout({
    required List<CartItem> cartItems,
    required double exchangeRate,
    required String paymentType,
    required String businessId,
    String? customerId,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    // 1. Re-validate stock by fetching fresh product data
    final productService = ref.read(productServiceProvider);
    final freshProducts = await productService.getProducts(businessId);
    final freshMap = {for (final p in freshProducts) p.id!: p};

    for (final item in cartItems) {
      final fresh = freshMap[item.productId];
      if (fresh == null) {
        throw Exception('Product "${item.productName}" no longer exists');
      }
      if (fresh.quantity < item.quantity) {
        throw Exception(
          'Not enough stock for "${item.productName}". '
          'Requested: ${item.quantity}, Available: ${fresh.quantity}',
        );
      }
    }

    // 2. Calculate totals using effective prices (respects overrides/discounts)
    final totalUsd =
        cartItems.fold(0.0, (sum, item) => sum + item.subtotalUsd);
    final totalLbp = totalUsd * exchangeRate;

    // 3. Build sale_items JSON (snapshot data)
    final itemsJson = cartItems.map((item) {
      return {
        'product_id': item.productId,
        'product_name_snapshot': item.productName,
        'quantity': item.quantity,
        'unit_price_usd': item.effectivePrice,
        'subtotal_usd': item.subtotalUsd,
      };
    }).toList();

    // 4. Create the sale
    final sale = await _saleService.createSale(
      businessId: businessId,
      totalUsd: totalUsd,
      totalLbp: totalLbp,
      exchangeRate: exchangeRate,
      paymentType: paymentType,
      itemsJson: itemsJson,
      customerId: customerId,
    );

    // 5. Decrement stock for each sold item
    for (final item in cartItems) {
      try {
        await _productActions.adjustStock(item.productId, -item.quantity);
      } catch (e) {
        // Stock adjustment failed after sale was created.
        // The sale record exists — flag this for manual correction.
        throw Exception(
          'Sale recorded but stock adjustment failed for '
          '"${item.productName}". Please adjust stock manually in Inventory.',
        );
      }
    }

    // 6. Invalidate providers to refresh data
    ref.invalidate(salesListProvider);
    ref.invalidate(productListProvider);
    if (customerId != null) {
      ref.invalidate(customerListProvider);
    }

    // 7. Build the Sale with items for receipt display
    final saleItems = cartItems.map((item) {
      return SaleItem(
        id: '', // Not critical for receipt display
        saleId: sale.id,
        productId: item.productId,
        productNameSnapshot: item.productName,
        quantity: item.quantity,
        unitPriceUsd: item.effectivePrice,
        subtotalUsd: item.subtotalUsd,
      );
    }).toList();

    return sale.copyWith(items: saleItems);
  }
}

/// Provider for sale actions.
final saleActionsProvider = Provider<SaleActions>((ref) {
  return SaleActions(ref);
});
