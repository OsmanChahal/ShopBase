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

    dev.log('[SyncEngine Push] Processing ${entries.length} pending operations.');

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
          default:
            dev.log('[SyncEngine Push] Unknown operation type: ${entry.operationType}');
        }
        await _queueRepo.markSynced(entry.id);
      } catch (e, st) {
        dev.log('[SyncEngine Push] Failed to process entry ${entry.id}: $e\n$st');
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
    await _supabase.rpc('adjust_stock', params: {
      'p_product_id': productId,
      'p_delta': delta,
    });
  }

  Future<void> _handleSale(Map<String, dynamic> payload) async {
    final saleData = payload['sale'] as Map<String, dynamic>;
    final itemsData = (payload['items'] as List).cast<Map<String, dynamic>>();
    final stockDeltas = (payload['stock_deltas'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
      await _supabase.rpc('adjust_stock', params: {
        'p_product_id': productId,
        'p_delta': qtyDelta,
      });
    }
  }

  Future<void> _handleCustomerUpsert(Map<String, dynamic> payload) async {
    await _supabase.from('customers').upsert(payload);
  }

  // ── PULL PHASE ─────────────────────────────────────────────────────────────

  Future<void> _pull(String businessId) async {
    final lastPullAt = await _getLastPullAt(businessId);
    final now = DateTime.now().toUtc();

    dev.log('[SyncEngine Pull] Pulling updates since: $lastPullAt');

    await _pullProducts(businessId, lastPullAt);
    await _pullCustomers(businessId, lastPullAt);

    await _updateLastPullAt(businessId, now);
  }

  Future<DateTime?> _getLastPullAt(String businessId) async {
    final row = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
    return row?.lastPullAt;
  }

  Future<void> _updateLastPullAt(String businessId, DateTime timestamp) async {
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            businessId: businessId,
            lastPullAt: timestamp,
          ),
        );
  }

  Future<void> _pullProducts(String businessId, DateTime? lastPullAt) async {
    dynamic query = _supabase.from('products').select().eq('business_id', businessId);
    if (lastPullAt != null) {
      query = query.gt('updated_at', lastPullAt.toIso8601String());
    }

    final List<dynamic> remoteProducts = await query;
    if (remoteProducts.isEmpty) return;

    dev.log('[SyncEngine Pull] Pulled ${remoteProducts.length} product updates.');

    for (final raw in remoteProducts) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'] as String;
      final serverUpdatedAt = DateTime.parse(item['updated_at'] as String);

      final local = await (_db.select(_db.localProducts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      if (local == null) {
        // Product doesn't exist locally — insert
        await _db.into(_db.localProducts).insert(
              LocalProductsCompanion.insert(
                id: id,
                businessId: businessId,
                name: item['name'] as String,
                sku: Value(item['sku'] as String?),
                category: Value(item['category'] as String?),
                costPriceUsd: (item['cost_price_usd'] as num).toDouble(),
                sellPriceUsd: (item['sell_price_usd'] as num).toDouble(),
                quantity: item['quantity'] as int,
                lowStockThreshold: Value(item['low_stock_threshold'] as int? ?? 5),
                updatedAt: Value(serverUpdatedAt),
                lastSyncedAt: Value(DateTime.now().toUtc()),
              ),
            );
      } else {
        // Product exists locally:
        // Server's quantity is always authoritative after push deltas.
        // For non-quantity fields, use Last-Write-Wins based on updatedAt.
        final shouldUpdateNonQuantity = local.updatedAt == null ||
            serverUpdatedAt.isAfter(local.updatedAt!);

        await (_db.update(_db.localProducts)..where((t) => t.id.equals(id)))
            .write(LocalProductsCompanion(
          quantity: Value(item['quantity'] as int),
          name: shouldUpdateNonQuantity ? Value(item['name'] as String) : const Value.absent(),
          sku: shouldUpdateNonQuantity ? Value(item['sku'] as String?) : const Value.absent(),
          category: shouldUpdateNonQuantity ? Value(item['category'] as String?) : const Value.absent(),
          costPriceUsd: shouldUpdateNonQuantity ? Value((item['cost_price_usd'] as num).toDouble()) : const Value.absent(),
          sellPriceUsd: shouldUpdateNonQuantity ? Value((item['sell_price_usd'] as num).toDouble()) : const Value.absent(),
          lowStockThreshold: shouldUpdateNonQuantity ? Value(item['low_stock_threshold'] as int? ?? 5) : const Value.absent(),
          updatedAt: shouldUpdateNonQuantity ? Value(serverUpdatedAt) : const Value.absent(),
          lastSyncedAt: Value(DateTime.now().toUtc()),
        ));
      }
    }
  }

  Future<void> _pullCustomers(String businessId, DateTime? lastPullAt) async {
    dynamic query = _supabase.from('customers').select().eq('business_id', businessId);
    if (lastPullAt != null) {
      query = query.gt('created_at', lastPullAt.toIso8601String());
    }

    final List<dynamic> remoteCustomers = await query;
    if (remoteCustomers.isEmpty) return;

    dev.log('[SyncEngine Pull] Pulled ${remoteCustomers.length} customer updates.');

    for (final raw in remoteCustomers) {
      final item = raw as Map<String, dynamic>;
      final id = item['id'] as String;
      final createdAt = DateTime.parse(item['created_at'] as String);

      await _db.into(_db.localCustomers).insertOnConflictUpdate(
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
}
