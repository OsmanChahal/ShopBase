import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../database/sync_queue_repository.dart';

class SyncEngine {
  final SyncQueueRepository _queueRepo;
  final SupabaseClient _supabase;
  final AppDatabase _db;

  bool _needsStockReconcile = true;
  final List<String> _rejections = [];

  List<String> takeRejections() {
    final out = List<String>.from(_rejections);
    _rejections.clear();
    return out;
  }

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
      await _queueRepo.deleteOldFinished();
      return;
    }

    dev.log('[SyncEngine Push] Processing ${entries.length} operations.');

    for (final entry in entries) {
      Map<String, dynamic>? payload;
      try {
        payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        switch (entry.operationType) {
          case 'product_upsert':
            await _handleProductUpsert(payload);
            break;
          case 'product_catalog_update':
            await _handleProductCatalogUpdate(payload);
            break;
          case 'product_delete':
            await _handleProductDelete(payload);
            break;
          case 'stock_adjustment':
            await _handleStockAdjustment(payload);
            break;
          case 'stock_prices_update':
            await _handleStockPricesUpdate(payload);
            break;
          case 'stock_transfer': // NEW
            await _handleStockTransfer(payload);
            break;
          case 'inventory_upsert': // NEW
            await _supabase.from('inventories').upsert(payload);
            break;
          case 'inventory_archive': // NEW
            await _handleInventoryArchive(payload);
            break;
          case 'inventory_access_upsert': // NEW
            await _supabase
                .from('inventory_access')
                .upsert(payload, onConflict: 'inventory_id,user_id');
            break;
          case 'inventory_access_delete': // NEW
            await _supabase
                .from('inventory_access')
                .delete()
                .eq('inventory_id', payload['inventory_id'])
                .eq('user_id', payload['user_id']);
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
              '[SyncEngine Push] Unknown operation: ${entry.operationType}',
            );
        }
        await _queueRepo.markSynced(entry.id);
      } catch (e, st) {
        dev.log(
          '[SyncEngine Push] ${entry.operationType} ${entry.id}: $e\n$st',
        );
        if (_isTransient(e)) {
          // Offline / session refresh: keep it pending, keep the order, stop here.
          await _queueRepo.noteTransientError(entry.id, e.toString());
          break;
        } else if (_isPermanent(e)) {
          final msg = _friendly(e);
          await _queueRepo.markRejected(entry.id, msg);
          _rejections.add(msg);
          await _compensate(entry.operationType, payload);
        } else {
          await _queueRepo.markFailed(entry.id, e.toString());
        }
      }
    }
    await _queueRepo.deleteOldFinished();
  }

  // ── NEW: failure handling ──────────────────────────────────────────────────

  bool _isTransient(Object e) {
    if (e is SocketException || e is TimeoutException || e is AuthException) {
      return true;
    }
    final t = e.runtimeType.toString();
    return t.contains('ClientException') || t.contains('HandshakeException');
  }

  /// The server understood the request and said no (RAISE EXCEPTION, RLS,
  /// unique violation, check violation).
  bool _isPermanent(Object e) =>
      e is PostgrestException &&
      const {
        'P0001',
        '42501',
        '23505',
        '23514',
        '22023',
        '23503',
      }.contains(e.code);

  String _friendly(Object e) {
    if (e is PostgrestException) {
      if (e.code == '42501') return "You don't have permission for this change";
      if (e.code == '23505') return 'That already exists';
      return e.message;
    }
    return e.toString();
  }

  /// Undo the local optimistic effect of an operation the server refused.
  Future<void> _compensate(String type, Map<String, dynamic>? payload) async {
    switch (type) {
      case 'stock_adjustment':
      case 'stock_prices_update':
      case 'sale':
        _needsStockReconcile = true;
        break;
      case 'stock_transfer':
        _needsStockReconcile = true;
        final id = payload?['transfer_id'] as String?;
        if (id != null) {
          await _db.transaction(() async {
            await (_db.delete(
              _db.localStockTransferItems,
            )..where((t) => t.transferId.equals(id))).go();
            await (_db.delete(
              _db.localStockTransfers,
            )..where((t) => t.id.equals(id))).go();
          });
        }
        break;
      case 'inventory_upsert':
      case 'inventory_archive':
        final id = (payload?['id'] ?? payload?['inventory_id']) as String?;
        if (id != null) await _restoreInventoryFromServer(id);
        break;
    }
  }

  Future<void> _restoreInventoryFromServer(String id) async {
    try {
      final j = await _supabase
          .from('inventories')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (j == null) {
        // Never existed on the server (e.g. refused create): remove locally
        await _db.transaction(() async {
          await (_db.delete(
            _db.localInventoryStock,
          )..where((t) => t.inventoryId.equals(id))).go();
          await (_db.delete(
            _db.localInventoryAccess,
          )..where((t) => t.inventoryId.equals(id))).go();
          await (_db.delete(
            _db.localInventories,
          )..where((t) => t.id.equals(id))).go();
        });
      } else {
        await _db
            .into(_db.localInventories)
            .insertOnConflictUpdate(
              LocalInventoriesCompanion.insert(
                id: id,
                businessId: j['business_id'] as String,
                name: j['name'] as String,
                isArchived: Value(j['is_archived'] as bool? ?? false),
                createdAt: DateTime.parse(j['created_at'] as String),
                updatedAt: Value(DateTime.parse(j['updated_at'] as String)),
              ),
            );
      }
    } catch (e) {
      dev.log('[SyncEngine] could not restore inventory $id: $e');
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

  Future<void> _handleProductCatalogUpdate(Map<String, dynamic> payload) async {
    final id = payload['id'] as String;
    final map = Map<String, dynamic>.from(payload)..remove('id');
    await _supabase.from('products').update(map).eq('id', id);
  }

  Future<void> _handleStockPricesUpdate(Map<String, dynamic> payload) async {
    await _supabase.rpc(
      'set_stock_prices',
      params: {
        'p_product_id': payload['product_id'],
        'p_inventory_id': payload['inventory_id'],
        'p_sell': payload['sell_price_usd'],
        'p_cost': payload['cost_price_usd'],
        'p_threshold': payload['low_stock_threshold'],
      },
    );
  }

  Future<void> _handleStockTransfer(Map<String, dynamic> p) async {
    await _supabase.rpc(
      'transfer_stock',
      params: {
        'p_transfer_id': p['transfer_id'],
        'p_from': p['from_inventory_id'],
        'p_to': p['to_inventory_id'],
        'p_items': p['items'],
      },
    );
  }

  Future<void> _handleInventoryArchive(Map<String, dynamic> p) async {
    await _supabase.rpc(
      (p['archive'] as bool? ?? true)
          ? 'archive_inventory'
          : 'unarchive_inventory',
      params: {'p_inventory_id': p['inventory_id']},
    );
  }

  Future<void> _handleStockAdjustment(Map<String, dynamic> payload) async {
    final productId = payload['product_id'] as String;
    final delta = payload['delta'] as int;
    final operationId = payload['operation_id'] as String;
    final inventoryId = payload['inventory_id'] as String?;

    if (inventoryId == null) {
      // Operations queued by the old app version: routed to Main by the server
      await _supabase.rpc(
        'adjust_stock',
        params: {
          'p_product_id': productId,
          'p_delta': delta,
          'p_operation_id': operationId,
        },
      );
    } else {
      await _supabase.rpc(
        'adjust_stock',
        params: {
          'p_product_id': productId,
          'p_inventory_id': inventoryId,
          'p_delta': delta,
          'p_operation_id': operationId,
          'p_reason': payload['reason'] as String? ?? 'adjustment',
        },
      );
    }
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
      final inventoryId = delta['inventory_id'] as String?;
      if (inventoryId == null) {
        await _supabase.rpc(
          'adjust_stock',
          params: {
            'p_product_id': productId,
            'p_delta': qtyDelta,
            'p_operation_id': operationId,
          },
        );
      } else {
        await _supabase.rpc(
          'adjust_stock',
          params: {
            'p_product_id': productId,
            'p_inventory_id': inventoryId,
            'p_delta': qtyDelta,
            'p_operation_id': operationId,
            'p_reason': delta['reason'] as String? ?? 'sale',
          },
        );
      }
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
    final reconcile =
        _needsStockReconcile && (await _queueRepo.getProcessableCount()) == 0;
    await _pullInventoryStock(businessId, overlapSince, reconcile: reconcile);
    if (reconcile) _needsStockReconcile = false;
    if ((await _queueRepo.getProcessableCount()) == 0) {
      await _pullInventoryAccess();
    }
    await _pullTransfers(businessId, overlapSince);
    await _pullCustomers(businessId, lastPullAt);

    await _updateLastPullAt(businessId, now);
  }
  // Future<void> _pull(String businessId) async {
  //   final lastPullAt = await _getLastPullAt(businessId);
  //   final now = DateTime.now().toUtc();
  //   final overlapSince = lastPullAt?.subtract(const Duration(minutes: 2));

  //   dev.log('[SyncEngine Pull] Pulling updates since: $lastPullAt');

  //   final queueEmpty = (await _queueRepo.getProcessableCount()) == 0;

  //   // Access first: if it changed, locations and stock must be re-read in full
  //   var accessChanged = false;
  //   if (queueEmpty) accessChanged = await _pullInventoryAccess();

  //   // Locations are a tiny table: always pull them in full, because a grant
  //   // changes what is visible without changing the row's updated_at.
  //   await _pullInventories(businessId, null);
  //   await _pullProducts(businessId, lastPullAt);

  //   final reconcile = (_needsStockReconcile || accessChanged) && queueEmpty;
  //   await _pullInventoryStock(businessId, overlapSince, reconcile: reconcile);
  //   if (reconcile) _needsStockReconcile = false;

  //   await _pullTransfers(businessId, overlapSince);
  //   await _pullCustomers(businessId, lastPullAt);

  //   await _updateLastPullAt(businessId, now);
  // }

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

  Future<void> _pullInventoryStock(
    String businessId,
    DateTime? since, {
    bool reconcile = false,
  }) async {
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
      if (!reconcile && since != null) {
        q = q.gt('updated_at', since.toIso8601String());
      }
      return q;
    }, ['product_id', 'inventory_id']);
    if (rows.isEmpty) return; // never delete everything on an empty answer
    dev.log(
      '[SyncEngine Pull] ${rows.length} stock rows (reconcile=$reconcile).',
    );

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
          // Reconcile = server is the truth (queue is empty). Otherwise:
          // quantity = server value, prices = last-write-wins.
          final updateFields =
              reconcile ||
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

      if (reconcile) {
        // Drop local stock rows the server doesn't have (rejected transfers
        // into a new inventory, products deleted on another device...)
        final serverKeys = rows
            .map((j) => '${j['product_id']}|${j['inventory_id']}')
            .toSet();
        final locals = await (_db.select(
          _db.localInventoryStock,
        )..where((t) => t.inventoryId.isIn(inventoryIds))).get();
        for (final l in locals) {
          if (!serverKeys.contains('${l.productId}|${l.inventoryId}')) {
            await (_db.delete(_db.localInventoryStock)..where(
                  (t) =>
                      t.productId.equals(l.productId) &
                      t.inventoryId.equals(l.inventoryId),
                ))
                .go();
          }
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
  // Future<bool> _pullInventoryAccess() async {
  //   final rows = await _fetchAllPages(
  //     () => _supabase.from('inventory_access').select(),
  //     ['inventory_id', 'user_id'],
  //   );
  //   String key(String i, String u, bool p, bool v, bool e) => '$i|$u|$p|$v|$e';

  //   final before = (await _db.select(_db.localInventoryAccess).get())
  //       .map(
  //         (r) => key(r.inventoryId, r.userId, r.canPos, r.canView, r.canEdit),
  //       )
  //       .toSet();
  //   final after = rows
  //       .map(
  //         (j) => key(
  //           j['inventory_id'] as String,
  //           j['user_id'] as String,
  //           j['can_pos'] as bool? ?? false,
  //           j['can_view'] as bool? ?? false,
  //           j['can_edit'] as bool? ?? false,
  //         ),
  //       )
  //       .toSet();

  //   final companions = rows.map(
  //     (j) => LocalInventoryAccessCompanion.insert(
  //       inventoryId: j['inventory_id'] as String,
  //       userId: j['user_id'] as String,
  //       canPos: Value(j['can_pos'] as bool? ?? false),
  //       canView: Value(j['can_view'] as bool? ?? false),
  //       canEdit: Value(j['can_edit'] as bool? ?? false),
  //     ),
  //   );
  //   await _db.transaction(() async {
  //     await _db.delete(_db.localInventoryAccess).go();
  //     await _db.batch(
  //       (b) => b.insertAll(
  //         _db.localInventoryAccess,
  //         companions.toList(),
  //         mode: InsertMode.insertOrReplace,
  //       ),
  //     );
  //   });

  //   return before.length != after.length || !before.containsAll(after);
  // }

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
