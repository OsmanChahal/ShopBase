import 'package:crm_pos/database/app_database.dart';
import 'package:crm_pos/database/sync_queue_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SyncQueueRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('SyncQueueRepository detects failed entries and counts correctly', () async {
    // 1. Initially no pending or failed entries
    expect(await repo.hasPendingOrFailed(), isFalse);
    expect(await repo.hasFailedEntries(), isFalse);
    expect(await repo.getFailedCount(), equals(0));

    // 2. Enqueue an operation
    await repo.enqueue(
      operationType: 'product_upsert',
      payloadJson: '{"name":"Test"}',
    );

    expect(await repo.hasPendingOrFailed(), isTrue);
    expect(await repo.hasFailedEntries(), isFalse);
    expect(await repo.getPendingCount(), equals(1));

    // 3. Mark the entry as failed
    final entries = await repo.getProcessableEntries();
    expect(entries.length, equals(1));
    final entryId = entries.first.id;

    await repo.markFailed(entryId, 'Network timeout');

    expect(await repo.hasPendingOrFailed(), isTrue);
    expect(await repo.hasFailedEntries(), isTrue);
    expect(await repo.getFailedCount(), equals(1));

    // 4. Mark synced after retry
    await repo.markSynced(entryId);

    expect(await repo.hasPendingOrFailed(), isFalse);
    expect(await repo.hasFailedEntries(), isFalse);
    expect(await repo.getFailedCount(), equals(0));
  });
}
