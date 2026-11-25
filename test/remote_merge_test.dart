import 'package:crm_pos/database/app_database.dart';
import 'package:crm_pos/sync/remote_merge.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.utc(2026, 11, 25, 12);

Map<String, dynamic> remoteSale(String id, {double usd = 10}) => {
      'id': id,
      'business_id': 'b',
      'customer_id': null,
      'total_usd': usd,
      'total_lbp': usd * 89500,
      'exchange_rate_used': 89500,
      'payment_type': 'cash',
      'created_at': '2026-11-20T10:00:00Z',
      'inventory_id': 'inv1',
    };

Map<String, dynamic> remoteItem(String id, String saleId) => {
      'id': id,
      'sale_id': saleId,
      'product_id': 'p1',
      'product_name_snapshot': 'Cola',
      'quantity': 2,
      'unit_price_usd': 5,
      'subtotal_usd': 10,
      'cost_price_snapshot': 3,
    };

Map<String, dynamic> remoteCustomer(String id, String name, [String? phone]) =>
    {
      'id': id,
      'business_id': 'b',
      'name': name,
      'phone': phone,
      'created_at': '2026-01-01T00:00:00Z',
    };

Map<String, dynamic> remoteProduct(String id, String name) => {
      'id': id,
      'business_id': 'b',
      'name': name,
      'sku': null,
      'category': null,
      'cost_price_usd': 1,
      'sell_price_usd': 2,
      'quantity': 5,
      'low_stock_threshold': 3,
      'updated_at': '2026-11-01T00:00:00Z',
    };

void main() {
  late AppDatabase db;
  late RemoteMerge merge;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    merge = RemoteMerge(db);
  });
  tearDown(() => db.close());

  Future<void> addLocalCustomer(String id, String name) => db
      .into(db.localCustomers)
      .insert(LocalCustomersCompanion.insert(
        id: id,
        businessId: 'b',
        name: name,
        createdAt: DateTime.utc(2026),
      ));

  Future<void> addLocalProduct(String id, {String name = 'Local'}) async {
    await db.into(db.localProducts).insert(LocalProductsCompanion.insert(
          id: id,
          businessId: 'b',
          name: name,
          costPriceUsd: 1,
          sellPriceUsd: 2,
          quantity: 1,
        ));
    await db.into(db.localInventoryStock).insert(
        LocalInventoryStockCompanion.insert(
            productId: id,
            inventoryId: 'inv1',
            sellPriceUsd: 2,
            costPriceUsd: 1));
  }

  group('sales from other devices (item 2)', () {
    test('adds missing sales with their items', () async {
      final added = await merge.insertMissingSales(
        'b',
        [remoteSale('s1'), remoteSale('s2')],
        [remoteItem('i1', 's1'), remoteItem('i2', 's2'), remoteItem('i3', 's2')],
      );
      expect(added, 2);
      expect((await db.select(db.localSales).get()).length, 2);
      expect((await db.select(db.localSaleItems).get()).length, 3);
      final s1 = await (db.select(db.localSales)
            ..where((t) => t.id.equals('s1')))
          .getSingle();
      expect(s1.synced, isTrue);
      expect(s1.inventoryId, 'inv1');
    });

    test('never overwrites a sale already on this device', () async {
      await merge.insertMissingSales('b', [remoteSale('s1', usd: 10)], []);
      final added = await merge.insertMissingSales(
          'b', [remoteSale('s1', usd: 999)], [remoteItem('i9', 's1')]);
      expect(added, 0);
      final s1 = await db.select(db.localSales).getSingle();
      expect(s1.totalUsd, 10);
      expect(await db.select(db.localSaleItems).get(), isEmpty);
    });
  });

  group('customers mirror (item 3)', () {
    test('applies edits, adds new and removes deleted customers', () async {
      await addLocalCustomer('c1', 'Old name');
      await addLocalCustomer('c2', 'Deleted elsewhere');
      await merge.mirrorCustomers(
        'b',
        [remoteCustomer('c1', 'New name', '+96170123456'), remoteCustomer('c3', 'New')],
        syncedAt: now,
      );
      final rows = {
        for (final c in await db.select(db.localCustomers).get()) c.id: c
      };
      expect(rows.keys.toSet(), {'c1', 'c3'});
      expect(rows['c1']!.name, 'New name');
      expect(rows['c1']!.phone, '+96170123456');
    });

    test('an empty server answer never wipes local customers', () async {
      await addLocalCustomer('c1', 'Keep');
      await merge.mirrorCustomers('b', [], syncedAt: now);
      expect((await db.select(db.localCustomers).get()).length, 1);
    });

    test('a refused customer delete is restored', () async {
      // Deleted locally, but the server refused, so it still has it.
      await merge.mirrorCustomers('b', [remoteCustomer('c1', 'Rami')],
          syncedAt: now);
      expect((await db.select(db.localCustomers).get()).single.name, 'Rami');
    });
  });

  group('products (items 3 and 4)', () {
    test('removes products deleted on the server, with their stock', () async {
      await addLocalProduct('p1');
      await addLocalProduct('p2');
      final removed = await merge.removeProductsNotOnServer('b', {'p1'});
      expect(removed, 1);
      expect((await db.select(db.localProducts).get()).map((p) => p.id), ['p1']);
      expect(
          (await db.select(db.localInventoryStock).get()).map((s) => s.productId),
          ['p1']);
    });

    test('an empty server id set never wipes local products', () async {
      await addLocalProduct('p1');
      expect(await merge.removeProductsNotOnServer('b', {}), 0);
      expect((await db.select(db.localProducts).get()).length, 1);
    });

    test('restores a product whose delete the server refused', () async {
      await merge.insertMissingProducts([remoteProduct('p1', 'Cola')],
          syncedAt: now);
      final p = await db.select(db.localProducts).getSingle();
      expect(p.name, 'Cola');
      expect(p.lastSyncedAt!.isAtSameMomentAs(now), isTrue);
    });

    test('a refused product edit is replaced by the server version',
        () async {
      await addLocalProduct('p1', name: 'Refused local edit');
      await merge.restoreProduct('p1', remoteProduct('p1', 'Server name'));
      expect((await db.select(db.localProducts).getSingle()).name,
          'Server name');
      // stock rows are kept (they are re-synced by the stock pull)
      expect((await db.select(db.localInventoryStock).get()).length, 1);
    });

    test('a refused product create is removed with its stock', () async {
      await addLocalProduct('p1');
      await merge.restoreProduct('p1', null);
      expect(await db.select(db.localProducts).get(), isEmpty);
      expect(await db.select(db.localInventoryStock).get(), isEmpty);
    });

    test('does not overwrite an existing local product', () async {
      await addLocalProduct('p1', name: 'Local edit');
      await merge.insertMissingProducts([remoteProduct('p1', 'Server')],
          syncedAt: now);
      expect((await db.select(db.localProducts).getSingle()).name, 'Local edit');
    });
  });
}
