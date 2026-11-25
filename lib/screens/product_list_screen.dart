import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/inventory_design.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/inventory_switcher_sheet.dart';
import '../widgets/inventory_ui_helpers.dart';
import '../widgets/transfer_stock_sheet.dart';
import 'product_form_screen.dart';
import 'stock_adjust_dialog.dart';
import 'add_location_screen.dart';
import 'manage_locations_screen.dart';
import '../utils/error_text.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _searchController;
  final Set<String> _selected = {}; // multi-select (long press)
  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _navigateToAddProduct() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProductFormScreen()));
  }

  void _navigateToEditProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  void _showStockAdjustDialog(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StockAdjustDialog(product: product),
    );
  }

  Future<void> _openTransfer(List<String> productIds) async {
    final ok = await showTransferStockSheet(
      context,
      fromInventoryId: ref.read(currentInventoryIdProvider).valueOrNull,
      productIds: productIds,
    );
    if (ok == true && mounted) setState(_selected.clear);
  }

  Future<void> _openSwitcher() async {
    final result = await showInventorySwitcher(context);
    if (!mounted) return;
    if (result == 'transfer') {
      await _openTransfer(const []);
    } else if (result == 'manage') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ManageLocationsScreen()));
    } else if (result == 'add') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AddLocationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Leaving a location clears any selection (it belonged to that location)
    ref.listen<AsyncValue<String?>>(currentInventoryIdProvider, (prev, next) {
      if (prev?.valueOrNull != next.valueOrNull && _selected.isNotEmpty) {
        setState(_selected.clear);
      }
    });

    final filtered = ref.watch(filteredProductListProvider);
    final all = ref.watch(productListProvider);
    final inventories =
        ref.watch(accessibleInventoriesProvider).valueOrNull ?? [];
    final current = ref.watch(currentInventoryProvider).valueOrNull;
    final isAdmin = ref.watch(isAdminProvider);
    final canEdit = ref.watch(hasPermissionProvider('edit_inventory'));
    final totalCount = all.valueOrNull?.length ?? 0;
    final lowCount = all.valueOrNull?.where((p) => p.isLowStock).length ?? 0;
    final query = ref.watch(productSearchQueryProvider);

    return Scaffold(
      backgroundColor: InvDesign.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ConnectivityBanner(),
            _header(current?.name, inventories.length),
            _pillRow(inventories, current?.id, isAdmin),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFFAF5FF),
                      iconColor: const Color(0xFF7E22CE),
                      label: 'Total Items:',
                      value: '$totalCount',
                      valueColor: InvDesign.slate900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFFFBEB),
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Low Stock:',
                      value: '$lowCount',
                      valueColor: lowCount > 0
                          ? InvDesign.amber600
                          : InvDesign.slate900,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _searchField(current?.name, query),
            ),
            Expanded(
              child: filtered.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppColors.statusError,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorText(e),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(productListProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              query.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty
                                  ? 'No products match "$query"'
                                  : 'No products in ${current?.name ?? 'this location'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (query.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                canEdit
                                    ? 'Tap + to add a product, or transfer stock in from another location'
                                    : 'Nothing to show here yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(productListProvider);
                      await ref.read(productListProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        final id = p.id!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProductRow(
                            product: p,
                            selecting: _selecting,
                            selected: _selected.contains(id),
                            canEdit: canEdit,
                            onTap: () {
                              if (_selecting) {
                                _toggle(id);
                              } else if (canEdit) {
                                _navigateToEditProduct(p);
                              }
                            },
                            onLongPress: canEdit ? () => _toggle(id) : null,
                            onAction: () {
                              if (p.isLowStock) {
                                _showStockAdjustDialog(p);
                              } else {
                                _openTransfer([id]);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selecting ? _selectionBar() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (canEdit && !_selecting)
          // lifted so it clears the Settings button owned by HomeScreen
          ? Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: _GradientFab(onTap: _navigateToAddProduct),
            )
          : null,
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _header(String? locationName, int activeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: InvDesign.title,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _openSwitcher,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCCFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: InvDesign.slate200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: InvDesign.slate700,
                              ),
                              children: [
                                const TextSpan(text: 'Warehouse: '),
                                TextSpan(
                                  text: locationName ?? '—',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: InvDesign.plum,
                                  ),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: InvDesign.slate400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCF3E8FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x80E9D5FF)),
                  ),
                  child: Text(
                    '$activeCount Active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E22CE),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // TODO(backend/UI): barcode scanner. Needs a scanner package
                // and a barcode column on products. Disabled for now.
                Opacity(
                  opacity: 0.45,
                  child: Tooltip(
                    message: 'Barcode scan — coming soon',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: InvDesign.slate200),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 17,
                        color: InvDesign.slate600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillRow(
    List<LocalInventory> inventories,
    String? currentId,
    bool isAdmin,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        children: [
          // TODO(backend/UI): "All Locations" = combined view across inventories.
          // Comes with the stats/filter phase. Disabled for now.
          const _Pill(label: 'All Locations', enabled: false),
          for (final inv in inventories)
            _Pill(
              label: inv.name,
              selected: inv.id == currentId,
              onTap: () => switchInventoryWithConfirm(context, ref, inv),
            ),
          if (isAdmin)
            _Pill(
              label: '+ Add',
              accent: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddLocationScreen()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvDesign.slate100),
        boxShadow: InvDesign.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: InvDesign.slate400,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(String? locationName, String query) {
    return TextField(
      controller: _searchController,
      onChanged: (v) => ref.read(productSearchQueryProvider.notifier).state = v,
      style: const TextStyle(fontSize: 14, color: InvDesign.slate900),
      decoration: InputDecoration(
        hintText: 'Search products in ${locationName ?? 'this location'}...',
        hintStyle: const TextStyle(fontSize: 14, color: InvDesign.slate400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: InvDesign.slate400,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: InvDesign.slate400,
                ),
                onPressed: () {
                  _searchController.clear();
                  ref.read(productSearchQueryProvider.notifier).state = '';
                },
              )
            // TODO(UI): filter (category, low stock only). Disabled for now.
            : const Opacity(
                opacity: 0.45,
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: 18,
                  color: InvDesign.slate400,
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: InvDesign.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: InvDesign.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFC084FC), width: 2),
        ),
      ),
    );
  }

  Widget _selectionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: InvDesign.slate200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel selection',
              onPressed: () => setState(_selected.clear),
            ),
            Expanded(
              child: Text(
                '${_selected.length} selected',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: InvDesign.slate900,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openTransfer(_selected.toList()),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── widgets ──────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    this.selected = false,
    this.accent = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected
        ? Colors.white
        : accent
        ? const Color(0xFF7E22CE)
        : InvDesign.slate600;
    final decoration = BoxDecoration(
      gradient: selected ? InvDesign.brandGradient : null,
      color: selected
          ? null
          : accent
          ? const Color(0xFFFAF5FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: selected
          ? null
          : Border.all(
              color: accent ? const Color(0xFFE9D5FF) : InvDesign.slate200,
            ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Tooltip(
          message: enabled ? '' : 'Coming soon',
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 16 : 14,
                vertical: 6,
              ),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final bool selecting;
  final bool selected;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onAction;

  const _ProductRow({
    required this.product,
    required this.selecting,
    required this.selected,
    required this.canEdit,
    required this.onTap,
    required this.onLongPress,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final out = product.quantity <= 0;
    final low = product.isLowStock && !out;
    final restock = low || out;
    final sub = out
        ? 'Out of stock'
        : low
        ? 'Threshold reached (≤ ${product.lowStockThreshold})'
        : ((product.category?.isNotEmpty ?? false)
              ? product.category!
              : (product.sku ?? ''));
    // TODO(backend): shelf/aisle location ("Aisle 2 • Shelf A") and inbound
    // units ("5 units inbound") need new columns / in-transit transfers.

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: (low || out)
                ? const LinearGradient(
                    colors: [Colors.white, Colors.white, Color(0x4DFFFBEB)],
                  )
                : null,
            color: (low || out) ? null : Colors.white,
            border: Border.all(
              color: selected
                  ? const Color(0xFF9333EA)
                  : ((low || out)
                        ? const Color(0xB3FEF3C7)
                        : InvDesign.slate100),
              width: selected ? 2 : 1,
            ),
            boxShadow: InvDesign.cardShadow,
          ),
          child: Row(
            children: [
              // Thumbnail (no image column yet: placeholder icon)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xCCFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Icon(
                  selecting && selected
                      ? Icons.check_circle_rounded
                      : Icons.inventory_2_outlined,
                  color: selecting && selected
                      ? const Color(0xFF9333EA)
                      : InvDesign.amber600,
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
                            product.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: InvDesign.slate900,
                            ),
                          ),
                        ),
                        if (restock) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${product.sellPriceUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: InvDesign.slate500,
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: restock
                              ? InvDesign.amber600
                              : InvDesign.slate400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: out
                          ? AppColors.statusError
                          : (low ? InvDesign.orange : InvDesign.green),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      out
                          ? 'Out of Stock'
                          : '${low ? 'Low' : 'High'} (${product.quantity})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (canEdit && !selecting) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onAction,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            restock ? 'Restock' : 'Transfer',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            restock
                                ? Icons.add_rounded
                                : Icons.arrow_forward_rounded,
                            size: 11,
                            color: const Color(0xFF9333EA),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: InvDesign.fabGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73B833C4),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
