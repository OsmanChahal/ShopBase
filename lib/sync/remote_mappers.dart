import 'package:drift/drift.dart';
import '../database/app_database.dart';

// Converts Supabase rows into local Drift rows. Shared by the first-login
// download (InitialPullService) and the incremental sync (SyncEngine), so
// both store remote data the same way.

LocalProductsCompanion productFromRemote(
  Map<String, dynamic> j, {
  required DateTime syncedAt,
}) {
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
          : syncedAt,
    ),
    lastSyncedAt: Value(syncedAt),
  );
}

LocalCustomersCompanion customerFromRemote(
  Map<String, dynamic> j, {
  required DateTime syncedAt,
}) {
  return LocalCustomersCompanion.insert(
    id: j['id'] as String,
    businessId: j['business_id'] as String,
    name: j['name'] as String,
    phone: Value(j['phone'] as String?),
    createdAt: DateTime.parse(j['created_at'] as String),
    lastSyncedAt: Value(syncedAt),
  );
}

LocalSalesCompanion saleFromRemote(Map<String, dynamic> j) {
  return LocalSalesCompanion.insert(
    id: j['id'] as String,
    businessId: j['business_id'] as String,
    customerId: Value(j['customer_id'] as String?),
    totalUsd: (j['total_usd'] as num).toDouble(),
    totalLbp: (j['total_lbp'] as num).toDouble(),
    exchangeRateUsed: (j['exchange_rate_used'] as num).toDouble(),
    paymentType: j['payment_type'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    synced: const Value(true), // already exists on the server
    inventoryId: Value(j['inventory_id'] as String?),
  );
}

LocalSaleItemsCompanion saleItemFromRemote(Map<String, dynamic> j) {
  return LocalSaleItemsCompanion.insert(
    id: j['id'] as String,
    saleId: j['sale_id'] as String,
    // product_id becomes null on the server after the product is deleted
    productId: (j['product_id'] as String?) ?? '',
    productNameSnapshot: j['product_name_snapshot'] as String,
    quantity: j['quantity'] as int,
    unitPriceUsd: (j['unit_price_usd'] as num).toDouble(),
    subtotalUsd: (j['subtotal_usd'] as num).toDouble(),
    costPriceUsdSnapshot: Value(
      (j['cost_price_snapshot'] as num?)?.toDouble(),
    ),
  );
}
