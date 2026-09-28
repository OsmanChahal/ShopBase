import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'sync_queue_repository.dart';

const _uuid = Uuid();

/// Repository for product CRUD against the local SQLite database.
/// Every mutation enqueues the corresponding operation into the sync queue.
class LocalProductRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  LocalProductRepository(this._db, this._syncQueue);

  /// Fetch all products for a business, sorted alphabetically by name.
  Future<List<LocalProduct>> getProducts(String businessId) async {
    return (_db.select(_db.localProducts)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Fetch a single product by ID.
  Future<LocalProduct?> getProductById(String id) async {
    return (_db.select(
      _db.localProducts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Check if any products exist for a business (used for initial pull guard).
  Future<bool> hasProducts(String businessId) async {
    final count = countAll();
    final query = _db.selectOnly(_db.localProducts)
      ..addColumns([count])
      ..where(_db.localProducts.businessId.equals(businessId));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Add a new product. Generates a UUID, inserts into local DB,
  /// and enqueues a product_upsert operation.
  Future<LocalProduct> addProduct({
    required String businessId,
    required String name,
    String? sku,
    String? category,
    required double costPriceUsd,
    required double sellPriceUsd,
    required int quantity,
    int lowStockThreshold = 5,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();

    final companion = LocalProductsCompanion.insert(
      id: id,
      businessId: businessId,
      name: name,
      sku: Value(sku),
      category: Value(category),
      costPriceUsd: costPriceUsd,
      sellPriceUsd: sellPriceUsd,
      quantity: quantity,
      lowStockThreshold: Value(lowStockThreshold),
      updatedAt: Value(now),
      lastSyncedAt: const Value(null), // never synced
    );

    await _db.into(_db.localProducts).insert(companion);

    // Enqueue for sync
    await _syncQueue.enqueue(
      operationType: 'product_upsert',
      payloadJson: jsonEncode({
        'id': id,
        'business_id': businessId,
        'name': name,
        'sku': sku,
        'category': category,
        'cost_price_usd': costPriceUsd,
        'sell_price_usd': sellPriceUsd,
        'quantity': quantity,
        'low_stock_threshold': lowStockThreshold,
      }),
    );

    return (await getProductById(id))!;
  }

  /// Update a product (all fields except quantity — stock changes go through adjustStock).
  /// Enqueues a product_upsert operation with the updated non-quantity fields.
  Future<LocalProduct> updateProduct({
    required String id,
    required String businessId,
    required String name,
    String? sku,
    String? category,
    required double costPriceUsd,
    required double sellPriceUsd,
    required int lowStockThreshold,
  }) async {
    final now = DateTime.now().toUtc();

    await (_db.update(_db.localProducts)..where((t) => t.id.equals(id))).write(
      LocalProductsCompanion(
        name: Value(name),
        sku: Value(sku),
        category: Value(category),
        costPriceUsd: Value(costPriceUsd),
        sellPriceUsd: Value(sellPriceUsd),
        lowStockThreshold: Value(lowStockThreshold),
        updatedAt: Value(now),
      ),
    );

    // Enqueue for sync (non-quantity fields only)
    await _syncQueue.enqueue(
      operationType: 'product_upsert',
      payloadJson: jsonEncode({
        'id': id,
        'business_id': businessId,
        'name': name,
        'sku': sku,
        'category': category,
        'cost_price_usd': costPriceUsd,
        'sell_price_usd': sellPriceUsd,
        'low_stock_threshold': lowStockThreshold,
      }),
    );

    return (await getProductById(id))!;
  }

  /// Delete a product. Enqueues a product_delete operation.
  Future<void> deleteProduct(String id) async {
    await (_db.delete(_db.localProducts)..where((t) => t.id.equals(id))).go();

    await _syncQueue.enqueue(
      operationType: 'product_delete',
      payloadJson: jsonEncode({'product_id': id}),
    );
  }

  /// Adjust stock quantity by a delta. Updates local_products.quantity
  /// and enqueues a stock_adjustment with the delta (never the final value).
  Future<LocalProduct> adjustStock(String id, int delta) async {
    final product = await getProductById(id);
    if (product == null) {
      throw Exception('Product not found');
    }

    final newQty = product.quantity + delta;
    if (newQty < 0) {
      throw Exception('Stock cannot go below zero.');
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.localProducts)..where((t) => t.id.equals(id))).write(
      LocalProductsCompanion(quantity: Value(newQty), updatedAt: Value(now)),
    );

    // Enqueue with DELTA, not final value
    await _syncQueue.enqueue(
      operationType: 'stock_adjustment',
      payloadJson: jsonEncode({'product_id': id, 'delta': delta}),
    );

    return (await getProductById(id))!;
  }

  /// Batch insert products from the initial pull (no sync queue entries needed).
  Future<void> bulkInsertProducts(List<LocalProductsCompanion> products) async {
    await _db.batch((batch) {
      batch.insertAll(_db.localProducts, products);
    });
  }
}
