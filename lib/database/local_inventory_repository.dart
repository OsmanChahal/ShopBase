import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'sync_queue_repository.dart';
import '../utils/location_rules.dart';

const _uuid = Uuid();

class TransferLine {
  final String productId;
  final int quantity;
  const TransferLine(this.productId, this.quantity);
}

/// Local-first inventory management. Every method writes to Drift first and
/// enqueues a sync operation. Permission checks happen in the actions layer
/// and on the server (RLS), so a refused change is rolled back after sync.
class LocalInventoryRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;
  LocalInventoryRepository(this._db, this._syncQueue);

  Future<List<LocalInventory>> getInventories(
    String businessId, {
    bool includeArchived = false,
  }) {
    return (_db.select(_db.localInventories)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                (includeArchived
                    ? const Constant(true)
                    : t.isArchived.equals(false)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Required and at most [kLocationNameMaxLength] characters. The forms
  /// check this too; enforcing it here covers every caller.
  void _checkNameLength(String clean) {
    if (clean.isEmpty) throw Exception('Inventory name is required');
    if (clean.length > kLocationNameMaxLength) {
      throw Exception('Keep the name under $kLocationNameMaxLength characters');
    }
  }

  Future<void> _ensureNameFree(
    String businessId,
    String name, {
    String? exceptId,
  }) async {
    final clash =
        await (_db.select(_db.localInventories)..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.name.lower().equals(name.toLowerCase()),
            ))
            .get();
    if (clash.any((i) => i.id != exceptId)) {
      throw Exception('An inventory with this name already exists');
    }
  }

  Future<String> createInventory({
    required String businessId,
    required String name,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      final clean = name.trim();
      _checkNameLength(clean);
      await _ensureNameFree(businessId, clean);

      final id = _uuid.v4();
      final now = DateTime.now().toUtc();
      await _db
          .into(_db.localInventories)
          .insert(
            LocalInventoriesCompanion.insert(
              id: id,
              businessId: businessId,
              name: clean,
              createdAt: now,
              updatedAt: Value(now),
            ),
          );
      await _syncQueue.enqueue(
        operationType: 'inventory_upsert',
        payloadJson: jsonEncode({
          'id': id,
          'business_id': businessId,
          'name': clean,
          'updated_at': now.toIso8601String(),
          // created_at is deliberately NOT sent: the server decides which
          // inventory is the oldest ("Main").
        }),
      );
      return id;
    });
  }

  Future<void> renameInventory(String id, String newName) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      final clean = newName.trim();
      _checkNameLength(clean);
      final inv = await (_db.select(
        _db.localInventories,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (inv == null) throw Exception('Inventory not found');
      await _ensureNameFree(inv.businessId, clean, exceptId: id);

      final now = DateTime.now().toUtc();
      await (_db.update(
        _db.localInventories,
      )..where((t) => t.id.equals(id))).write(
        LocalInventoriesCompanion(name: Value(clean), updatedAt: Value(now)),
      );
      await _syncQueue.enqueue(
        operationType: 'inventory_upsert',
        payloadJson: jsonEncode({
          'id': id,
          'business_id': inv.businessId,
          'name': clean,
          'updated_at': now.toIso8601String(),
        }),
      );
    });
  }

  Future<void> archiveInventory(String id) => _setArchived(id, true);
  Future<void> unarchiveInventory(String id) => _setArchived(id, false);

  Future<void> _setArchived(String id, bool archive) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      final inv = await (_db.select(
        _db.localInventories,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (inv == null) throw Exception('Inventory not found');
      if (inv.isArchived == archive) return;

      if (archive) {
        final active = await getInventories(inv.businessId);
        if (active.length <= 1) {
          throw Exception('Cannot archive the last active inventory');
        }
        final sum = _db.localInventoryStock.quantity.sum();
        final row =
            await (_db.selectOnly(_db.localInventoryStock)
                  ..addColumns([sum])
                  ..where(_db.localInventoryStock.inventoryId.equals(id)))
                .getSingle();
        final units = row.read(sum) ?? 0;
        if (units > 0) {
          throw Exception(
            'Inventory still holds $units units. Transfer them out first',
          );
        }
      }

      await (_db.update(
        _db.localInventories,
      )..where((t) => t.id.equals(id))).write(
        LocalInventoriesCompanion(
          isArchived: Value(archive),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await _syncQueue.enqueue(
        operationType: 'inventory_archive',
        payloadJson: jsonEncode({'inventory_id': id, 'archive': archive}),
      );
    });
  }

  /// pos/edit imply view (same rule as the server's check constraint).
  Future<void> setInventoryAccess({
    required String inventoryId,
    required String userId,
    required bool canPos,
    required bool canView,
    required bool canEdit,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      if (!canPos && !canView && !canEdit) {
        return removeInventoryAccess(inventoryId: inventoryId, userId: userId);
      }
      final view = canView || canPos || canEdit;
      await _db
          .into(_db.localInventoryAccess)
          .insertOnConflictUpdate(
            LocalInventoryAccessCompanion.insert(
              inventoryId: inventoryId,
              userId: userId,
              canPos: Value(canPos),
              canView: Value(view),
              canEdit: Value(canEdit),
            ),
          );
      await _syncQueue.enqueue(
        operationType: 'inventory_access_upsert',
        payloadJson: jsonEncode({
          'inventory_id': inventoryId,
          'user_id': userId,
          'can_pos': canPos,
          'can_view': view,
          'can_edit': canEdit,
        }),
      );
    });
  }

  Future<void> removeInventoryAccess({
    required String inventoryId,
    required String userId,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      await (_db.delete(_db.localInventoryAccess)..where(
            (t) => t.inventoryId.equals(inventoryId) & t.userId.equals(userId),
          ))
          .go();
      await _syncQueue.enqueue(
        operationType: 'inventory_access_delete',
        payloadJson: jsonEncode({'inventory_id': inventoryId, 'user_id': userId}),
      );
    });
  }

  /// Instant transfer: validates, moves stock and writes the history row
  /// locally, then queues ONE operation. Destination keeps its own prices if
  /// it already stocks the product; otherwise the source prices are copied.
  Future<String> transferStock({
    required String businessId,
    required String fromInventoryId,
    required String toInventoryId,
    required List<TransferLine> items,
    String? createdBy,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      if (fromInventoryId == toInventoryId) {
        throw Exception('Source and destination must differ');
      }
      if (items.isEmpty) throw Exception('No items to transfer');

      final merged = <String, int>{};
      for (final i in items) {
        if (i.quantity <= 0) throw Exception('Quantities must be above 0');
        merged[i.productId] = (merged[i.productId] ?? 0) + i.quantity;
      }

      final transferId = _uuid.v4();
      final now = DateTime.now().toUtc();

      await _db.transaction(() async {
        final invs = await (_db.select(
          _db.localInventories,
        )..where((t) => t.id.isIn([fromInventoryId, toInventoryId]))).get();
        if (invs.length != 2 || invs.any((i) => i.isArchived)) {
          throw Exception('Inventory not found or archived');
        }

        // 1) Check everything before changing anything
        final sources = <String, LocalStockRow>{};
        final names = <String, String>{};
        for (final e in merged.entries) {
          final src =
              await (_db.select(_db.localInventoryStock)..where(
                    (t) =>
                        t.productId.equals(e.key) &
                        t.inventoryId.equals(fromInventoryId),
                  ))
                  .getSingleOrNull();
          final product = await (_db.select(
            _db.localProducts,
          )..where((t) => t.id.equals(e.key))).getSingleOrNull();
          final name = product?.name ?? e.key;
          if (src == null || src.quantity < e.value) {
            throw Exception(
              'Insufficient stock for "$name": have ${src?.quantity ?? 0}, need ${e.value}',
            );
          }
          sources[e.key] = src;
          names[e.key] = name;
        }

        // 2) Apply
        for (final e in merged.entries) {
          final src = sources[e.key]!;
          await (_db.update(_db.localInventoryStock)..where(
                (t) =>
                    t.productId.equals(e.key) &
                    t.inventoryId.equals(fromInventoryId),
              ))
              .write(
                LocalInventoryStockCompanion(
                  quantity: Value(src.quantity - e.value),
                ),
              );

          final dest =
              await (_db.select(_db.localInventoryStock)..where(
                    (t) =>
                        t.productId.equals(e.key) &
                        t.inventoryId.equals(toInventoryId),
                  ))
                  .getSingleOrNull();
          if (dest == null) {
            await _db
                .into(_db.localInventoryStock)
                .insert(
                  LocalInventoryStockCompanion.insert(
                    productId: e.key,
                    inventoryId: toInventoryId,
                    quantity: Value(e.value),
                    sellPriceUsd: src.sellPriceUsd,
                    costPriceUsd: src.costPriceUsd,
                    lowStockThreshold: Value(src.lowStockThreshold),
                    updatedAt: Value(now),
                  ),
                );
          } else {
            await (_db.update(_db.localInventoryStock)..where(
                  (t) =>
                      t.productId.equals(e.key) &
                      t.inventoryId.equals(toInventoryId),
                ))
                .write(
                  LocalInventoryStockCompanion(
                    quantity: Value(dest.quantity + e.value),
                  ),
                );
          }

          await _db
              .into(_db.localStockTransferItems)
              .insert(
                LocalStockTransferItemsCompanion.insert(
                  id: _uuid.v4(),
                  transferId: transferId,
                  productId: Value(e.key),
                  quantity: e.value,
                  productNameSnapshot: names[e.key]!,
                ),
              );
        }

        await _db
            .into(_db.localStockTransfers)
            .insert(
              LocalStockTransfersCompanion.insert(
                id: transferId,
                businessId: businessId,
                fromInventoryId: fromInventoryId,
                toInventoryId: toInventoryId,
                createdBy: Value(createdBy),
                createdAt: now,
              ),
            );
      });

      await _syncQueue.enqueue(
        operationType: 'stock_transfer',
        payloadJson: jsonEncode({
          'transfer_id': transferId,
          'from_inventory_id': fromInventoryId,
          'to_inventory_id': toInventoryId,
          'items': merged.entries
              .map((e) => {'product_id': e.key, 'quantity': e.value})
              .toList(),
        }),
      );
      return transferId;
    });
  }
}
