import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../sync/sync_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/inventory_ui_helpers.dart';
import 'cart_panel.dart';
import 'sales_history_screen.dart';
import '../providers/pos_provider.dart';
import '../utils/formatters.dart';
import '../utils/error_text.dart';

part 'pos/pos_widgets.dart';

const _brand = Color(0xFF4A154B);
const _brandEnd = Color(0xFF6B21A8);
const _purple600 = Color(0xFF9333EA);
const _bg = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate700 = Color(0xFF334155);
const _slate900 = Color(0xFF0F172A);
const _emerald = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  late final TextEditingController _searchController;

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

  void _toast(String msg, {bool error = false}) {
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(milliseconds: error ? 2500 : 1200),
        backgroundColor: error ? AppColors.statusError : AppColors.emeraldGreen,
      ),
    );
  }

  void _addToCart(Product product, bool canSell) {
    if (!canSell) {
      _toast("You can't sell from this location", error: true);
      return;
    }
    try {
      ref.read(cartProvider.notifier).addToCart(product);
      _toast('${product.name} added to cart');
    } catch (e) {
      _toast(errorText(e), error: true);
    }
  }

  void _increment(String productId) {
    try {
      ref.read(cartProvider.notifier).incrementQuantity(productId);
    } catch (e) {
      _toast(errorText(e), error: true);
    }
  }

  void _decrement(String productId) =>
      ref.read(cartProvider.notifier).decrementQuantity(productId);

  void _openCart() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CartPanel()));

  void _openHistory() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));

  Future<void> _sync() async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;
    if (!ref.read(isOnlineProvider)) {
      _toast('You are offline. Changes sync when you reconnect.', error: true);
      return;
    }
    await ref
        .read(syncOrchestratorProvider)
        .runSync(businessId: business.id, showToast: true);
  }

  Future<void> _pickLocation(
    List<LocalInventory> list,
    String? currentId,
  ) async {
    final picked = await showModalBottomSheet<LocalInventory>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: _slate200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sell from',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _brand,
                    ),
                  ),
                ),
              ),
              for (final inv in list)
                ListTile(
                  leading: Icon(
                    inv.id == currentId
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: inv.id == currentId ? _brand : _slate400,
                  ),
                  title: Text(
                    inv.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.of(ctx).pop(inv),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      await switchInventoryWithConfirm(context, ref, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the working location changes under a non-empty cart (e.g. access was
    // revoked and the app fell back), the cart no longer matches: clear it.
    ref.listen<AsyncValue<String?>>(currentInventoryIdProvider, (prev, next) {
      final a = prev?.valueOrNull;
      final b = next.valueOrNull;
      if (a != null &&
          b != null &&
          a != b &&
          ref.read(cartProvider).isNotEmpty) {
        ref.read(cartProvider.notifier).clear();
        _toast('Location changed. Cart cleared.', error: true);
      }
    });

    final searched = ref.watch(filteredProductListProvider);
    final all = ref.watch(productListProvider).valueOrNull ?? [];
    final cart = ref.watch(cartProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final cartTotalUsd = ref.watch(cartTotalUsdProvider);
    final rate = ref.watch(currentBusinessProvider)?.currencyRate ?? 0;
    final isSyncing = ref.watch(isSyncingProvider);

    final posList = ref.watch(posInventoriesProvider).valueOrNull;
    final currentId = ref.watch(currentInventoryIdProvider).valueOrNull;
    final currentName = ref.watch(currentInventoryProvider).valueOrNull?.name;
    final canSell =
        posList == null ||
        currentId == null ||
        posList.any((i) => i.id == currentId);
    final noPosAtAll = posList != null && posList.isEmpty && currentId != null;

    // Categories come from the products of the current location
    final counts = productCountsByCategory(all);
    final categories = counts.keys.toList()..sort();
    final selectedRaw = ref.watch(posCategoryProvider);
    final selected = counts.containsKey(selectedRaw) ? selectedRaw : null;

    final products = searched.whenData(
      (list) => filterByCategory(list, selected),
    );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ConnectivityBanner(),
                _header(isSyncing, posList ?? const [], currentId, currentName),
                if (!canSell || noPosAtAll)
                  _noAccessBanner(posList, currentId, currentName, noPosAtAll),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _searchField(),
                ),
                _categoryRow(all.length, categories, counts, selected),
                const SizedBox(height: 4),
                Expanded(
                  child: products.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _errorView(e),
                    data: (items) {
                      if (items.isEmpty) return _emptyView(currentName);
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.76,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final p = items[i];
                          final inCart = cart
                              .where((c) => c.productId == p.id)
                              .fold<int>(0, (s, c) => s + c.quantity);
                          return _PosProductCard(
                            product: p,
                            rate: rate,
                            inCart: inCart,
                            canSell: canSell,
                            onAdd: () => _addToCart(p, canSell),
                            onIncrement: () => _increment(p.id!),
                            onDecrement: () => _decrement(p.id!),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (cartItemCount > 0)
              Positioned(
                left: 16,
                right: 64, // clears the Settings button owned by HomeScreen
                bottom: 12,
                child: _cartBar(cartItemCount, cartTotalUsd),
              ),
          ],
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _header(
    bool isSyncing,
    List<LocalInventory> posList,
    String? currentId,
    String? currentName,
  ) {
    final canSwitch = posList.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASHIER MODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: _purple600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Point of Sale',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: _brand,
                      ),
                    ),
                  ],
                ),
              ),
              _roundIcon(Icons.history_rounded, 'Sales history', _openHistory),
              const SizedBox(width: 8),
              _roundIcon(
                Icons.sync_rounded,
                'Sync now',
                isSyncing ? null : _sync,
                spinning: isSyncing,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: canSwitch
                      ? () => _pickLocation(posList, currentId)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE6F1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _slate200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currentName ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _slate700,
                            ),
                          ),
                        ),
                        if (canSwitch) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _slate400,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // TODO(backend/UI): terminals ("Terminal #01 Active") need a
              // terminals/registers concept. Disabled placeholder.
              Opacity(
                opacity: 0.45,
                child: Tooltip(
                  message: 'Terminals — coming soon',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x99A7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Terminal #— Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(
    IconData icon,
    String tip,
    VoidCallback? onTap, {
    bool spinning = false,
  }) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF3E8FF)),
          ),
          child: spinning
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _brand,
                  ),
                )
              : Icon(icon, size: 20, color: _brand),
        ),
      ),
    );
  }

  Widget _noAccessBanner(
    List<LocalInventory> posList,
    String? currentId,
    String? currentName,
    bool none,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              none
                  ? 'You have no location assigned for sales. Ask the owner to give you POS access.'
                  : "You can't sell from ${currentName ?? 'this location'}. Switch to a location you can sell from.",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          if (!none && posList.isNotEmpty)
            TextButton(
              onPressed: () => _pickLocation(posList, currentId),
              child: const Text('Switch'),
            ),
        ],
      ),
    );
  }

  // ── search + categories ────────────────────────────────────────────────────
  Widget _searchField() {
    final query = ref.watch(productSearchQueryProvider);
    return TextField(
      controller: _searchController,
      onChanged: (v) => ref.read(productSearchQueryProvider.notifier).state = v,
      style: const TextStyle(fontSize: 13, color: _slate900),
      decoration: InputDecoration(
        hintText: 'Search products or SKU...',
        hintStyle: const TextStyle(fontSize: 13, color: _slate400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: _slate400,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _slate400,
                ),
                onPressed: () {
                  _searchController.clear();
                  ref.read(productSearchQueryProvider.notifier).state = '';
                },
              )
            // TODO(backend/UI): barcode scanner needs a scanner package and a
            // barcode column on products. Disabled for now.
            : const Tooltip(
                message: 'Barcode scan — coming soon',
                child: Opacity(
                  opacity: 0.45,
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: _slate400,
                  ),
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _brand, width: 1.5),
        ),
      ),
    );
  }

  Widget _categoryRow(
    int total,
    List<String> categories,
    Map<String, int> counts,
    String? selected,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        children: [
          _CategoryChip(
            label: 'All Items',
            count: total,
            selected: selected == null,
            onTap: () => ref.read(posCategoryProvider.notifier).state = null,
          ),
          for (final c in categories)
            _CategoryChip(
              label: c,
              count: counts[c]!,
              selected: selected == c,
              onTap: () => ref.read(posCategoryProvider.notifier).state = c,
            ),
        ],
      ),
    );
  }

  // ── states ─────────────────────────────────────────────────────────────────
  Widget _errorView(Object e) => Center(
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
  );

  Widget _emptyView(String? locationName) {
    final query = ref.watch(productSearchQueryProvider);
    final hasFilter =
        query.isNotEmpty || ref.watch(posCategoryProvider) != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 64,
              color: _brand.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'No products match your filters'
                  : 'No products in ${locationName ?? 'this location'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 6),
              const Text(
                'Add or transfer stock in the Inventory tab first',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── cart bar ───────────────────────────────────────────────────────────────
  Widget _cartBar(int count, double total) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openCart,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_brand, _brandEnd]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x4DC084FC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x594A154B),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      size: 20,
                      color: Color(0xFFFCD34D),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _brand,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cart • $count ${count == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE9D5FF),
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: '\$${total.toStringAsFixed(2)} ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        children: const [
                          TextSpan(
                            text: 'USD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFE9D5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _brand,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: _brand),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
