import 'package:crm_pos/sync/supabase_paging.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal stand-in for a PostgREST query: records order() calls and serves
/// range() slices from an in-memory table, like Supabase's capped pages.
class FakeQuery {
  final List<Map<String, dynamic>> table;
  final List<String> orders = [];
  static int requests = 0;

  FakeQuery(this.table);

  FakeQuery order(String column) {
    orders.add(column);
    return this;
  }

  Future<List<dynamic>> range(int from, int to) async {
    requests++;
    if (from >= table.length) return [];
    final end = (to + 1).clamp(0, table.length);
    return table.sublist(from, end);
  }
}

List<Map<String, dynamic>> rows(int n) =>
    [for (var i = 0; i < n; i++) {'id': 'r$i'}];

void main() {
  setUp(() => FakeQuery.requests = 0);

  test('returns every row past the 1000-row cap', () async {
    final table = rows(2500);
    final result = await fetchAllPages(() => FakeQuery(table), ['id']);
    expect(result.length, 2500);
    expect(result.map((r) => r['id']).toSet().length, 2500); // no repeats
    expect(FakeQuery.requests, 3);
  });

  test('stops after one request for small tables', () async {
    final result = await fetchAllPages(() => FakeQuery(rows(10)), ['id']);
    expect(result.length, 10);
    expect(FakeQuery.requests, 1);
  });

  test('an exact multiple of the page size makes one extra empty request',
      () async {
    final result = await fetchAllPages(() => FakeQuery(rows(2000)), ['id']);
    expect(result.length, 2000);
    expect(FakeQuery.requests, 3);
  });

  test('applies the order columns to every page', () async {
    final seen = <List<String>>[];
    await fetchAllPages(() {
      final q = FakeQuery(rows(1500));
      seen.add(q.orders);
      return q;
    }, ['product_id', 'inventory_id']);
    expect(seen, hasLength(2));
    for (final o in seen) {
      expect(o, ['product_id', 'inventory_id']);
    }
  });
}
