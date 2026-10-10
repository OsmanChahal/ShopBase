import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_actions_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';

class DebugInventoryScreen extends ConsumerStatefulWidget {
  const DebugInventoryScreen({super.key});
  @override
  ConsumerState<DebugInventoryScreen> createState() => _S();
}

class _S extends ConsumerState<DebugInventoryScreen> {
  String _out = '';
  void _log(String s) => setState(() => _out = '$s\n$_out');

  Future<void> _run(String label, Future<dynamic> Function() f) async {
    try {
      final r = await f();
      _log('OK  $label ${r ?? ''}');
    } catch (e) {
      _log('ERR $label: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<List<dynamic>> _invs() =>
      ref.read(accessibleInventoriesProvider.future);

  Future<void> _transfer(int qty) async {
    final invs = await _invs();
    if (invs.length < 2) throw Exception('Create a second inventory first');
    final biz = ref.read(currentBusinessProvider)!;
    final from = invs.first, to = invs.last;
    final prods = await ref
        .read(localProductRepositoryProvider)
        .getProductsForInventory(biz.id, from.id);
    if (prods.isEmpty) throw Exception('No products in ${from.name}');
    final p = prods.first;
    await ref
        .read(inventoryActionsProvider)
        .transfer(
          fromId: from.id,
          toId: to.id,
          items: [TransferLine(p.product.id, qty)],
        );
  }

  Future<String> _dump() async {
    final db = ref.read(appDatabaseProvider);
    final invs = await db.select(db.localInventories).get();
    final stock = await db.select(db.localInventoryStock).get();
    final q = await db.select(db.syncQueueEntries).get();
    final b = StringBuffer('INVENTORIES\n');
    for (final i in invs) {
      final rows = stock.where((s) => s.inventoryId == i.id);
      b.writeln(
        '${i.name}${i.isArchived ? " [archived]" : ""}: '
        '${rows.length} products, ${rows.fold<int>(0, (a, r) => a + r.quantity)} units',
      );
    }
    b.writeln('QUEUE');
    for (final e in q.where((e) => e.status != 'synced')) {
      b.writeln(
        '${e.operationType} ${e.status} r${e.retryCount} ${e.lastError ?? ""}',
      );
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.read(inventoryActionsProvider);
    Widget btn(String t, Future<dynamic> Function() f) =>
        OutlinedButton(onPressed: () => _run(t, f), child: Text(t));
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG inventories')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                btn('Create Branch B', () => a.create('Branch B')),
                btn(
                  'Rename last -> Branch C',
                  () async => a.rename((await _invs()).last.id, 'Branch C'),
                ),
                btn('Transfer 1 (first->last)', () => _transfer(1)),
                btn('Transfer 99999', () => _transfer(99999)),
                btn(
                  'Archive last',
                  () async => a.archive((await _invs()).last.id),
                ),
                btn('Dump', _dump),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _out,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
