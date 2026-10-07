import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/local_product_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/inventory_design.dart';

const _p50 = Color(0xFFFAF5FF);
const _p100 = Color(0xFFF3E8FF);
const _p200 = Color(0xFFE9D5FF);
const _p600 = Color(0xFF9333EA);
const _p700 = Color(0xFF7E22CE);
const _p800 = Color(0xFF6B21A8);
const _slate50 = Color(0xFFF8FAFC);

/// Inventories the user may move stock in/out of (owner/admin: all;
/// staff: only those where they hold can_edit).
final editableInventoriesProvider = FutureProvider<List<LocalInventory>>((
  ref,
) async {
  final list = await ref.watch(accessibleInventoriesProvider.future);
  if (ref.watch(isAdminProvider)) return list;
  final userId = ref.watch(currentMemberProvider)?.userId;
  if (userId == null) return [];
  final db = ref.watch(appDatabaseProvider);
  final grants = await (db.select(
    db.localInventoryAccess,
  )..where((t) => t.userId.equals(userId) & t.canEdit.equals(true))).get();
  final ids = grants.map((g) => g.inventoryId).toSet();
  return list.where((i) => ids.contains(i.id)).toList();
});

/// Opens the transfer sheet. Returns true if a transfer was made.
Future<bool?> showTransferStockSheet(
  BuildContext context, {
  String? fromInventoryId,
  String? toInventoryId,
  List<String> productIds = const [],
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TransferStockSheet(
      fromInventoryId: fromInventoryId,
      toInventoryId: toInventoryId,
      productIds: productIds,
    ),
  );
}

class _Line {
  final String productId;
  int qty;
  _Line(this.productId, this.qty);
}

class TransferStockSheet extends ConsumerStatefulWidget {
  final String? fromInventoryId;
  final String? toInventoryId;
  final List<String> productIds;
  const TransferStockSheet({
    super.key,
    this.fromInventoryId,
    this.toInventoryId,
    this.productIds = const [],
  });

  @override
  ConsumerState<TransferStockSheet> createState() => _TransferStockSheetState();
}

class _TransferStockSheetState extends ConsumerState<TransferStockSheet> {
  String? _fromId;
  String? _toId;
  final List<_Line> _lines = [];
  List<ProductWithStock> _fromRows = [];
  List<ProductWithStock> _toRows = [];
  List<LocalInventory> _inventories = [];
  String? _primaryId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    final list = await ref.read(editableInventoriesProvider.future);
    final primary = await ref.read(primaryInventoryIdProvider.future);
    if (!mounted) return;
    _inventories = list;
    _primaryId = primary;

    final current = ref.read(currentInventoryIdProvider).valueOrNull;
    _fromId =
        widget.fromInventoryId ??
        (list.any((i) => i.id == current) ? current : null) ??
        (list.isNotEmpty ? list.first.id : null);
    _toId =
        widget.toInventoryId ??
        list.where((i) => i.id != _fromId).map((i) => i.id).firstOrNull;

    await _reload();
    if (!mounted) return;
    setState(() {
      for (final pid in widget.productIds) {
        final src = _src(pid);
        if (src != null && src.stock.quantity > 0) _lines.add(_Line(pid, 1));
      }
      _loading = false;
    });
  }

  /// Re-reads both inventories and drops/clamps lines that no longer fit.
  Future<void> _reload() async {
    final biz = ref.read(currentBusinessProvider);
    if (biz == null) return;
    final repo = ref.read(localProductRepositoryProvider);
    final from = _fromId == null
        ? <ProductWithStock>[]
        : await repo.getProductsForInventory(biz.id, _fromId!);
    final to = _toId == null
        ? <ProductWithStock>[]
        : await repo.getProductsForInventory(biz.id, _toId!);
    if (!mounted) return;
    setState(() {
      _fromRows = from;
      _toRows = to;
      _lines.removeWhere((l) => _maxFor(l.productId) <= 0);
      for (final l in _lines) {
        final m = _maxFor(l.productId);
        if (l.qty > m) l.qty = m;
      }
      _error = null;
    });
  }

  // ── lookups ────────────────────────────────────────────────────────────────
  ProductWithStock? _src(String pid) {
    for (final r in _fromRows) {
      if (r.product.id == pid) return r;
    }
    return null;
  }

  ProductWithStock? _dst(String pid) {
    for (final r in _toRows) {
      if (r.product.id == pid) return r;
    }
    return null;
  }

  LocalInventory? _inv(String? id) {
    if (id == null) return null;
    for (final i in _inventories) {
      if (i.id == id) return i;
    }
    return null;
  }

  int _maxFor(String pid) => _src(pid)?.stock.quantity ?? 0;
  int get _totalQty => _lines.fold(0, (a, l) => a + l.qty);

  bool get _valid =>
      _fromId != null &&
      _toId != null &&
      _fromId != _toId &&
      _lines.isNotEmpty &&
      _lines.every((l) => l.qty > 0 && l.qty <= _maxFor(l.productId));

  // ── pickers ────────────────────────────────────────────────────────────────
  Future<String?> _pickInventory({String? exclude}) {
    final options = _inventories.where((i) => i.id != exclude).toList();
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final i in options)
              ListTile(
                leading: const Icon(Icons.warehouse_outlined),
                title: Text(i.name),
                onTap: () => Navigator.of(ctx).pop(i.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickProduct() {
    final used = _lines.map((l) => l.productId).toSet();
    final options = _fromRows
        .where((r) => r.stock.quantity > 0 && !used.contains(r.product.id))
        .toList();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: options.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No more products with stock in this location',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in options)
                      ListTile(
                        title: Text(r.product.name),
                        subtitle: Text('${r.stock.quantity} units available'),
                        onTap: () => Navigator.of(ctx).pop(r.product.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────
  Future<void> _changeFrom(String id) async {
    _fromId = id;
    if (_toId == id) {
      _toId = _inventories
          .where((i) => i.id != id)
          .map((i) => i.id)
          .firstOrNull;
    }
    await _reload();
  }

  Future<void> _swap() async {
    final f = _fromId;
    _fromId = _toId;
    _toId = f;
    await _reload();
  }

  void _setQty(_Line l, int q) {
    final max = _maxFor(l.productId);
    if (max < 1) return;
    setState(() => l.qty = q.clamp(1, max).toInt());
  }

  Future<void> _addItem() async {
    final pid = await _pickProduct();
    if (pid == null) return;
    setState(() => _lines.add(_Line(pid, 1)));
  }

  Future<void> _changeItem(int index) async {
    final pid = await _pickProduct();
    if (pid == null) return;
    setState(() => _lines[index] = _Line(pid, 1));
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(inventoryActionsProvider)
          .transfer(
            fromId: _fromId!,
            toId: _toId!,
            items: [for (final l in _lines) TransferLine(l.productId, l.qty)],
          );
      if (!mounted) return;
      final units = _totalQty;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transferred $units units')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── projection ─────────────────────────────────────────────────────────────
  ({int before, int after, int lowBefore, int lowAfter}) _project(bool source) {
    final moved = {for (final l in _lines) l.productId: l.qty};
    final rows = source ? _fromRows : _toRows;
    var before = 0, after = 0, lowBefore = 0, lowAfter = 0;
    for (final r in rows) {
      final q = r.stock.quantity;
      final t = r.stock.lowStockThreshold;
      final m = moved[r.product.id] ?? 0;
      final a = source ? q - m : q + m;
      before += q;
      after += a;
      if (q <= t) lowBefore++;
      if (a <= t) lowAfter++;
    }
    if (!source) {
      // products the destination doesn't stock yet (row is created on transfer)
      for (final l in _lines) {
        if (_dst(l.productId) == null) {
          final s = _src(l.productId);
          after += l.qty;
          if (s != null && l.qty <= s.stock.lowStockThreshold) lowAfter++;
        }
      }
    }
    return (
      before: before,
      after: after,
      lowBefore: lowBefore,
      lowAfter: lowAfter,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.92;
    final notEnough = !_loading && _inventories.length < 2;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 44,
                height: 6,
                decoration: BoxDecoration(
                  color: InvDesign.slate200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            _header(),
            const Divider(height: 1, color: InvDesign.slate100),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : notEnough
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'You need at least two locations you are allowed '
                        'to edit before you can move stock.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: InvDesign.slate500),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _routeCard(),
                          const SizedBox(height: 20),
                          _itemsSection(),
                          const SizedBox(height: 20),
                          _projectionCard(),
                          const SizedBox(height: 20),
                          _methodSection(),
                        ],
                      ),
                    ),
            ),
            if (!notEnough && !_loading) _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Transfer Stock',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: InvDesign.slate900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // TODO(backend): batch numbers (TR-408) need a sequence
                    // column on stock_transfers. Disabled placeholder.
                    Opacity(
                      opacity: 0.45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _p50,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _p100),
                        ),
                        child: const Text(
                          'Batch #—',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _p700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Move inventory between active locations',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: InvDesign.slate500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: InvDesign.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: InvDesign.slate500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── route card ─────────────────────────────────────────────────────────────
  Widget _routeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvDesign.slate200),
      ),
      child: Column(
        children: [
          _locationRow(true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Expanded(child: Divider(color: InvDesign.slate200)),
                InkWell(
                  onTap: _swap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: InvDesign.slate200),
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: _p700,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: InvDesign.slate200)),
              ],
            ),
          ),
          _locationRow(false),
        ],
      ),
    );
  }

  Widget _locationRow(bool isFrom) {
    final id = isFrom ? _fromId : _toId;
    final inv = _inv(id);
    final rows = isFrom ? _fromRows : _toRows;
    final units = rows.fold<int>(0, (a, r) => a + r.stock.quantity);
    final low = rows
        .where((r) => r.stock.quantity <= r.stock.lowStockThreshold)
        .length;

    final showLow = !isFrom && low > 0;
    final badgeText = showLow
        ? 'Low Stock Alert ($low ${low == 1 ? 'item' : 'items'})'
        : '$units Units In Stock';
    final badgeFg = showLow ? InvDesign.amber600 : const Color(0xFF059669);
    final badgeBg = showLow ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isFrom ? 'SOURCE LOCATION (FROM)' : 'DESTINATION (TO)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: InvDesign.slate400,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeFg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await _pickInventory(
              exclude: isFrom ? _toId : _fromId,
            );
            if (picked == null) return;
            if (isFrom) {
              await _changeFrom(picked);
            } else {
              _toId = picked;
              await _reload();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isFrom
                  ? Border.all(color: InvDesign.slate200)
                  : Border.all(color: const Color(0xFFA855F7), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isFrom ? _p700 : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isFrom
                        ? Icons.apartment_rounded
                        : Icons.shopping_bag_outlined,
                    size: 18,
                    color: isFrom ? Colors.white : const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv?.name ?? 'Select location',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: InvDesign.slate900,
                        ),
                      ),
                      Text(
                        '${id == _primaryId ? 'Primary • ' : ''}'
                        '${rows.length} products • $units units',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: InvDesign.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: InvDesign.slate400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── items ──────────────────────────────────────────────────────────────────
  Widget _itemsSection() {
    final hasMore = _fromRows.any(
      (r) =>
          r.stock.quantity > 0 &&
          !_lines.any((l) => l.productId == r.product.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECT PRODUCT TO MOVE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: InvDesign.slate900,
              ),
            ),
            if (_lines.isNotEmpty && hasMore)
              InkWell(
                onTap: _addItem,
                child: const Text(
                  '+ Add Multiple Items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _p700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lines.isEmpty)
          InkWell(
            onTap: _addItem,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _p200, width: 1.5),
                color: _p50,
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: _p700),
                  SizedBox(height: 6),
                  Text(
                    'Tap to choose a product',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _p700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (var i = 0; i < _lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _lineCard(i),
            ),
      ],
    );
  }

  Widget _lineCard(int index) {
    final l = _lines[index];
    final src = _src(l.productId);
    if (src == null) return const SizedBox.shrink();
    final dst = _dst(l.productId);
    final max = src.stock.quantity;
    final fromName = _inv(_fromId)?.name ?? '';
    final toName = _inv(_toId)?.name ?? '';
    final destQty = dst?.stock.quantity ?? 0;
    final destLow = dst != null && destQty <= dst.stock.lowStockThreshold;
    final srcLow = src.stock.quantity <= src.stock.lowStockThreshold;
    final sku = src.product.sku;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _p600, width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: InvDesign.amber600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            src.product.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: InvDesign.slate900,
                            ),
                          ),
                        ),
                        if (srcLow || destLow) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // TODO(backend): batch numbers (#IH-992) need a batch column.
                    Text(
                      '\$${src.stock.sellPriceUsd.toStringAsFixed(2)} / unit'
                      '${sku != null && sku.isNotEmpty ? ' • SKU $sku' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: InvDesign.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          color: InvDesign.slate500,
                        ),
                        children: [
                          TextSpan(text: 'At $fromName: '),
                          TextSpan(
                            text: '$max units',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: InvDesign.slate700,
                            ),
                          ),
                          const TextSpan(text: '  •  '),
                          TextSpan(
                            text: 'At $toName: ',
                            style: TextStyle(
                              color: destLow
                                  ? InvDesign.amber600
                                  : InvDesign.slate500,
                            ),
                          ),
                          TextSpan(
                            text: destLow
                                ? '$destQty units (Low)'
                                : '$destQty units',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: destLow
                                  ? InvDesign.amber600
                                  : InvDesign.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  InkWell(
                    onTap: () => _changeItem(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _p50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _p700,
                        ),
                      ),
                    ),
                  ),
                  if (_lines.length > 1)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20,
                        color: InvDesign.slate400,
                      ),
                      tooltip: 'Remove',
                      onPressed: () => setState(() => _lines.removeAt(index)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: InvDesign.slate100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transfer Quantity',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: InvDesign.slate700,
                ),
              ),
              Row(
                children: [
                  _stepBtn(
                    '−',
                    InvDesign.slate100,
                    InvDesign.slate700,
                    () => _setQty(l, l.qty - 1),
                  ),
                  Container(
                    width: 56,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _p200),
                    ),
                    child: Text(
                      '${l.qty}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _p800,
                      ),
                    ),
                  ),
                  _stepBtn('+', _p100, _p800, () => _setQty(l, l.qty + 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // TODO(backend): the "(Restock)" suggested amount needs restock logic.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Presets:',
                style: TextStyle(fontSize: 11, color: InvDesign.slate400),
              ),
              _preset('+10', () => _setQty(l, l.qty + 10)),
              _preset('+25', () => _setQty(l, l.qty + 25)),
              _preset('+50', () => _setQty(l, l.qty + 50)),
              _preset('Max ($max)', () => _setQty(l, max)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _preset(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: InvDesign.slate100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: InvDesign.slate600,
          ),
        ),
      ),
    );
  }

  // ── projection card ────────────────────────────────────────────────────────
  Widget _projectionCard() {
    final s = _project(true);
    final d = _project(false);
    final resolved = d.lowBefore > 0 && d.lowAfter == 0 && _lines.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xB3FAF5FF), Color(0x80ECFDF5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _p100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 15, color: _p700),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Projected Stock After Transfer',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: InvDesign.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (resolved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3D1FAE5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Low Stock Resolved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _projBox(_inv(_fromId)?.name ?? '', s, true)),
              const SizedBox(width: 8),
              Expanded(child: _projBox(_inv(_toId)?.name ?? '', d, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _projBox(
    String name,
    ({int before, int after, int lowBefore, int lowAfter}) p,
    bool source,
  ) {
    final healthy = p.lowAfter == 0;
    final status = healthy
        ? (source ? 'Still Healthy' : 'Optimal (Healthy)')
        : '${p.lowAfter} ${p.lowAfter == 1 ? 'item' : 'items'} low';
    final color = healthy ? const Color(0xFF059669) : InvDesign.amber600;
    final delta = _totalQty;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _p100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: InvDesign.slate500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${p.after} units',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: InvDesign.slate700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                source ? '(-$delta)' : '(+$delta)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: source
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── method + note ──────────────────────────────────────────────────────────
  Widget _methodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSFER REASON & DISPATCH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: InvDesign.slate900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _modeCard(
                'Instant Transfer',
                'Immediate stock update',
                selected: true,
                enabled: true,
              ),
            ),
            const SizedBox(width: 8),
            // TODO(backend): in-transit mode (dispatch, then arrival check).
            // Product decision for now: instant transfers only.
            Expanded(
              child: _modeCard(
                'In-Transit Dispatch',
                'Requires arrival check',
                selected: false,
                enabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // TODO(backend): transfer notes need a `note` column on stock_transfers.
        Opacity(
          opacity: 0.45,
          child: Tooltip(
            message: 'Coming soon',
            child: TextField(
              enabled: false,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Add transfer note (e.g., Driver: Ahmad, Van #2)...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: InvDesign.slate400,
                ),
                filled: true,
                fillColor: _slate50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: InvDesign.slate200),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: InvDesign.slate200),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeCard(
    String title,
    String sub, {
    required bool selected,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x80FAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _p600 : InvDesign.slate200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: selected ? _p700 : InvDesign.slate400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? InvDesign.slate900 : InvDesign.slate700,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 10,
                      color: InvDesign.slate500,
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

  // ── footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    final enabled = _valid && !_submitting;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: InvDesign.slate100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusError,
                ),
              ),
            ),
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: enabled ? _submit : null,
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_p700, Color(0xFF4338CA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D9333EA),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _totalQty > 0
                                    ? 'Confirm Transfer ($_totalQty ${_totalQty == 1 ? 'Unit' : 'Units'})'
                                    : 'Confirm Transfer',
                                style: const TextStyle(
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
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel & Return to Inventory',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: InvDesign.slate500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
