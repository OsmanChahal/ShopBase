import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/inventory_ui_helpers.dart';
import '../widgets/location_form_widgets.dart';
import '../widgets/transfer_stock_sheet.dart';
import '../providers/inventory_access_provider.dart';
import '../widgets/inventory_access_widgets.dart';
import '../utils/error_text.dart';
import '../utils/location_rules.dart';

class AddLocationScreen extends ConsumerStatefulWidget {
  const AddLocationScreen({super.key});
  @override
  ConsumerState<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends ConsumerState<AddLocationScreen> {
  final _name = TextEditingController();
  bool _isSaving = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  final Map<String, AccessGrant> _draft = {};

  Future<int> _applyDraftAccess(String inventoryId) =>
      ref.read(inventoryActionsProvider).applyAccessGrants(inventoryId, _draft);

  String? _nameError(List<LocalInventory> existing) => validateLocationName(
        _name.text.trim(),
        existing.map((i) => i.name),
      );

  Future<void> _save() async {
    final name = _name.text.trim();
    setState(() {
      _isSaving = true;
      _serverError = null;
    });
    String id;
    try {
      id = await ref.read(inventoryActionsProvider).create(name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _serverError = errorText(e);
      });
      return;
    }
    final failed = await _applyDraftAccess(id);
    final list = await ref.read(accessibleInventoriesProvider.future);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location created, but $failed staff access setting(s) could not '
            'be saved. Set them from Manage Locations.',
          ),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
    await _afterCreate(id, name, list);
  }

  Future<void> _afterCreate(
    String id,
    String name,
    List<LocalInventory> list,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('"$name" created'),
        content: const Text(
          'It is empty for now. You can switch to it, or move stock in '
          'from another location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('done'),
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('transfer'),
            child: const Text('Transfer stock in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('switch'),
            child: const Text('Switch to it'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final inv = list.where((i) => i.id == id).firstOrNull;
    if (choice == 'switch' && inv != null) {
      await switchInventoryWithConfirm(context, ref, inv);
    } else if (choice == 'transfer') {
      await showTransferStockSheet(context, toInventoryId: id);
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  Future<void> _discard() async {
    if (_name.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this location?'),
        content: const Text('What you typed will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final existing = ref.watch(accessibleInventoriesProvider).valueOrNull ?? [];
    final currentName = ref.watch(currentInventoryProvider).valueOrNull?.name;
    final nameError = _nameError(existing);
    final canSave =
        isAdmin &&
        _name.text.trim().isNotEmpty &&
        nameError == null &&
        !_isSaving;

    return Scaffold(
      backgroundColor: LocDesign.surface,
      appBar: locAppBar(
        context,
        title: 'Add Warehouse / Branch',
        subtitle: 'LOCATION SETUP',
        subtitleColor: LocDesign.purple,
        // TODO(backend/UI): help & documentation. Disabled for now.
        trailing: const ComingSoon(
          child: Icon(Icons.help_outline_rounded, color: LocDesign.muted),
        ),
      ),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Only the owner or an admin can add locations.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ── General information (LIVE: name only) ───────────────────
                LocSection(
                  dot: LocDesign.purple,
                  title: 'General Information',
                  trailing: const LocBadge(
                    'Required',
                    bg: LocDesign.purpleLight,
                    fg: LocDesign.purple,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LocLabel('Location / Branch Name', required: true),
                      TextField(
                        controller: _name,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        onChanged: (_) => setState(() => _serverError = null),
                        style: const TextStyle(fontSize: 14),
                        decoration: locInput(
                          'e.g., North Apiary Hub, Mall Branch POS',
                          error: nameError ?? _serverError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // TODO(backend): facility type needs an `inventories.type`
                      // column. Icons on the switcher are cosmetic until then.
                      const ComingSoon(
                        message: 'Facility type — coming soon',
                        child: _TypeGrid(),
                      ),
                      const SizedBox(height: 12),
                      // TODO(backend): auto-generated system ID (WH-005) needs
                      // a per-business sequence column.
                      const ComingSoon(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Auto-generated System ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: LocDesign.muted,
                              ),
                            ),
                            LocBadge(
                              'WH-—',
                              bg: Color(0xFFF1F5F9),
                              fg: LocDesign.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Address & lead (DISABLED) ───────────────────────────────
                // TODO(backend): address, city, postal code, manager name,
                // phone and a map pin need new columns on `inventories`.
                LocSection(
                  dot: LocDesign.green,
                  title: 'Address & Branch Lead',
                  trailing: const ComingSoon(
                    message: 'Map pin — coming soon',
                    child: LocBadge(
                      'Pin on Map',
                      bg: LocDesign.purpleLight,
                      fg: LocDesign.purple,
                    ),
                  ),
                  child: ComingSoon(
                    message: 'Address & contact — coming soon',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocLabel('Street Address'),
                        TextField(
                          enabled: false,
                          decoration: locInput(
                            'Building No, Street name, District',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const LocLabel('City / Municipality'),
                                  TextField(
                                    enabled: false,
                                    decoration: locInput('e.g. Beirut'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const LocLabel('Postal Code'),
                                  TextField(
                                    enabled: false,
                                    decoration: locInput('e.g. 11564'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const LocLabel('Responsible Manager / Contact'),
                        TextField(
                          enabled: false,
                          decoration: locInput("Manager's full name"),
                        ),
                        const SizedBox(height: 12),
                        const LocLabel('Phone Number'),
                        TextField(
                          enabled: false,
                          decoration: locInput('+961 3 XXX XXX'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Inventory & POS settings (DISABLED) ─────────────────────
                LocSection(
                  dot: const Color(0xFFF59E0B),
                  title: 'Inventory & POS Settings',
                  child: Column(
                    children: [
                      // TODO(backend): POS access is per staff member
                      // (inventory_access.can_pos), not a per-location switch.
                      const ComingSoon(
                        child: LocToggleRow(
                          title: 'Enable Point of Sale (POS)',
                          subtitle:
                              'Allow direct sales and checkout from this branch',
                          value: true,
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFF3F4F6)),
                      // TODO(backend): thresholds are per product today; a
                      // per-location default needs a new column.
                      const ComingSoon(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Low Stock Alert Threshold',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Trigger warning tags when stock dips below',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: LocDesign.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            LocBadge(
                              '10 units',
                              bg: Color(0xFFF1F5F9),
                              fg: LocDesign.ink,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xFFF3F4F6)),
                      // TODO(backend): "primary" is the oldest location and
                      // drives server routing; changing it needs a design.
                      const ComingSoon(
                        child: LocToggleRow(
                          title: 'Set as Primary Warehouse',
                          subtitle:
                              'New purchases default to this hub unless chosen otherwise',
                          value: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                LocSection(
                  dot: LocDesign.purple,
                  title: 'Staff Access',
                  child: DraftStaffAccessSection(
                    draft: _draft,
                    onChanged: (userId, grant) => setState(() {
                      if (grant.isNone) {
                        _draft.remove(userId);
                      } else {
                        _draft[userId] = grant;
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Next-step callout (LIVE) ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x99E8FBF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x4D10B981)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: LocDesign.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Step: Product Allocation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF022C22),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Once saved, you can immediately transfer '
                              'products from ${currentName ?? 'another location'}.',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !isAdmin
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: LocDesign.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocPrimaryButton(
                      label: 'Save & Add Location',
                      icon: Icons.add_rounded,
                      loading: _isSaving,
                      onTap: canSave ? _save : null,
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _discard,
                      child: const Text(
                        'Discard & Go Back',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// The 4 facility-type cards from the design (inert, wrapped in ComingSoon).
class _TypeGrid extends StatelessWidget {
  const _TypeGrid();
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocLabel('Facility Type', required: true),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                'Central Hub',
                'Main Warehouse',
                Icons.apartment_rounded,
                LocDesign.purple,
                Colors.white,
                true,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _TypeCard(
                'Retail Kiosk',
                'Storefront / Mall',
                Icons.shopping_bag_outlined,
                Color(0xFFFEF3C7),
                Color(0xFFB45309),
                false,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                'Apiary Farm',
                'Harvest & Bulk',
                Icons.home_work_outlined,
                Color(0xFFD1FAE5),
                Color(0xFF047857),
                false,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _TypeCard(
                'Fulfillment',
                'E-Commerce hub',
                Icons.public_rounded,
                Color(0xFFE0F2FE),
                Color(0xFF0369A1),
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title, sub;
  final IconData icon;
  final Color bg, fg;
  final bool selected;
  const _TypeCard(
    this.title,
    this.sub,
    this.icon,
    this.bg,
    this.fg,
    this.selected,
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: selected ? const Color(0x66F3EEFA) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? LocDesign.purple : const Color(0xFFE5E5E5),
        width: selected ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? LocDesign.purple : const Color(0xFF262626),
                ),
              ),
              Text(
                sub,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: LocDesign.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
