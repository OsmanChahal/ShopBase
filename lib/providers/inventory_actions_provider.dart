import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_provider.dart';
import '../database/local_inventory_repository.dart';
import 'auth_provider.dart';
import 'inventory_provider.dart';
import 'product_provider.dart';

export '../database/local_inventory_repository.dart' show TransferLine;

final localInventoryRepositoryProvider = Provider<LocalInventoryRepository>(
  (ref) => LocalInventoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncQueueRepositoryProvider),
  ),
);

class InventoryActions {
  final Ref ref;
  InventoryActions(this.ref);

  LocalInventoryRepository get _repo =>
      ref.read(localInventoryRepositoryProvider);

  String get _businessId {
    final b = ref.read(currentBusinessProvider);
    if (b == null) throw Exception('No business loaded');
    return b.id;
  }

  void _requireAdmin() {
    if (!ref.read(isAdminProvider)) {
      throw Exception('Only the owner or an admin can manage inventories');
    }
  }

  void _refresh() {
    ref.invalidate(accessibleInventoriesProvider);
    ref.invalidate(posInventoriesProvider);
    ref.invalidate(productListProvider);
  }

  Future<String> create(String name) async {
    _requireAdmin();
    final id = await _repo.createInventory(businessId: _businessId, name: name);
    _refresh();
    return id;
  }

  Future<void> rename(String id, String name) async {
    _requireAdmin();
    await _repo.renameInventory(id, name);
    _refresh();
  }

  Future<void> archive(String id) async {
    _requireAdmin();
    await _repo.archiveInventory(id);
    // If the archived one was selected, the provider falls back automatically
    _refresh();
  }

  Future<void> unarchive(String id) async {
    _requireAdmin();
    await _repo.unarchiveInventory(id);
    _refresh();
  }

  Future<String> transfer({
    required String fromId,
    required String toId,
    required List<TransferLine> items,
  }) async {
    if (!ref.read(hasPermissionProvider('edit_inventory'))) {
      throw Exception("You don't have permission to move stock");
    }
    final id = await _repo.transferStock(
      businessId: _businessId,
      fromInventoryId: fromId,
      toInventoryId: toId,
      items: items,
      createdBy: Supabase.instance.client.auth.currentUser?.id,
    );
    ref.invalidate(productListProvider);
    return id;
  }

  Future<void> setAccess({
    required String inventoryId,
    required String userId,
    required bool canPos,
    required bool canView,
    required bool canEdit,
  }) async {
    _requireAdmin();
    await _repo.setInventoryAccess(
      inventoryId: inventoryId,
      userId: userId,
      canPos: canPos,
      canView: canView,
      canEdit: canEdit,
    );
  }
}

final inventoryActionsProvider = Provider<InventoryActions>(
  (ref) => InventoryActions(ref),
);
