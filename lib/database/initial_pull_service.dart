import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_database.dart';
import 'local_customer_repository.dart';
import 'local_product_repository.dart';
import 'local_sale_repository.dart';

/// One-time initial pull from Supabase into the local SQLite database.
///
/// On first run for an existing business, fetches all products, customers,
/// sales, and sale_items from Supabase and populates the local tables.
/// Only runs once — checks if local data already exists before pulling.
class InitialPullService {
  final SupabaseClient _supabase;
  final LocalProductRepository _productRepo;
  final LocalCustomerRepository _customerRepo;
  final LocalSaleRepository _saleRepo;

  InitialPullService({
    required SupabaseClient supabase,
    required LocalProductRepository productRepo,
    required LocalCustomerRepository customerRepo,
    required LocalSaleRepository saleRepo,
  }) : _supabase = supabase,
       _productRepo = productRepo,
       _customerRepo = customerRepo,
       _saleRepo = saleRepo;

  /// Check if the initial pull is needed and perform it if so.
  /// Returns true if a pull was performed, false if it was skipped.
  Future<bool> pullIfNeeded(String businessId) async {
    // If local products already exist for this business, skip
    final hasData = await _productRepo.hasProducts(businessId);
    if (hasData) return false;

    await _pullAll(businessId);
    return true;
  }

  Future<void> _pullAll(String businessId) async {
    final now = DateTime.now().toUtc();

    // 1. Pull products
    final productsResponse = await _supabase
        .from('products')
        .select()
        .eq('business_id', businessId)
        .order('name', ascending: true);

    final productCompanions = (productsResponse as List).map((json) {
      final j = json as Map<String, dynamic>;
      return LocalProductsCompanion.insert(
        id: j['id'] as String,
        businessId: j['business_id'] as String,
        name: j['name'] as String,
        sku: Value(j['sku'] as String?),
        category: Value(j['category'] as String?),
        costPriceUsd: (j['cost_price_usd'] as num).toDouble(),
        sellPriceUsd: (j['sell_price_usd'] as num).toDouble(),
        quantity: j['quantity'] as int,
        lowStockThreshold: Value((j['low_stock_threshold'] as int?) ?? 5),
        updatedAt: Value(
          j['updated_at'] != null
              ? DateTime.parse(j['updated_at'] as String)
              : now,
        ),
        lastSyncedAt: Value(now),
      );
    }).toList();

    if (productCompanions.isNotEmpty) {
      await _productRepo.bulkInsertProducts(productCompanions);
    }

    // 2. Pull customers
    final customersResponse = await _supabase
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .order('name', ascending: true);

    final customerCompanions = (customersResponse as List).map((json) {
      final j = json as Map<String, dynamic>;
      return LocalCustomersCompanion.insert(
        id: j['id'] as String,
        businessId: j['business_id'] as String,
        name: j['name'] as String,
        phone: Value(j['phone'] as String?),
        createdAt: DateTime.parse(j['created_at'] as String),
        lastSyncedAt: Value(now),
      );
    }).toList();

    if (customerCompanions.isNotEmpty) {
      await _customerRepo.bulkInsertCustomers(customerCompanions);
    }

    // 3. Pull sales
    final salesResponse = await _supabase
        .from('sales')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    final salesList = salesResponse as List;
    if (salesList.isNotEmpty) {
      final saleCompanions = salesList.map((json) {
        final j = json as Map<String, dynamic>;
        return LocalSalesCompanion.insert(
          id: j['id'] as String,
          businessId: j['business_id'] as String,
          customerId: Value(j['customer_id'] as String?),
          totalUsd: (j['total_usd'] as num).toDouble(),
          totalLbp: (j['total_lbp'] as num).toDouble(),
          exchangeRateUsed: (j['exchange_rate_used'] as num).toDouble(),
          paymentType: j['payment_type'] as String,
          createdAt: DateTime.parse(j['created_at'] as String),
          synced: const Value(true), // Already exists on server
          inventoryId: Value(j['inventory_id'] as String?),
        );
      }).toList();

      await _saleRepo.bulkInsertSales(saleCompanions);

      // 4. Pull sale items for all sales
      final saleIds = salesList.map((j) => j['id'] as String).toList();

      // Fetch in batches to avoid URL length limits
      final allItemCompanions = <LocalSaleItemsCompanion>[];
      for (var i = 0; i < saleIds.length; i += 50) {
        final batchIds = saleIds.sublist(
          i,
          i + 50 > saleIds.length ? saleIds.length : i + 50,
        );
        final itemsResponse = await _supabase
            .from('sale_items')
            .select()
            .inFilter('sale_id', batchIds);

        for (final json in (itemsResponse as List)) {
          final j = json as Map<String, dynamic>;
          allItemCompanions.add(
            LocalSaleItemsCompanion.insert(
              id: j['id'] as String,
              saleId: j['sale_id'] as String,
              productId:
                  (j['product_id'] as String?) ??
                  '', //Changes null after product deletion
              productNameSnapshot: j['product_name_snapshot'] as String,
              quantity: j['quantity'] as int,
              unitPriceUsd: (j['unit_price_usd'] as num).toDouble(),
              subtotalUsd: (j['subtotal_usd'] as num).toDouble(),
              costPriceUsdSnapshot: Value(
                (j['cost_price_snapshot'] as num?)?.toDouble(),
              ),
            ),
          );
        }
      }

      if (allItemCompanions.isNotEmpty) {
        await _saleRepo.bulkInsertSaleItems(allItemCompanions);
      }
    }
  }
}
