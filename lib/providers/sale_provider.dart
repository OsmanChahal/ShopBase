import 'inventory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/local_product_repository.dart';
import '../database/local_sale_repository.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';
import 'auth_provider.dart';
import 'customer_provider.dart';
import 'product_provider.dart';

/// Provides the SaleService instance (still used by CRM customer detail screen).
final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(ref.watch(supabaseClientProvider));
});

/// Provides the LocalSaleRepository instance.
final localSaleRepositoryProvider = Provider<LocalSaleRepository>((ref) {
  return LocalSaleRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncQueueRepositoryProvider),
  );
});

/// Fetches the sales list for the current business from the local database.
final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  final repo = ref.watch(localSaleRepositoryProvider);
  final localSales = await repo.getSales(business.id);

  return localSales.map(_localSaleToModel).toList();
});

/// Helper class for sale/checkout actions using the local database.
class SaleActions {
  final Ref ref;

  SaleActions(this.ref);

  LocalSaleRepository get _saleRepo => ref.read(localSaleRepositoryProvider);

  /// Line items for [saleId] from the local database, as app models.
  Future<List<SaleItem>> getLocalSaleItems(String saleId) async {
    final localItems = await _saleRepo.getSaleItems(saleId);
    return localItems.map(localSaleItemToModel).toList();
  }
  LocalProductRepository get _productRepo =>
      ref.read(localProductRepositoryProvider);

  /// Execute the checkout flow entirely against the local database:
  /// 1. Validate stock from local_products
  /// 2. Generate UUIDs for sale + each sale item
  /// 3. Insert local_sales + local_sale_items
  /// 4. Decrement local_products.quantity for each item
  /// 5. Enqueue a single 'sale' operation with full payload
  /// 6. Return the completed Sale with items for the receipt
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

    final inventoryId = await ref.read(
      currentInventoryIdProvider.future,
    ); // NEW

    // 1. Validate stock against the current inventory (legacy fallback if none)
    for (final item in cartItems) {
      int available;
      if (inventoryId != null) {
        final stock = await _productRepo.getStockRow(
          item.productId,
          inventoryId,
        );
        if (stock == null) {
          throw Exception(
            '"${item.productName}" is not stocked in this inventory',
          );
        }
        available = stock.quantity;
      } else {
        final product = await _productRepo.getProductById(item.productId);
        if (product == null) {
          throw Exception('Product "${item.productName}" no longer exists');
        }
        available = product.quantity;
      }
      if (available < item.quantity) {
        throw Exception(
          'Not enough stock for "${item.productName}". '
          'Requested: ${item.quantity}, Available: $available',
        );
      }
    }

    // 2. Calculate totals using effective prices (respects overrides/discounts)
    final totalUsd = cartItems.fold(0.0, (sum, item) => sum + item.subtotalUsd);
    final totalLbp = totalUsd * exchangeRate;

    // 3. Build items and stock deltas
    final items = cartItems.map((item) {
      return {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPriceUsd': item.effectivePrice,
        'subtotalUsd': item.subtotalUsd,
      };
    }).toList();

    final stockDeltas = cartItems.map((item) {
      return {'productId': item.productId, 'delta': -item.quantity};
    }).toList();

    // 4. Create the sale (transaction: sale + items + stock decrements + enqueue)
    final saleId = await _saleRepo.createSale(
      businessId: businessId,
      customerId: customerId,
      totalUsd: totalUsd,
      totalLbp: totalLbp,
      exchangeRate: exchangeRate,
      paymentType: paymentType,
      items: items,
      stockDeltas: stockDeltas,
      inventoryId: inventoryId,
    );

    // 5. Invalidate providers to refresh UI
    ref.invalidate(salesListProvider);
    ref.invalidate(productListProvider);
    if (customerId != null) {
      ref.invalidate(customerListProvider);
    }

    // 6. Build the Sale with items for receipt display
    final saleItems = cartItems.map((item) {
      return SaleItem(
        id: '', // Not critical for receipt display
        saleId: saleId,
        productId: item.productId,
        productNameSnapshot: item.productName,
        quantity: item.quantity,
        unitPriceUsd: item.effectivePrice,
        subtotalUsd: item.subtotalUsd,
      );
    }).toList();

    final sale = Sale(
      id: saleId,
      businessId: businessId,
      customerId: customerId,
      totalUsd: totalUsd,
      totalLbp: totalLbp,
      exchangeRateUsed: exchangeRate,
      paymentType: paymentType,
      createdAt: DateTime.now().toUtc(),
      items: saleItems,
    );

    return sale;
  }
}

/// Provider for sale actions.
final saleActionsProvider = Provider<SaleActions>((ref) {
  return SaleActions(ref);
});

/// Convert a drift LocalSaleItem row into the app-level SaleItem model.
SaleItem localSaleItemToModel(LocalSaleItem li) {
  return SaleItem(
    id: li.id,
    saleId: li.saleId,
    productId: li.productId,
    productNameSnapshot: li.productNameSnapshot,
    quantity: li.quantity,
    unitPriceUsd: li.unitPriceUsd,
    subtotalUsd: li.subtotalUsd,
  );
}

/// Convert a drift LocalSale row into the app-level Sale model.
Sale _localSaleToModel(LocalSale ls) {
  return Sale(
    id: ls.id,
    businessId: ls.businessId,
    customerId: ls.customerId,
    totalUsd: ls.totalUsd,
    totalLbp: ls.totalLbp,
    exchangeRateUsed: ls.exchangeRateUsed,
    paymentType: ls.paymentType,
    createdAt: ls.createdAt,
  );
}
