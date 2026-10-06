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
    return (_db.select(
      _db.localSaleItems,
    )..where((t) => t.saleId.equals(saleId))).get();
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
    String? inventoryId, // NEW (null = legacy fallback)
  }) async {
    final saleId = _uuid.v4();
    final now = DateTime.now().toUtc();

    // NEW: cost price at sale time, from this inventory's stock rows
    final costs = <String, double>{};
    if (inventoryId != null) {
      for (final item in items) {
        final pid = item['productId'] as String;
        final row =
            await (_db.select(_db.localInventoryStock)..where(
                  (t) =>
                      t.productId.equals(pid) &
                      t.inventoryId.equals(inventoryId),
                ))
                .getSingleOrNull();
        if (row != null) costs[pid] = row.costPriceUsd;
      }
    }

    final saleItems = <LocalSaleItemsCompanion>[];
    final itemsPayload = <Map<String, dynamic>>[];

    for (final item in items) {
      final itemId = _uuid.v4();
      final cost = costs[item['productId'] as String];
      saleItems.add(
        LocalSaleItemsCompanion.insert(
          id: itemId,
          saleId: saleId,
          productId: item['productId'] as String,
          productNameSnapshot: item['productName'] as String,
          quantity: item['quantity'] as int,
          unitPriceUsd: item['unitPriceUsd'] as double,
          subtotalUsd: item['subtotalUsd'] as double,
          costPriceUsdSnapshot: Value(cost), // NEW
        ),
      );
      itemsPayload.add({
        'id': itemId,
        'sale_id': saleId,
        'product_id': item['productId'],
        'product_name_snapshot': item['productName'],
        'quantity': item['quantity'],
        'unit_price_usd': item['unitPriceUsd'],
        'subtotal_usd': item['subtotalUsd'],
        'cost_price_usd_snapshot':
            cost, // NEW (null -> server trigger fills it)
      });
    }

    await _db.transaction(() async {
      await _db
          .into(_db.localSales)
          .insert(
            LocalSalesCompanion.insert(
              id: saleId,
              businessId: businessId,
              customerId: Value(customerId),
              totalUsd: totalUsd,
              totalLbp: totalLbp,
              exchangeRateUsed: exchangeRate,
              paymentType: paymentType,
              createdAt: now,
              inventoryId: Value(inventoryId), // NEW
            ),
          );

      for (final item in saleItems) {
        await _db.into(_db.localSaleItems).insert(item);
      }

      for (final delta in stockDeltas) {
        final productId = delta['productId'] as String;
        final qty = delta['delta'] as int; // negative

        if (inventoryId != null) {
          // NEW: decrement this inventory's stock (clamped at 0 like the server)
          final row =
              await (_db.select(_db.localInventoryStock)..where(
                    (t) =>
                        t.productId.equals(productId) &
                        t.inventoryId.equals(inventoryId),
                  ))
                  .getSingleOrNull();
          if (row != null) {
            final newQty = row.quantity + qty;
            await (_db.update(_db.localInventoryStock)..where(
                  (t) =>
                      t.productId.equals(productId) &
                      t.inventoryId.equals(inventoryId),
                ))
                .write(
                  LocalInventoryStockCompanion(
                    quantity: Value(newQty < 0 ? 0 : newQty),
                  ),
                );
          }
        } else {
          // legacy fallback, unchanged
          final product = await (_db.select(
            _db.localProducts,
          )..where((t) => t.id.equals(productId))).getSingleOrNull();
          if (product != null) {
            await (_db.update(
              _db.localProducts,
            )..where((t) => t.id.equals(productId))).write(
              LocalProductsCompanion(
                quantity: Value(product.quantity + qty),
                updatedAt: Value(now),
              ),
            );
          }
        }
      }
    });

    await _syncQueue.enqueue(
      operationType: 'sale',
      payloadJson: jsonEncode({
        'sale': {
          'id': saleId,
          'business_id': businessId,
          'customer_id': customerId,
          'inventory_id':
              inventoryId, // NEW (null -> server trigger fills Main)
          'total_usd': totalUsd,
          'total_lbp': totalLbp,
          'exchange_rate_used': exchangeRate,
          'payment_type': paymentType,
          'created_at': now.toIso8601String(),
        },
        'items': itemsPayload,
        'stock_deltas': stockDeltas
            .map(
              (d) => {
                'product_id': d['productId'],
                if (inventoryId != null) 'inventory_id': inventoryId, // NEW
                'delta': d['delta'],
                'operation_id': _uuid.v4(),
                if (inventoryId != null) 'reason': 'sale', // NEW
              },
            )
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
