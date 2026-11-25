import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/location_form_widgets.dart';
import 'add_location_screen.dart';
import 'edit_location_screen.dart';
import '../utils/error_text.dart';

/// Design not provided: styled like the switcher sheet's location cards.
class ManageLocationsScreen extends ConsumerWidget {
  const ManageLocationsScreen({super.key});

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    LocalInventory inv,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(inventoryActionsProvider).unarchive(inv.id);
      messenger.showSnackBar(SnackBar(content: Text('"${inv.name}" restored')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final active = ref.watch(inventorySummariesProvider).valueOrNull ?? [];
    final archived = ref.watch(archivedInventoriesProvider).valueOrNull ?? [];
    final primaryId = ref.watch(primaryInventoryIdProvider).valueOrNull;

    return Scaffold(
      backgroundColor: LocDesign.surface,
      appBar: locAppBar(
        context,
        title: 'Manage Locations',
        subtitle: 'WAREHOUSES & BRANCHES',
        subtitleColor: LocDesign.purple,
      ),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Only the owner or an admin can manage locations.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                for (final s in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditLocationScreen(inventoryId: s.inventory.id),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LocDesign.border),
                          boxShadow: LocDesign.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: LocDesign.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          s.inventory.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (s.inventory.id == primaryId) ...[
                                        const SizedBox(width: 8),
                                        const LocBadge(
                                          'PRIMARY',
                                          bg: LocDesign.purple,
                                          fg: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.products} Products • ${s.units} Units',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: LocDesign.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: LocDesign.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ARCHIVED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  for (final inv in archived)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                inv.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _restore(context, ref, inv),
                              child: const Text('Restore'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
      bottomNavigationBar: !isAdmin
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: LocDesign.border)),
              ),
              child: SafeArea(
                top: false,
                child: LocPrimaryButton(
                  label: 'Add New Warehouse / Branch',
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddLocationScreen(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
