import 'package:crm_pos/database/app_database.dart';
import 'package:crm_pos/database/local_inventory_repository.dart';
import 'package:crm_pos/database/sync_queue_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalInventoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalInventoryRepository(db, SyncQueueRepository(db));
  });

  tearDown(() => db.close());

  test('createInventory accepts 40 characters and rejects 41', () async {
    await repo.createInventory(businessId: 'b', name: 'x' * 40);
    expect(
      () => repo.createInventory(businessId: 'b', name: 'y' * 41),
      throwsA(isA<Exception>().having((e) => '$e', 'message',
          contains('under 40 characters'))),
    );
  });

  test('renameInventory enforces the same limit', () async {
    final id = await repo.createInventory(businessId: 'b', name: 'Main');
    expect(
      () => repo.renameInventory(id, 'z' * 41),
      throwsA(isA<Exception>()),
    );
    await repo.renameInventory(id, 'z' * 40); // allowed
  });

  test('empty names are still rejected', () async {
    expect(
      () => repo.createInventory(businessId: 'b', name: '   '),
      throwsA(isA<Exception>().having(
          (e) => '$e', 'message', contains('Inventory name is required'))),
    );
  });
}
