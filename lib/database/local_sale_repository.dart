import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'sync_queue_repository.dart';

const _uuid = Uuid();

/// Repository for sales against the local SQLite database.
/// Creating a sale also decrements stock and enqueues a single 'sale' operation.
class LocalSaleRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  LocalSaleRepository(this._db, this._syncQueue);

  /// Fetch all sales for a business, most recent first.
  Future<List<LocalSale>> getSales(String businessId) async {
    return (_db.select(_db.localSales)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Fetch line items for a specific sale.
  Future<List<LocalSaleItem>> getSaleItems(String saleId) async {
    return (_db.select(_db.localSaleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
  }

  /// Create a sale with its line items and stock decrements in a single transaction.
  /// Returns the sale ID.
  ///
  /// [items] is a list of maps with keys:
  ///   productId, productName, quantity, unitPriceUsd, subtotalUsd
  ///
  /// [stockDeltas] is a list of maps with keys:
  ///   productId, delta (negative)
  Future<String> createSale({
    required String businessId,
    String? customerId,
    required double totalUsd,
    required double totalLbp,
    required double exchangeRate,
    required String paymentType,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> stockDeltas,
  }) async {
    final saleId = _uuid.v4();
    final now = DateTime.now().toUtc();

    // Build sale items with generated IDs
    final saleItems = <LocalSaleItemsCompanion>[];
    final itemsPayload = <Map<String, dynamic>>[];

    for (final item in items) {
      final itemId = _uuid.v4();
      saleItems.add(LocalSaleItemsCompanion.insert(
        id: itemId,
        saleId: saleId,
        productId: item['productId'] as String,
        productNameSnapshot: item['productName'] as String,
        quantity: item['quantity'] as int,
        unitPriceUsd: item['unitPriceUsd'] as double,
        subtotalUsd: item['subtotalUsd'] as double,
      ));
      itemsPayload.add({
        'id': itemId,
        'sale_id': saleId,
        'product_id': item['productId'],
        'product_name_snapshot': item['productName'],
        'quantity': item['quantity'],
        'unit_price_usd': item['unitPriceUsd'],
        'subtotal_usd': item['subtotalUsd'],
      });
    }

    // Execute everything in a transaction
    await _db.transaction(() async {
      // 1. Insert sale
      await _db.into(_db.localSales).insert(
            LocalSalesCompanion.insert(
              id: saleId,
              businessId: businessId,
              customerId: Value(customerId),
              totalUsd: totalUsd,
              totalLbp: totalLbp,
              exchangeRateUsed: exchangeRate,
              paymentType: paymentType,
              createdAt: now,
            ),
          );

      // 2. Insert sale items
      for (final item in saleItems) {
        await _db.into(_db.localSaleItems).insert(item);
      }

      // 3. Decrement stock for each product
      for (final delta in stockDeltas) {
        final productId = delta['productId'] as String;
        final qty = delta['delta'] as int; // negative
        final product = await (_db.select(_db.localProducts)
              ..where((t) => t.id.equals(productId)))
            .getSingleOrNull();
        if (product != null) {
          await (_db.update(_db.localProducts)
                ..where((t) => t.id.equals(productId)))
              .write(LocalProductsCompanion(
            quantity: Value(product.quantity + qty),
            updatedAt: Value(now),
          ));
        }
      }
    });

    // 4. Enqueue a single 'sale' operation with full payload
    await _syncQueue.enqueue(
      operationType: 'sale',
      payloadJson: jsonEncode({
        'sale': {
          'id': saleId,
          'business_id': businessId,
          'customer_id': customerId,
          'total_usd': totalUsd,
          'total_lbp': totalLbp,
          'exchange_rate_used': exchangeRate,
          'payment_type': paymentType,
          'created_at': now.toIso8601String(),
        },
        'items': itemsPayload,
        'stock_deltas': stockDeltas
            .map((d) => {
                  'product_id': d['productId'],
                  'delta': d['delta'],
                })
            .toList(),
      }),
    );

    return saleId;
  }

  /// Batch insert sales from the initial pull (no sync queue entries needed).
  Future<void> bulkInsertSales(List<LocalSalesCompanion> sales) async {
    await _db.batch((batch) {
      batch.insertAll(_db.localSales, sales);
    });
  }

  /// Batch insert sale items from the initial pull.
  Future<void> bulkInsertSaleItems(List<LocalSaleItemsCompanion> items) async {
    await _db.batch((batch) {
      batch.insertAll(_db.localSaleItems, items);
    });
  }
}
