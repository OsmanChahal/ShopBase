import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/location_form_widgets.dart';
import '../widgets/transfer_stock_sheet.dart';
import '../widgets/inventory_access_widgets.dart';
import '../utils/error_text.dart';
import '../utils/location_rules.dart';

class EditLocationScreen extends ConsumerStatefulWidget {
  final String inventoryId;
  const EditLocationScreen({super.key, required this.inventoryId});
  @override
  ConsumerState<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends ConsumerState<EditLocationScreen> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  bool _nameInit = false;
  bool _busy = false;
  String? _serverError;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _quickRename() {
    _nameFocus.requestFocus();
    _name.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _name.text.length,
    );
  }

  Future<void> _save(InventorySummary s) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _serverError = null;
    });
    try {
      await ref
          .read(inventoryActionsProvider)
          .rename(s.inventory.id, _name.text.trim());
      messenger.showSnackBar(const SnackBar(content: Text('Location renamed')));
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = errorText(e);
      });
    }
  }

  Future<void> _archive(InventorySummary s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive "${s.inventory.name}"?'),
        content: const Text(
          'It disappears from the POS, the switcher and transfers. Past sales '
          'and history are kept, and you can restore it later from Manage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: LocDesign.danger),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(inventoryActionsProvider)
          .archiveAndClearCartIfCurrent(s.inventory.id);
      messenger.showSnackBar(
        SnackBar(content: Text('"${s.inventory.name}" archived')),
      );
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(errorText(e))),
      );
    }
  }

  Future<void> _transferOut() =>
      showTransferStockSheet(context, fromInventoryId: widget.inventoryId);

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final summariesAsync = ref.watch(inventorySummariesProvider);
    final primaryId = ref.watch(primaryInventoryIdProvider).valueOrNull;
    final list = summariesAsync.valueOrNull ?? [];
    final s = list
        .where((x) => x.inventory.id == widget.inventoryId)
        .firstOrNull;

    if (s == null) {
      return Scaffold(
        backgroundColor: LocDesign.surface,
        appBar: locAppBar(
          context,
          title: 'Edit Location',
          subtitle: 'WAREHOUSE SETTINGS',
          subtitleColor: LocDesign.muted,
        ),
        body: Center(
          child: summariesAsync.isLoading
              ? const CircularProgressIndicator()
              : const Text('This location is no longer available.'),
        ),
      );
    }

    if (!_nameInit) {
      _name.text = s.inventory.name;
      _nameInit = true;
    }

    final isPrimary = s.inventory.id == primaryId;
    final typed = _name.text.trim();
    final nameError = validateLocationName(
      typed,
      list
          .where((x) => x.inventory.id != s.inventory.id)
          .map((x) => x.inventory.name),
      emptyMessage: 'Name is required',
    );
    final dirty = typed != s.inventory.name;
    final canSave = isAdmin && dirty && nameError == null && !_busy;

    // Archive rules (server enforces the same; primary is a UI-only rule)
    final archiveBlock = archiveBlockReason(
      isPrimary: isPrimary,
      activeLocationCount: list.length,
      allocatedUnits: s.units,
    );
    final canArchive = isAdmin && archiveBlock == null && !_busy;

    final low = s.lowStock;
    final healthColor = low > 0
        ? const Color(0xFFD97706)
        : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: LocDesign.surface,
      appBar: locAppBar(
        context,
        title: 'Edit Location',
        subtitle: 'WAREHOUSE SETTINGS',
        subtitleColor: LocDesign.muted,
        // TODO(UI): overflow menu (duplicate, export...). Disabled for now.
        trailing: const ComingSoon(
          child: Icon(Icons.more_horiz_rounded, color: LocDesign.muted),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── Summary card (LIVE) ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LocDesign.purple, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: LocDesign.purple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 24,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            const LocBadge(
                              'PRIMARY',
                              bg: LocDesign.purple,
                              fg: Colors.white,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.products} ${s.products == 1 ? 'Product' : 'Products'}'
                        ' • ${s.units} Total ${s.units == 1 ? 'Unit' : 'Units'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: LocDesign.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: healthColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.products == 0
                                    ? 'No stock yet'
                                    : (low > 0
                                          ? 'Needs attention'
                                          : 'Healthy Stock Level'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: healthColor,
                                ),
                              ),
                            ],
                          ),
                          if (low > 0)
                            LocBadge(
                              '$low ${low == 1 ? 'Alert' : 'Alerts'}',
                              bg: const Color(0xFFFFFBEB),
                              fg: const Color(0xFFD97706),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Location profile ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Eyebrow('Location Profile'),
              if (isAdmin)
                InkWell(
                  onTap: _quickRename,
                  child: const Text(
                    'Quick Rename',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocLabel('Warehouse / Location Name'),
                TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  enabled: isAdmin,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  onChanged: (_) => setState(() => _serverError = null),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration:
                      locInput(
                        'Location name',
                        error: dirty
                            ? (nameError ?? _serverError)
                            : _serverError,
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO(backend): facility type column.
                    const Expanded(
                      child: ComingSoon(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocLabel('Type'),
                            _FakeField(
                              'Central Hub',
                              trailing: Icons.keyboard_arrow_down_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // TODO(backend): identifier code (WH-001) sequence column.
                    const Expanded(
                      child: ComingSoon(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocLabel('Identifier Code'),
                            _FakeField('WH-—', mono: true, readOnly: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isAdmin) ...[
            const _Eyebrow('Staff Access'),
            const SizedBox(height: 8),
            _Card(
              child: InventoryStaffAccessSection(inventoryId: s.inventory.id),
            ),
            const SizedBox(height: 20),
          ],
          // ── Address & operations (DISABLED) ──────────────────────────────
          // TODO(backend): physical address + operations manager columns.
          const _Eyebrow('Address & Operations'),
          const SizedBox(height: 8),
          const ComingSoon(
            message: 'Address & contact — coming soon',
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocLabel('Physical Storage Details'),
                  _FakeField(
                    'Address, aisle, sector...',
                    leading: Icons.place_outlined,
                  ),
                  SizedBox(height: 14),
                  LocLabel('Operations Manager'),
                  _FakeField(
                    'Manager name and phone',
                    leading: Icons.person_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Rules & alerts (DISABLED) ────────────────────────────────────
          const _Eyebrow('Inventory Rules & Alerts'),
          const SizedBox(height: 8),
          const _Card(
            child: Column(
              children: [
                // TODO(backend): per-location default threshold column.
                ComingSoon(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Low Stock Alert',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Triggers reorder badge on products',
                              style: TextStyle(
                                fontSize: 11,
                                color: LocDesign.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      LocBadge(
                        '15 units',
                        bg: Color(0xFFF1F5F9),
                        fg: LocDesign.ink,
                      ),
                    ],
                  ),
                ),
                Divider(height: 28, color: Color(0xFFF1F5F9)),
                // TODO(backend): POS is per staff member (can_pos).
                ComingSoon(
                  child: LocToggleRow(
                    title: 'Active POS Cashier Terminal',
                    subtitle: 'Enable direct checkouts at this facility',
                    value: false,
                  ),
                ),
                Divider(height: 28, color: Color(0xFFF1F5F9)),
                // TODO(backend): push notifications are not built.
                ComingSoon(
                  child: LocToggleRow(
                    title: 'Restock Notifications',
                    subtitle:
                        'Send push alerts when items fall under threshold',
                    value: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Governance (LIVE) ────────────────────────────────────────────
          const _Eyebrow('Location Governance'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x80FFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xCCFECDD3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Color(0xFFF43F5E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deactivate or Archive Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4C0519),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            archiveBlock ??
                                'Archiving hides this location from the POS '
                                    'and transfers. History is kept and you '
                                    'can restore it from Manage.',
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Color(0xE6BE123C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (s.units > 0)
                        _SmallButton(
                          'Transfer Stock First',
                          onTap: _busy ? null : _transferOut,
                          danger: true,
                        ),
                      const SizedBox(width: 8),
                      _SmallButton(
                        'Archive Location',
                        onTap: canArchive ? () => _archive(s) : null,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocPrimaryButton(
                label: 'Save Changes',
                icon: Icons.check_rounded,
                gradient: false,
                loading: _busy,
                onTap: canSave ? () => _save(s) : null,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (s.units > 0 && !_busy) ? _transferOut : null,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: LocDesign.purple,
                  ),
                  label: Text(
                    'Transfer Stock Out of ${s.inventory.name}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
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

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF64748B),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

/// Look-alike field used only for disabled placeholders.
class _FakeField extends StatelessWidget {
  final String text;
  final IconData? leading;
  final IconData? trailing;
  final bool mono;
  final bool readOnly;
  const _FakeField(
    this.text, {
    this.leading,
    this.trailing,
    this.mono = false,
    this.readOnly = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        if (leading != null) ...[
          Icon(leading, size: 16, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        if (trailing != null)
          Icon(trailing, size: 18, color: const Color(0xFF94A3B8)),
      ],
    ),
  );
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const _SmallButton(this.label, {required this.onTap, this.danger = false});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xFFF1F5F9)
              : (danger ? const Color(0xB3FFE4E6) : const Color(0xFFFFE4E6)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? const Color(0xFFFECDD3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFFBE123C) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
