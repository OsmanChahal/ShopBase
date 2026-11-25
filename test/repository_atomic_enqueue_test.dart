import 'package:crm_pos/database/app_database.dart';
import 'package:crm_pos/database/local_customer_repository.dart';
import 'package:crm_pos/database/local_inventory_repository.dart';
import 'package:crm_pos/database/local_product_repository.dart';
import 'package:crm_pos/database/sync_queue_repository.dart';
import 'package:drift/drift.dart' show TableInfo;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A queue whose enqueue fails, simulating a crash/error between the local
/// write and queueing it for sync.
class FailingQueue extends SyncQueueRepository {
  FailingQueue(super.db);

  @override
  Future<void> enqueue({
    required String operationType,
    required String payloadJson,
  }) async {
    throw StateError('enqueue failed');
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> count(TableInfo table) async =>
      (await db.select(table).get()).length;

  group('when enqueue fails, the local write is rolled back', () {
    test('addCustomer', () async {
      final repo = LocalCustomerRepository(db, FailingQueue(db));
      await expectLater(
        repo.addCustomer(businessId: 'b', name: 'Rami'),
        throwsStateError,
      );
      expect(await count(db.localCustomers), 0);
    });

    test('addProduct', () async {
      final repo = LocalProductRepository(db, FailingQueue(db));
      await expectLater(
        repo.addProduct(
          businessId: 'b',
          name: 'Cola',
          costPriceUsd: 0.5,
          sellPriceUsd: 1,
          quantity: 10,
        ),
        throwsStateError,
      );
      expect(await count(db.localProducts), 0);
    });

    test('createInventory', () async {
      final repo = LocalInventoryRepository(db, FailingQueue(db));
      await expectLater(
        repo.createInventory(businessId: 'b', name: 'Main'),
        throwsStateError,
      );
      expect(await count(db.localInventories), 0);
    });

    test('deleteCustomer keeps the customer', () async {
      final ok = LocalCustomerRepository(db, SyncQueueRepository(db));
      final c = await ok.addCustomer(businessId: 'b', name: 'Lina');
      final failing = LocalCustomerRepository(db, FailingQueue(db));
      await expectLater(failing.deleteCustomer(c.id), throwsStateError);
      expect(await count(db.localCustomers), 1);
    });
  });

  test('on success the write and its queue entry are both saved', () async {
    final queue = SyncQueueRepository(db);
    final repo = LocalCustomerRepository(db, queue);
    await repo.addCustomer(businessId: 'b', name: 'Rami');
    expect(await count(db.localCustomers), 1);
    expect(await queue.getPendingCount(), 1);
  });
}
