import 'dart:developer' as dev;
import 'package:crm_pos/providers/product_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'auth_provider.dart';

/// Non-archived inventories the signed-in user may use, oldest first
/// (so "Main" is first). Owners/admins get all; staff get only their grants.
/// [posOnly] restricts staff to inventories where they may sell (can_pos).
Future<List<LocalInventory>> _loadInventories(
  Ref ref, {
  required bool posOnly,
}) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final isAdmin = ref.watch(isAdminProvider);
  final db = ref.watch(appDatabaseProvider);

  final all =
      await (db.select(db.localInventories)
            ..where(
              (t) =>
                  t.businessId.equals(business.id) & t.isArchived.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();
  if (isAdmin) return all;

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final grants = await (db.select(
    db.localInventoryAccess,
  )..where((t) => t.userId.equals(userId))).get();
  final allowed = grants
      .where((g) => posOnly ? g.canPos : g.canView)
      .map((g) => g.inventoryId)
      .toSet();
  return all.where((i) => allowed.contains(i.id)).toList();
}

/// Inventories the user can view (dashboard filter, product list, stats).
final accessibleInventoriesProvider = FutureProvider<List<LocalInventory>>(
  (ref) => _loadInventories(ref, posOnly: false),
);

/// Inventories the user can sell from (POS selector).
final posInventoriesProvider = FutureProvider<List<LocalInventory>>(
  (ref) => _loadInventories(ref, posOnly: true),
);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// The user's explicit choice, remembered per user on this device.
/// null = "use the first accessible one".
class SelectedInventoryNotifier extends StateNotifier<String?> {
  final SharedPreferences? _prefs;
  final String? _key;

  SelectedInventoryNotifier(this._prefs, this._key)
    : super((_prefs == null || _key == null) ? null : _prefs.getString(_key));

  Future<void> select(String? inventoryId) async {
    state = inventoryId;
    final prefs = _prefs;
    final key = _key;
    if (prefs == null || key == null) return;
    try {
      if (inventoryId == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, inventoryId);
      }
    } catch (e) {
      dev.log('[Inventory] could not save selection: $e');
    }
  }
}

final selectedInventoryIdProvider =
    StateNotifierProvider<SelectedInventoryNotifier, String?>((ref) {
      ref.watch(
        currentBusinessProvider.select((b) => b?.id),
      ); // rebuild on login/logout
      final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      return SelectedInventoryNotifier(
        prefs,
        userId == null ? null : 'selected_inventory_$userId',
      );
    });

/// The inventory the app is currently working in. Falls back to the first
/// accessible inventory if the saved one is missing, archived or revoked.
final currentInventoryIdProvider = FutureProvider<String?>((ref) async {
  // Wait for prefs so the saved choice is applied before anything renders
  try {
    await ref.watch(sharedPreferencesProvider.future);
  } catch (_) {}
  final list = await ref.watch(accessibleInventoriesProvider.future);
  final selected = ref.watch(selectedInventoryIdProvider);
  final id = (selected != null && list.any((i) => i.id == selected))
      ? selected
      : (list.isEmpty ? null : list.first.id);
  dev.log(
    '[Inventory] current inventory = $id (of ${list.length})',
  ); // TEMPORARY
  return id;
});

/// The inventory the app is working in (null until inventories are pulled).
final currentInventoryProvider = FutureProvider<LocalInventory?>((ref) async {
  final id = await ref.watch(currentInventoryIdProvider.future);
  final list = await ref.watch(accessibleInventoriesProvider.future);
  for (final i in list) {
    if (i.id == id) return i;
  }
  return null;
});

/// The oldest inventory of the business = "Main" (shown with a Primary badge).
final primaryInventoryIdProvider = FutureProvider<String?>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return null;
  final db = ref.watch(appDatabaseProvider);
  final rows =
      await (db.select(db.localInventories)
            ..where((t) => t.businessId.equals(business.id))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(1))
          .get();
  return rows.isEmpty ? null : rows.first.id;
});

class InventorySummary {
  final LocalInventory inventory;
  final int products;
  final int units;
  final int lowStock;
  const InventorySummary(
    this.inventory,
    this.products,
    this.units,
    this.lowStock,
  );
}

/// Per-inventory totals for the switcher sheet.
final inventorySummariesProvider = FutureProvider<List<InventorySummary>>((
  ref,
) async {
  ref.watch(productListProvider); // recompute whenever stock changes
  final list = await ref.watch(accessibleInventoriesProvider.future);
  if (list.isEmpty) return [];
  final db = ref.watch(appDatabaseProvider);
  final rows = await (db.select(
    db.localInventoryStock,
  )..where((t) => t.inventoryId.isIn(list.map((i) => i.id).toList()))).get();
  return list.map((inv) {
    final mine = rows.where((r) => r.inventoryId == inv.id);
    return InventorySummary(
      inv,
      mine.length,
      mine.fold<int>(0, (a, r) => a + r.quantity),
      mine.where((r) => r.quantity <= r.lowStockThreshold).length,
    );
  }).toList();
});

/// Archived locations (for the Manage screen's Restore list).
final archivedInventoriesProvider = FutureProvider<List<LocalInventory>>((
  ref,
) async {
  ref.watch(accessibleInventoriesProvider); // refresh when inventories change
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.localInventories)
        ..where(
          (t) => t.businessId.equals(business.id) & t.isArchived.equals(true),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
});
