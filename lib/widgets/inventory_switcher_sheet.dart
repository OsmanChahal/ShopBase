import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_colors.dart';
import 'transfer_stock_sheet.dart';

const _accent = Color(0xFF833AB4); // design: brand.accent
const _emerald = Color(0xFF10B981);
const _orange = Color(0xFFF97316);

Future<String?> showInventorySwitcher(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const InventorySwitcherSheet(),
  );
}

class InventorySwitcherSheet extends ConsumerStatefulWidget {
  const InventorySwitcherSheet({super.key});
  @override
  ConsumerState<InventorySwitcherSheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<InventorySwitcherSheet> {
  // Cosmetic only: no column stores icon/color per location. They cycle by position.
  static const _icons = [
    Icons.shopping_bag_outlined,
    Icons.home_work_outlined,
    Icons.public_rounded,
  ];
  static const _tints = [
    (Color(0xFFFFEDD5), Color(0xFFEA580C)), // orange
    (Color(0xFFD1FAE5), Color(0xFF047857)), // emerald
    (Color(0xFFDBEAFE), Color(0xFF2563EB)), // blue
  ];

  Future<void> _select(LocalInventory inv, String? currentId) async {
    if (inv.id == currentId) {
      Navigator.of(context).pop();
      return;
    }
    if (ref.read(cartProvider).isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Switch location?'),
          content: const Text(
            'Your cart has items from the current location. '
            'Switching will clear the cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Switch & clear'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      ref.read(cartProvider.notifier).clear();
    }
    await ref.read(selectedInventoryIdProvider.notifier).select(inv.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(inventorySummariesProvider).valueOrNull ?? [];
    final currentId = ref.watch(currentInventoryIdProvider).valueOrNull;
    final primaryId = ref.watch(primaryInventoryIdProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider);
    final canTransfer =
        ref.watch(hasPermissionProvider('edit_inventory')) &&
        summaries.length >= 2;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    var otherIndex = 0;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Switch stock view or allocate items',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: canTransfer ? 1 : 0.45,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canTransfer
                            ? () => Navigator.of(context).pop('transfer')
                            : null,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryPurple, _accent],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Transfer Stock Between Locations',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Locations
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  for (final s in summaries)
                    () {
                      final isPrimary = s.inventory.id == primaryId;
                      final tint = isPrimary
                          ? null
                          : _tints[otherIndex % _tints.length];
                      final icon = isPrimary
                          ? Icons.apartment_rounded
                          : _icons[otherIndex++ % _icons.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LocationCard(
                          summary: s,
                          selected: s.inventory.id == currentId,
                          isPrimary: isPrimary,
                          icon: icon,
                          tint: tint,
                          onTap: () => _select(s.inventory, currentId),
                        ),
                      );
                    }(),
                  if (summaries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No locations available yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer actions
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: isAdmin ? 1 : 0.45,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isAdmin
                          ? () => Navigator.of(context).pop('manage')
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: _accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: isAdmin ? 1 : 0.45,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: isAdmin
                            ? () => Navigator.of(context).pop('add')
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Color(0xFF4B5563),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add New Warehouse / Branch',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final InventorySummary summary;
  final bool selected;
  final bool isPrimary;
  final IconData icon;
  final (Color, Color)? tint; // (background, foreground); null = primary style
  final VoidCallback onTap;

  const _LocationCard({
    required this.summary,
    required this.selected,
    required this.isPrimary,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final low = summary.lowStock;
    final empty = summary.products == 0;
    final dot = low > 0
        ? _orange
        : (empty ? const Color(0xFF9CA3AF) : _emerald);
    final statusText = low > 0
        ? '$low ${low == 1 ? 'Item' : 'Items'} Low Stock'
        : (empty ? 'No stock yet' : 'Healthy Stock Level');
    final statusColor = low > 0
        ? const Color(0xFFEA580C)
        : (empty ? AppColors.textSecondary : const Color(0xFF047857));

    return Material(
      color: selected
          ? AppColors.primaryPurple.withValues(alpha: 0.06)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primaryPurple
                  : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint?.$1 ?? AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: tint?.$2 ?? Colors.white),
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
                            summary.inventory.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.products} ${summary.products == 1 ? 'Product' : 'Products'}'
                      ' • ${summary.units} ${summary.units == 1 ? 'Unit' : 'Units'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              selected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 2,
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
