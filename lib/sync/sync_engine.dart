import 'dart:convert';
import 'dart:developer' as dev;
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../database/sync_queue_repository.dart';

class SyncEngine {
  final SyncQueueRepository _queueRepo;
  final SupabaseClient _supabase;
  final AppDatabase _db;

  SyncEngine(this._queueRepo, this._supabase, this._db);

  /// Triggers full sync: Push pending local changes, then Pull remote updates.
  Future<void> sync(String businessId) async {
    dev.log('[SyncEngine] Starting sync for business: $businessId');
    await _push();
    await _pull(businessId);
    dev.log('[SyncEngine] Sync complete for business: $businessId');
  }

  // ── PUSH PHASE ─────────────────────────────────────────────────────────────

  Future<void> _push() async {
    final entries = await _queueRepo.getProcessableEntries();
    if (entries.isEmpty) {
      dev.log('[SyncEngine Push] No pending operations to push.');
      return;
    }

    dev.log(
      '[SyncEngine Push] Processing ${entries.length} pending operations.',
    );

    for (final entry in entries) {
      try {
        final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        switch (entry.operationType) {
          case 'product_upsert':
            await _handleProductUpsert(payload);
            break;
          case 'product_delete':
            await _handleProductDelete(payload);
            break;
          case 'stock_adjustment':
            await _handleStockAdjustment(payload);
            break;
          case 'sale':
            await _handleSale(payload);
            break;
          case 'customer_upsert':
            await _handleCustomerUpsert(payload);
            break;
          case 'customer_delete':
            await _handleCustomerDelete(payload);
            break;
          default:
            dev.log(
              '[SyncEngine Push] Unknown operation type: ${entry.operationType}',
            );
        }
        await _queueRepo.markSynced(entry.id);
      } catch (e, st) {
        dev.log(
          '[SyncEngine Push] Failed to process entry ${entry.id}: $e\n$st',
        );
        await _queueRepo.markFailed(entry.id, e.toString());
      }
    }
  }

  Future<void> _handleProductUpsert(Map<String, dynamic> payload) async {
    // Strip quantity field so stock adjustments handle quantity
    final map = Map<String, dynamic>.from(payload)..remove('quantity');
    await _supabase.from('products').upsert(map);
  }

  Future<void> _handleProductDelete(Map<String, dynamic> payload) async {
    final productId = payload['product_id'] ?? payload['id'];
    if (productId != null) {
      await _supabase.from('products').delete().eq('id', productId);
    }
  }

  Future<void> _handleStockAdjustment(Map<String, dynamic> payload) async {
    final productId = payload['product_id'] as String;
    final delta = payload['delta'] as int;
    final operationId = payload['operation_id'] as String;
    await _supabase.rpc(
      'adjust_stock',
      params: {
        'p_product_id': productId,
        'p_delta': delta,
        'p_operation_id': operationId,
      },
    );
  }

  Future<void> _handleSale(Map<String, dynamic> payload) async {
    final saleData = payload['sale'] as Map<String, dynamic>;
    final itemsData = (payload['items'] as List).cast<Map<String, dynamic>>();
    final stockDeltas =
        (payload['stock_deltas'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // 1. Upsert sale header
    await _supabase.from('sales').upsert(saleData);

    // 2. Upsert sale items
    if (itemsData.isNotEmpty) {
      await _supabase.from('sale_items').upsert(itemsData);
    }

    // 3. Apply stock deltas for each item
    for (final delta in stockDeltas) {
      final productId = delta['product_id'] as String;
      final qtyDelta = delta['delta'] as int;
      final operationId = delta['operation_id'] as String;
      await _supabase.rpc(
        'adjust_stock',
        params: {
          'p_product_id': productId,
          'p_delta': qtyDelta,
          'p_operation_id': operationId,
        },
      );
    }
  }

  Future<void> _handleCustomerUpsert(Map<String, dynamic> payload) async {
    await _supabase.from('customers').upsert(payload);
  }

  Future<void> _handleCustomerDelete(Map<String, dynamic> payload) async {
    final customerId = payload['customer_id'] ?? payload['id'];
    if (customerId != null) {
      await _supabase.from('customers').delete().eq('id', customerId);
    }
  }

  // ── PULL PHASE ─────────────────────────────────────────────────────────────

  Future<void> _pull(String businessId) async {
    final lastPullAt = await _getLastPullAt(businessId);
    final now = DateTime.now().toUtc();
    final overlapSince = lastPullAt?.subtract(const Duration(minutes: 2));

    dev.log('[SyncEngine Pull] Pulling updates since: $lastPullAt');

    await _pullInventories(businessId, overlapSince);
    await _pullProducts(businessId, lastPullAt);
    await _pullInventoryStock(businessId, overlapSince);
    await _pullInventoryAccess();
    await _pullTransfers(businessId, overlapSince);
    await _pullCustomers(businessId, lastPullAt);

    dev.log(
      '[SyncEngine Pull] local inventories='
      '${(await _db.select(_db.localInventories).get()).length}, '
      'stock=${(await _db.select(_db.localInventoryStock).get()).length}, '
      'access=${(await _db.select(_db.localInventoryAccess).get()).length}, '
      'transfers=${(await _db.select(_db.localStockTransfers).get()).length}',
    );

    await _updateLastPullAt(businessId, now);
  }

  Future<DateTime?> _getLastPullAt(String businessId) async {
    final row = await (_db.select(
      _db.syncMetadataEntries,
    )..where((t) => t.businessId.equals(businessId))).getSingleOrNull();
    return row?.lastPullAt;
  }

  Future<void> _updateLastPullAt(String businessId, DateTime timestamp) async {
    await _db
        .into(_db.syncMetadataEntries)
        .insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            businessId: businessId,
            lastPullAt: timestamp,
          ),
        );
  }

  Future<void> _pullProducts(String businessId, DateTime? lastPullAt) async {
    dynamic query = _supabase
        .from('products')
        .select()
        .eq('business_id', businessId);
    if (lastPullAt != null) {
      query = query.gt('updated_at', lastPullAt.toIso8601String());
    }

    final List<dynamic> remoteProducts = await query;
    if (remoteProducts.isEmpty) return;

    dev.log(
      '[SyncEngine Pull] Pulled ${remoteProducts.length} product updates.',
    );

    for (final raw in remoteProducts) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'] as String;
      final serverUpdatedAt = DateTime.parse(item['updated_at'] as String);

      final local = await (_db.select(
        _db.localProducts,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (local == null) {
        // Product doesn't exist locally — insert
        await _db
            .into(_db.localProducts)
            .insert(
              LocalProductsCompanion.insert(
                id: id,
                businessId: businessId,
                name: item['name'] as String,
                sku: Value(item['sku'] as String?),
                category: Value(item['category'] as String?),
                costPriceUsd: (item['cost_price_usd'] as num).toDouble(),
                sellPriceUsd: (item['sell_price_usd'] as num).toDouble(),
                quantity: item['quantity'] as int,
                lowStockThreshold: Value(
                  item['low_stock_threshold'] as int? ?? 5,
                ),
                updatedAt: Value(serverUpdatedAt),
                lastSyncedAt: Value(DateTime.now().toUtc()),
              ),
            );
      } else {
        // Product exists locally:
        // Server's quantity is always authoritative after push deltas.
        // For non-quantity fields, use Last-Write-Wins based on updatedAt.
        final shouldUpdateNonQuantity =
            local.updatedAt == null ||
            serverUpdatedAt.isAfter(local.updatedAt!);

        await (_db.update(
          _db.localProducts,
        )..where((t) => t.id.equals(id))).write(
          LocalProductsCompanion(
            quantity: Value(item['quantity'] as int),
            name: shouldUpdateNonQuantity
                ? Value(item['name'] as String)
                : const Value.absent(),
            sku: shouldUpdateNonQuantity
                ? Value(item['sku'] as String?)
                : const Value.absent(),
            category: shouldUpdateNonQuantity
                ? Value(item['category'] as String?)
                : const Value.absent(),
            costPriceUsd: shouldUpdateNonQuantity
                ? Value((item['cost_price_usd'] as num).toDouble())
                : const Value.absent(),
            sellPriceUsd: shouldUpdateNonQuantity
                ? Value((item['sell_price_usd'] as num).toDouble())
                : const Value.absent(),
            lowStockThreshold: shouldUpdateNonQuantity
                ? Value(item['low_stock_threshold'] as int? ?? 5)
                : const Value.absent(),
            updatedAt: shouldUpdateNonQuantity
                ? Value(serverUpdatedAt)
                : const Value.absent(),
            lastSyncedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    }
  }

  Future<void> _pullCustomers(String businessId, DateTime? lastPullAt) async {
    dynamic query = _supabase
        .from('customers')
        .select()
        .eq('business_id', businessId);
    if (lastPullAt != null) {
      query = query.gt('created_at', lastPullAt.toIso8601String());
    }

    final List<dynamic> remoteCustomers = await query;
    if (remoteCustomers.isEmpty) return;

    dev.log(
      '[SyncEngine Pull] Pulled ${remoteCustomers.length} customer updates.',
    );

    for (final raw in remoteCustomers) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'] as String;
      final createdAt = DateTime.parse(item['created_at'] as String);

      await _db
          .into(_db.localCustomers)
          .insertOnConflictUpdate(
            LocalCustomersCompanion.insert(
              id: id,
              businessId: businessId,
              name: item['name'] as String,
              phone: Value(item['phone'] as String?),
              createdAt: createdAt,
              lastSyncedAt: Value(DateTime.now().toUtc()),
            ),
          );
    }
  }

  // ── NEW: multi-inventory pulls ─────────────────────────────────────────────

  /// Supabase returns at most 1000 rows per request, so page through them.
  Future<List<Map<String, dynamic>>> _fetchAllPages(
    dynamic Function() buildFiltered,
    List<String> orderBy,
  ) async {
    const pageSize = 1000;
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      dynamic q = buildFiltered();
      for (final col in orderBy) {
        q = q.order(col);
      }
      final List<dynamic> page = await q.range(from, from + pageSize - 1);
      out.addAll(page.cast<Map<String, dynamic>>());
      if (page.length < pageSize) break;
      from += pageSize;
    }
    return out;
  }

  Future<void> _pullInventories(String businessId, DateTime? since) async {
    final rows = await _fetchAllPages(() {
      dynamic q = _supabase
          .from('inventories')
          .select()
          .eq('business_id', businessId);
      if (since != null) q = q.gt('updated_at', since.toIso8601String());
      return q;
    }, ['id']);
    if (rows.isEmpty) return;
    dev.log('[SyncEngine Pull] Pulled ${rows.length} inventory updates.');

    await _db.transaction(() async {
      for (final j in rows) {
        final id = j['id'] as String;
        final serverUpdatedAt = DateTime.parse(j['updated_at'] as String);
        final local = await (_db.select(
          _db.localInventories,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        // Last-write-wins: keep a newer local edit (e.g. an unsynced rename)
        if (local?.updatedAt != null &&
            local!.updatedAt!.isAfter(serverUpdatedAt)) {
          continue;
        }
        await _db
            .into(_db.localInventories)
            .insertOnConflictUpdate(
              LocalInventoriesCompanion.insert(
                id: id,
                businessId: j['business_id'] as String,
                name: j['name'] as String,
                isArchived: Value(j['is_archived'] as bool? ?? false),
                createdAt: DateTime.parse(j['created_at'] as String),
                updatedAt: Value(serverUpdatedAt),
              ),
            );
      }
    });
  }

  Future<void> _pullInventoryStock(String businessId, DateTime? since) async {
    final inventoryIds =
        (await (_db.select(
              _db.localInventories,
            )..where((t) => t.businessId.equals(businessId))).get())
            .map((r) => r.id)
            .toList();
    if (inventoryIds.isEmpty) return;

    final rows = await _fetchAllPages(() {
      dynamic q = _supabase
          .from('inventory_stock')
          .select()
          .inFilter('inventory_id', inventoryIds);
      if (since != null) q = q.gt('updated_at', since.toIso8601String());
      return q;
    }, ['product_id', 'inventory_id']);
    if (rows.isEmpty) return;
    dev.log('[SyncEngine Pull] Pulled ${rows.length} stock rows.');

    await _db.transaction(() async {
      for (final j in rows) {
        final productId = j['product_id'] as String;
        final inventoryId = j['inventory_id'] as String;
        final serverUpdatedAt = DateTime.parse(j['updated_at'] as String);
        final qty = j['quantity'] as int;
        final sell = (j['sell_price_usd'] as num).toDouble();
        final cost = (j['cost_price_usd'] as num).toDouble();
        final threshold = j['low_stock_threshold'] as int? ?? 5;

        final local =
            await (_db.select(_db.localInventoryStock)..where(
                  (t) =>
                      t.productId.equals(productId) &
                      t.inventoryId.equals(inventoryId),
                ))
                .getSingleOrNull();

        if (local == null) {
          await _db
              .into(_db.localInventoryStock)
              .insert(
                LocalInventoryStockCompanion.insert(
                  productId: productId,
                  inventoryId: inventoryId,
                  quantity: Value(qty),
                  sellPriceUsd: sell,
                  costPriceUsd: cost,
                  lowStockThreshold: Value(threshold),
                  updatedAt: Value(serverUpdatedAt),
                ),
              );
        } else {
          // Same rule as products: quantity = server value (authoritative after
          // the push); prices/threshold = last-write-wins on updatedAt.
          final updateFields =
              local.updatedAt == null ||
              serverUpdatedAt.isAfter(local.updatedAt!);
          await (_db.update(_db.localInventoryStock)..where(
                (t) =>
                    t.productId.equals(productId) &
                    t.inventoryId.equals(inventoryId),
              ))
              .write(
                LocalInventoryStockCompanion(
                  quantity: Value(qty),
                  sellPriceUsd: updateFields
                      ? Value(sell)
                      : const Value.absent(),
                  costPriceUsd: updateFields
                      ? Value(cost)
                      : const Value.absent(),
                  lowStockThreshold: updateFields
                      ? Value(threshold)
                      : const Value.absent(),
                  updatedAt: updateFields
                      ? Value(serverUpdatedAt)
                      : const Value.absent(),
                ),
              );
        }
      }
    });
  }

  /// inventory_access has no updated_at, so it can't be pulled incrementally.
  /// It's a tiny table: replace the local copy with what the server shows
  /// this user (own rows for staff, every row for owner/admin).
  Future<void> _pullInventoryAccess() async {
    final rows = await _fetchAllPages(
      () => _supabase.from('inventory_access').select(),
      ['inventory_id', 'user_id'],
    );
    final companions = rows.map(
      (j) => LocalInventoryAccessCompanion.insert(
        inventoryId: j['inventory_id'] as String,
        userId: j['user_id'] as String,
        canPos: Value(j['can_pos'] as bool? ?? false),
        canView: Value(j['can_view'] as bool? ?? false),
        canEdit: Value(j['can_edit'] as bool? ?? false),
      ),
    );
    await _db.transaction(() async {
      await _db.delete(_db.localInventoryAccess).go();
      await _db.batch(
        (b) => b.insertAll(
          _db.localInventoryAccess,
          companions.toList(),
          mode: InsertMode.insertOrReplace,
        ),
      );
    });
  }

  Future<void> _pullTransfers(String businessId, DateTime? since) async {
    final rows = await _fetchAllPages(() {
      dynamic q = _supabase
          .from('stock_transfers')
          .select()
          .eq('business_id', businessId);
      if (since != null) q = q.gt('created_at', since.toIso8601String());
      return q;
    }, ['created_at', 'id']);
    if (rows.isEmpty) return;

    // A transfer created on THIS device already exists locally (same client UUID),
    // with its own local item rows. Skip those entirely, otherwise the server's
    // item rows (different ids) would duplicate them.
    final newHeaders = <Map<String, dynamic>>[];
    for (final j in rows) {
      final exists =
          await (_db.select(
            _db.localStockTransfers,
          )..where((t) => t.id.equals(j['id'] as String))).getSingleOrNull() !=
          null;
      if (!exists) newHeaders.add(j);
    }
    if (newHeaders.isEmpty) return;
    dev.log('[SyncEngine Pull] Pulled ${newHeaders.length} new transfers.');

    final ids = newHeaders.map((j) => j['id'] as String).toList();
    final itemRows = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 50) {
      final batch = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
      final List<dynamic> res = await _supabase
          .from('stock_transfer_items')
          .select()
          .inFilter('transfer_id', batch);
      itemRows.addAll(res.cast<Map<String, dynamic>>());
    }

    await _db.transaction(() async {
      for (final j in newHeaders) {
        await _db
            .into(_db.localStockTransfers)
            .insertOnConflictUpdate(
              LocalStockTransfersCompanion.insert(
                id: j['id'] as String,
                businessId: j['business_id'] as String,
                fromInventoryId: j['from_inventory_id'] as String,
                toInventoryId: j['to_inventory_id'] as String,
                createdBy: Value(j['created_by'] as String?),
                createdAt: DateTime.parse(j['created_at'] as String),
              ),
            );
      }
      for (final j in itemRows) {
        await _db
            .into(_db.localStockTransferItems)
            .insertOnConflictUpdate(
              LocalStockTransferItemsCompanion.insert(
                id: j['id'] as String,
                transferId: j['transfer_id'] as String,
                productId: Value(j['product_id'] as String?),
                quantity: j['quantity'] as int,
                productNameSnapshot: j['product_name_snapshot'] as String,
              ),
            );
      }
    });
  }
}
