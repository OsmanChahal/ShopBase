import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_member.dart';
import '../providers/inventory_access_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/staff_provider.dart';
import '../theme/app_colors.dart';
import 'location_form_widgets.dart';

const _amber = Color(0xFFB45309);

/// The server needs the global permission AND the location grant.
String? permissionHint(BusinessMember m, AccessGrant g) {
  if (g.pos && !m.hasPermission('use_pos')) {
    return "Selling also needs the 'Use POS' permission";
  }
  if (g.edit && !m.hasPermission('edit_inventory')) {
    return "Editing also needs the 'Edit Inventory' permission";
  }
  if (g.view &&
      !(m.hasPermission('view_inventory') ||
          m.hasPermission('use_pos') ||
          m.hasPermission('view_dashboard'))) {
    return "Viewing needs 'View Inventory', 'Use POS' or 'View Dashboard'";
  }
  return null;
}

/// Saves one grant (local-first). Shows a message instead of throwing.
Future<void> saveAccessGrant(
  BuildContext context,
  WidgetRef ref, {
  required String inventoryId,
  required String userId,
  required AccessGrant grant,
}) async {
  try {
    await ref
        .read(inventoryActionsProvider)
        .setAccess(
          inventoryId: inventoryId,
          userId: userId,
          canPos: grant.pos,
          canView: grant.view,
          canEdit: grant.edit,
        );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.statusError,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String extra;
  const _Note(this.extra);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      'Owners and admins always have full access. '
      'Sell = use the POS, View = see stock and sales, Edit = change '
      'stock and prices and move stock. $extra',
      style: const TextStyle(fontSize: 11, height: 1.4, color: LocDesign.muted),
    ),
  );
}

class _AccessChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _AccessChip(this.label, this.on, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: on ? LocDesign.purple : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? LocDesign.purple : LocDesign.fieldBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (on) ...[
            const Icon(Icons.check_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One row: a name plus the Sell / View / Edit chips.
class AccessTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? warning;
  final AccessGrant grant;
  final ValueChanged<AccessGrant> onChanged;
  const AccessTile({
    super.key,
    required this.title,
    required this.grant,
    required this.onChanged,
    this.subtitle,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: LocDesign.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: LocDesign.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: LocDesign.muted),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _AccessChip(
              'Sell',
              grant.pos,
              () => onChanged(grant.toggled('pos', !grant.pos)),
            ),
            _AccessChip(
              'View',
              grant.view,
              () => onChanged(grant.toggled('view', !grant.view)),
            ),
            _AccessChip(
              'Edit',
              grant.edit,
              () => onChanged(grant.toggled('edit', !grant.edit)),
            ),
          ],
        ),
        if (warning != null) ...[
          const SizedBox(height: 6),
          Text(
            warning!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _amber,
            ),
          ),
        ],
      ],
    ),
  );
}

/// The staff list shared by the Add and Edit location screens.
class _StaffList extends ConsumerWidget {
  final AccessGrant Function(String userId) grantFor;
  final void Function(BusinessMember member, AccessGrant grant) onChange;
  const _StaffList({required this.grantFor, required this.onChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assignableStaffProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, st) => Column(
        children: [
          const Text(
            'Connect to the internet to load your staff list.',
            style: TextStyle(fontSize: 12, color: LocDesign.muted),
          ),
          TextButton(
            onPressed: () => ref.invalidate(staffMembersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Text(
            'No active staff yet. Invite people from Manage Staff, then '
            'choose their access here.',
            style: TextStyle(fontSize: 12, color: LocDesign.muted),
          );
        }
        return Column(
          children: [
            for (final m in list)
              AccessTile(
                title: m.displayName ?? 'Staff member',
                grant: grantFor(m.userId),
                warning: permissionHint(m, grantFor(m.userId)),
                onChanged: (g) => onChange(m, g),
              ),
          ],
        );
      },
    );
  }
}

/// Edit Location: saves each tap instantly.
class InventoryStaffAccessSection extends ConsumerWidget {
  final String inventoryId;
  const InventoryStaffAccessSection({super.key, required this.inventoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(inventoryAccessRowsProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Note('Changes save instantly.'),
        _StaffList(
          grantFor: (u) => lookupGrant(rows, inventoryId, u),
          onChange: (m, g) => saveAccessGrant(
            context,
            ref,
            inventoryId: inventoryId,
            userId: m.userId,
            grant: g,
          ),
        ),
      ],
    );
  }
}

/// Add Location: a draft kept by the screen until the location is created.
class DraftStaffAccessSection extends StatelessWidget {
  final Map<String, AccessGrant> draft;
  final void Function(String userId, AccessGrant grant) onChanged;
  const DraftStaffAccessSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Note(
        'Applied when you save. Leave everyone off to keep the '
        'location private to owners and admins.',
      ),
      _StaffList(
        grantFor: (u) => draft[u] ?? AccessGrant.none,
        onChange: (m, g) => onChanged(m.userId, g),
      ),
    ],
  );
}

/// Staff edit sheet: the same grants, seen from the person's side.
class StaffLocationAccessSection extends ConsumerWidget {
  final BusinessMember member;
  const StaffLocationAccessSection({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventories =
        ref.watch(accessibleInventoriesProvider).valueOrNull ?? const [];
    final rows = ref.watch(inventoryAccessRowsProvider).valueOrNull ?? const [];
    if (inventories.isEmpty) {
      return const Text(
        'No locations yet.',
        style: TextStyle(fontSize: 12, color: LocDesign.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Note('Changes save instantly.'),
        for (final inv in inventories)
          Builder(
            builder: (_) {
              final g = lookupGrant(rows, inv.id, member.userId);
              return AccessTile(
                title: inv.name,
                grant: g,
                warning: permissionHint(member, g),
                onChanged: (next) => saveAccessGrant(
                  context,
                  ref,
                  inventoryId: inv.id,
                  userId: member.userId,
                  grant: next,
                ),
              );
            },
          ),
      ],
    );
  }
}
