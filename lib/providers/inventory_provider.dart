import 'dart:developer' as dev;
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

/// The user's explicit choice. null = "use the first accessible one".
/// In-memory for now; persistence per user comes after I check pubspec.
final selectedInventoryIdProvider = StateProvider<String?>((ref) => null);

/// The inventory the app is currently working in. Falls back to the first
/// accessible inventory if the selection is missing, archived or revoked.
/// null means no inventories have been pulled yet (offline right after upgrade).
final currentInventoryIdProvider = FutureProvider<String?>((ref) async {
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
