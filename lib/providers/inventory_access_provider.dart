import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/business_member.dart';
import 'staff_provider.dart';

/// What one person may do in one location. Sell and Edit imply View.
class AccessGrant {
  final bool pos;
  final bool view;
  final bool edit;
  const AccessGrant({this.pos = false, this.view = false, this.edit = false});

  static const none = AccessGrant();
  bool get isNone => !pos && !view && !edit;

  AccessGrant toggled(String level, bool on) {
    switch (level) {
      case 'pos':
        return AccessGrant(pos: on, view: on ? true : view, edit: edit);
      case 'edit':
        return AccessGrant(pos: pos, view: on ? true : view, edit: on);
      default: // view
        return on
            ? AccessGrant(pos: pos, view: true, edit: edit)
            : AccessGrant.none; // no View means no Sell and no Edit
    }
  }
}

/// Live copy of the local access table (owner/admin devices hold every row).
final inventoryAccessRowsProvider =
    StreamProvider<List<LocalInventoryAccessRow>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return db.select(db.localInventoryAccess).watch();
    });

AccessGrant lookupGrant(
  List<LocalInventoryAccessRow> rows,
  String inventoryId,
  String userId,
) {
  for (final r in rows) {
    if (r.inventoryId == inventoryId && r.userId == userId) {
      return AccessGrant(pos: r.canPos, view: r.canView, edit: r.canEdit);
    }
  }
  return AccessGrant.none;
}

/// Active non-admin staff. Online-only (comes from the staff service).
final assignableStaffProvider = FutureProvider<List<BusinessMember>>((
  ref,
) async {
  final all = await ref.watch(staffMembersProvider.future);
  return all.where((m) => m.role != 'admin' && m.status == 'active').toList();
});
