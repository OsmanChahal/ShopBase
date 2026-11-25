import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'remote_mappers.dart';

/// Applies rows fetched from Supabase to the local database during sync.
///
/// Kept separate from [SyncEngine] (which does the fetching) so the merge
/// rules can be tested against an in-memory database.
///
/// Safety rules shared by every method:
/// - An empty server answer never deletes local data (it may be a permission
///   or network glitch rather than "everything was deleted").
/// - Methods that delete or overwrite local rows must only be called when the
///   sync queue has nothing left to push, so unsent local changes are never
///   lost. Sales are only ever added, so they are safe at any time.
class RemoteMerge {
  final AppDatabase _db;
  RemoteMerge(this._db);

  static const _chunk = 500; // stays well under SQLite's variable limit

  // ── Sales (add-only: sales are never edited after checkout) ──────────────

  Future<Set<String>> localSaleIds(String businessId) async {
    final rows = await (_db.selectOnly(_db.localSales)
          ..addColumns([_db.localSales.id])
          ..where(_db.localSales.businessId.equals(businessId)))
        .get();
    return rows.map((r) => r.read(_db.localSales.id)!).toSet();
  }

  /// Inserts the given server sales and their items, skipping any sale that
  /// already exists locally. Returns how many sales were added.
  Future<int> insertMissingSales(
    String businessId,
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> items,
  ) async {
    if (sales.isEmpty) return 0;
    final existing = await localSaleIds(businessId);
    final newSales =
        sales.where((s) => !existing.contains(s['id'] as String)).toList();
    if (newSales.isEmpty) return 0;
    final newIds = newSales.map((s) => s['id'] as String).toSet();
    final newItems =
        items.where((i) => newIds.contains(i['sale_id'] as String)).toList();

    await _db.batch((b) {
      b.insertAll(
        _db.localSales,
        newSales.map(saleFromRemote).toList(),
        mode: InsertMode.insertOrIgnore,
      );
      b.insertAll(
        _db.localSaleItems,
        newItems.map(saleItemFromRemote).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
    return newSales.length;
  }

  // ── Customers (full mirror) ─────────────────────────────────────────────

  /// Makes the local customers of [businessId] match [serverCustomers]:
  /// edits from other devices are applied and customers deleted on the server
  /// are removed. Does nothing if [serverCustomers] is empty.
  ///
  /// Only call when the sync queue is empty.
  Future<void> mirrorCustomers(
    String businessId,
    List<Map<String, dynamic>> serverCustomers, {
    required DateTime syncedAt,
  }) async {
    if (serverCustomers.isEmpty) return;
    final serverIds = serverCustomers.map((c) => c['id'] as String).toSet();

    await _db.transaction(() async {
      for (final c in serverCustomers) {
        await _db
            .into(_db.localCustomers)
            .insertOnConflictUpdate(customerFromRemote(c, syncedAt: syncedAt));
      }
      final local = await (_db.select(_db.localCustomers)
            ..where((t) => t.businessId.equals(businessId)))
          .get();
      final gone =
          local.map((c) => c.id).where((id) => !serverIds.contains(id)).toList();
      for (var i = 0; i < gone.length; i += _chunk) {
        final part = gone.sublist(i, (i + _chunk).clamp(0, gone.length));
        await (_db.delete(_db.localCustomers)..where((t) => t.id.isIn(part)))
            .go();
      }
    });
  }

  // ── Products (deletes + restores; field updates use the normal pull) ─────

  Future<Set<String>> localProductIds(String businessId) async {
    final rows = await (_db.selectOnly(_db.localProducts)
          ..addColumns([_db.localProducts.id])
          ..where(_db.localProducts.businessId.equals(businessId)))
        .get();
    return rows.map((r) => r.read(_db.localProducts.id)!).toSet();
  }

  /// Removes local products of [businessId] (and their per-location stock)
  /// that no longer exist on the server. Returns how many were removed.
  /// Does nothing if [serverIds] is empty.
  ///
  /// Only call when the sync queue is empty.
  Future<int> removeProductsNotOnServer(
    String businessId,
    Set<String> serverIds,
  ) async {
    if (serverIds.isEmpty) return 0;
    final gone = (await localProductIds(businessId))
        .where((id) => !serverIds.contains(id))
        .toList();
    if (gone.isEmpty) return 0;
    await _db.transaction(() async {
      for (var i = 0; i < gone.length; i += _chunk) {
        final part = gone.sublist(i, (i + _chunk).clamp(0, gone.length));
        await (_db.delete(_db.localInventoryStock)
              ..where((t) => t.productId.isIn(part)))
            .go();
        await (_db.delete(_db.localProducts)..where((t) => t.id.isIn(part)))
            .go();
      }
    });
    return gone.length;
  }

  /// Replaces local product [id] with the server's version [server], or
  /// removes it (and its stock) if the server doesn't have it. Used when the
  /// server refuses a product create/edit.
  Future<void> restoreProduct(
    String id,
    Map<String, dynamic>? server, {
    DateTime? syncedAt,
  }) async {
    if (server == null) {
      await _db.transaction(() async {
        await (_db.delete(_db.localInventoryStock)
              ..where((t) => t.productId.equals(id)))
            .go();
        await (_db.delete(_db.localProducts)..where((t) => t.id.equals(id)))
            .go();
      });
      return;
    }
    await _db.into(_db.localProducts).insertOnConflictUpdate(productFromRemote(
          server,
          syncedAt: syncedAt ?? DateTime.now().toUtc(),
        ));
  }

  /// Inserts server products that are missing locally (e.g. restored after a
  /// refused delete). Existing local products are left untouched.
  Future<void> insertMissingProducts(
    List<Map<String, dynamic>> products, {
    required DateTime syncedAt,
  }) async {
    if (products.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(
        _db.localProducts,
        products.map((p) => productFromRemote(p, syncedAt: syncedAt)).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}
