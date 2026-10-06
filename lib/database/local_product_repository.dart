import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'sync_queue_repository.dart';

const _uuid = Uuid();

/// NEW: a catalog row joined with its stock row for one inventory.
class ProductWithStock {
  final LocalProduct product;
  final LocalStockRow stock;
  const ProductWithStock(this.product, this.stock);
}

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

  /// NEW: catalog JOIN stock for one inventory. A product appears here only if
  /// it has a stock row in that inventory. Not used by the UI until 3.3b.
  Future<List<ProductWithStock>> getProductsForInventory(
    String businessId,
    String inventoryId,
  ) async {
    final p = _db.localProducts;
    final s = _db.localInventoryStock;
    final query =
        _db.select(p).join([
            innerJoin(
              s,
              s.productId.equalsExp(p.id) & s.inventoryId.equals(inventoryId),
            ),
          ])
          ..where(p.businessId.equals(businessId))
          ..orderBy([OrderingTerm.asc(p.name)]);
    final rows = await query.get();
    return rows
        .map((r) => ProductWithStock(r.readTable(p), r.readTable(s)))
        .toList();
  }

  /// NEW: one product joined with its stock row for one inventory.
  Future<ProductWithStock?> getProductWithStock(
    String productId,
    String inventoryId,
  ) async {
    final p = _db.localProducts;
    final s = _db.localInventoryStock;
    final query = _db.select(p).join([
      innerJoin(
        s,
        s.productId.equalsExp(p.id) & s.inventoryId.equals(inventoryId),
      ),
    ])..where(p.id.equals(productId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ProductWithStock(row.readTable(p), row.readTable(s));
  }

  /// NEW: the raw stock row (used by sales for availability + cost snapshot).
  Future<LocalStockRow?> getStockRow(String productId, String inventoryId) {
    return (_db.select(_db.localInventoryStock)..where(
          (t) =>
              t.productId.equals(productId) & t.inventoryId.equals(inventoryId),
        ))
        .getSingleOrNull();
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

  /// Returns the distinct, non-empty categories already used by this
  /// business's products, sorted alphabetically. This is what makes the
  /// category list "grow" organically instead of coming from a fixed list.
  Future<List<String>> getDistinctCategories(String businessId) async {
    final query = _db.selectOnly(_db.localProducts, distinct: true)
      ..addColumns([_db.localProducts.category])
      ..where(
        _db.localProducts.businessId.equals(businessId) &
            _db.localProducts.category.isNotNull(),
      )
      ..orderBy([OrderingTerm.asc(_db.localProducts.category)]);

    final rows = await query.get();

    return rows
        .map((row) => row.read(_db.localProducts.category))
        .whereType<String>()
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Add a new product. Generates a UUID, inserts into local DB,
  /// and enqueues a product_upsert operation.
  /// CHANGED: returns the new product id. With [inventoryId] it also creates
  /// the stock row in that inventory; without it, legacy behavior.
  Future<String> addProduct({
    required String businessId,
    required String name,
    String? sku,
    String? category,
    required double costPriceUsd,
    required double sellPriceUsd,
    required int quantity,
    int lowStockThreshold = 5,
    String? inventoryId, // NEW
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await _db
          .into(_db.localProducts)
          .insert(
            LocalProductsCompanion.insert(
              id: id,
              businessId: businessId,
              name: name,
              sku: Value(sku),
              category: Value(category),
              costPriceUsd: costPriceUsd,
              sellPriceUsd: sellPriceUsd,
              // legacy mirror column: only meaningful without inventories
              quantity: inventoryId == null ? quantity : 0,
              lowStockThreshold: Value(lowStockThreshold),
              updatedAt: Value(now),
              lastSyncedAt: const Value(null),
            ),
          );
      if (inventoryId != null) {
        await _db
            .into(_db.localInventoryStock)
            .insert(
              LocalInventoryStockCompanion.insert(
                productId: id,
                inventoryId: inventoryId,
                quantity: Value(quantity),
                sellPriceUsd: sellPriceUsd,
                costPriceUsd: costPriceUsd,
                lowStockThreshold: Value(lowStockThreshold),
                updatedAt: Value(now),
              ),
            );
      }
    });

    // 1) Catalog row (prices are required by the server's NOT NULL columns)
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

    if (inventoryId != null) {
      // 2) Creates/updates this inventory's stock row on the server
      await _syncQueue.enqueue(
        operationType: 'stock_prices_update',
        payloadJson: jsonEncode({
          'product_id': id,
          'inventory_id': inventoryId,
          'sell_price_usd': sellPriceUsd,
          'cost_price_usd': costPriceUsd,
          'low_stock_threshold': lowStockThreshold,
        }),
      );
    }

    // 3) Initial quantity travels as a delta (existing rule)
    if (quantity != 0) {
      await _syncQueue.enqueue(
        operationType: 'stock_adjustment',
        payloadJson: jsonEncode({
          'product_id': id,
          if (inventoryId != null) 'inventory_id': inventoryId,
          'delta': quantity,
          'operation_id': _uuid.v4(),
          if (inventoryId != null) 'reason': 'initial',
        }),
      );
    }
    return id;
  }

  /// CHANGED: with [inventoryId], name/sku/category are shared across all
  /// inventories and prices/threshold apply to that inventory only.
  Future<void> updateProduct({
    required String id,
    required String businessId,
    required String name,
    String? sku,
    String? category,
    required double costPriceUsd,
    required double sellPriceUsd,
    required int lowStockThreshold,
    String? inventoryId, // NEW
  }) async {
    final now = DateTime.now().toUtc();

    if (inventoryId == null) {
      // ── legacy behavior, unchanged ──
      await (_db.update(
        _db.localProducts,
      )..where((t) => t.id.equals(id))).write(
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
      return;
    }

    await _db.transaction(() async {
      await (_db.update(
        _db.localProducts,
      )..where((t) => t.id.equals(id))).write(
        LocalProductsCompanion(
          name: Value(name),
          sku: Value(sku),
          category: Value(category),
          updatedAt: Value(now),
        ),
      );
      await (_db.update(_db.localInventoryStock)..where(
            (t) => t.productId.equals(id) & t.inventoryId.equals(inventoryId),
          ))
          .write(
            LocalInventoryStockCompanion(
              sellPriceUsd: Value(sellPriceUsd),
              costPriceUsd: Value(costPriceUsd),
              lowStockThreshold: Value(lowStockThreshold),
              updatedAt: Value(now),
            ),
          );
    });

    // Catalog fields only: never touches prices of other inventories
    await _syncQueue.enqueue(
      operationType: 'product_catalog_update',
      payloadJson: jsonEncode({
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'updated_at': now.toIso8601String(),
      }),
    );
    await _syncQueue.enqueue(
      operationType: 'stock_prices_update',
      payloadJson: jsonEncode({
        'product_id': id,
        'inventory_id': inventoryId,
        'sell_price_usd': sellPriceUsd,
        'cost_price_usd': costPriceUsd,
        'low_stock_threshold': lowStockThreshold,
      }),
    );
  }

  /// CHANGED: also removes this product's local stock rows (the server
  /// cascades the same way).
  Future<void> deleteProduct(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.localInventoryStock,
      )..where((t) => t.productId.equals(id))).go();
      await (_db.delete(_db.localProducts)..where((t) => t.id.equals(id))).go();
    });
    await _syncQueue.enqueue(
      operationType: 'product_delete',
      payloadJson: jsonEncode({'product_id': id}),
    );
  }

  /// CHANGED: with [inventoryId] the delta applies to that inventory's stock.
  Future<void> adjustStock(String id, int delta, {String? inventoryId}) async {
    final now = DateTime.now().toUtc();

    if (inventoryId == null) {
      // ── legacy behavior, unchanged ──
      final product = await getProductById(id);
      if (product == null) throw Exception('Product not found');
      final newQty = product.quantity + delta;
      if (newQty < 0) throw Exception('Stock cannot go below zero.');
      await (_db.update(
        _db.localProducts,
      )..where((t) => t.id.equals(id))).write(
        LocalProductsCompanion(quantity: Value(newQty), updatedAt: Value(now)),
      );
      await _syncQueue.enqueue(
        operationType: 'stock_adjustment',
        payloadJson: jsonEncode({
          'product_id': id,
          'delta': delta,
          'operation_id': _uuid.v4(),
        }),
      );
      return;
    }

    final row = await getStockRow(id, inventoryId);
    if (row == null)
      throw Exception('Product is not stocked in this inventory');
    final newQty = row.quantity + delta;
    if (newQty < 0) throw Exception('Stock cannot go below zero.');

    await (_db.update(_db.localInventoryStock)..where(
          (t) => t.productId.equals(id) & t.inventoryId.equals(inventoryId),
        ))
        .write(LocalInventoryStockCompanion(quantity: Value(newQty)));
    // NOTE: stock updatedAt is deliberately NOT touched, so a quantity change
    // never wins a price last-write-wins comparison.

    await _syncQueue.enqueue(
      operationType: 'stock_adjustment',
      payloadJson: jsonEncode({
        'product_id': id,
        'inventory_id': inventoryId,
        'delta': delta,
        'operation_id': _uuid.v4(),
        'reason': 'adjustment',
      }),
    );
  }

  /// Batch insert products from the initial pull (no sync queue entries needed).
  Future<void> bulkInsertProducts(List<LocalProductsCompanion> products) async {
    await _db.batch((batch) {
      batch.insertAll(_db.localProducts, products);
    });
  }
}
