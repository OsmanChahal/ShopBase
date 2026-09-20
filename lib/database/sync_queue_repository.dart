import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

const _uuid = Uuid();

/// Enqueues operations into the sync_queue table.
/// Every local write calls this to record the operation for session 2's sync engine.
class SyncQueueRepository {
  final AppDatabase _db;

  SyncQueueRepository(this._db);

  /// Enqueue a sync operation with the given type and JSON payload.
  Future<void> enqueue({
    required String operationType,
    required String payloadJson,
  }) async {
    await _db
        .into(_db.syncQueueEntries)
        .insert(
          SyncQueueEntriesCompanion.insert(
            id: _uuid.v4(),
            operationType: operationType,
            payloadJson: payloadJson,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Get the count of pending operations (useful for debugging).
  Future<int> getPendingCount() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('pending'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Get all pending entries (for debug inspection).
  Future<List<SyncQueueEntry>> getAllPending() async {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get all entries ready to be processed by the sunc engine
  Future<List<SyncQueueEntry>> getProcessableEntries() async {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.isIn(['pending', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Check if there are pending or failed operations awaiting sync.
  Future<bool> hasPendingOrFailed() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.isIn(['pending', 'failed']));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Check if there are any failed operations awaiting retry.
  Future<bool> hasFailedEntries() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('failed'));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Get the count of failed operations.
  Future<int> getFailedCount() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('failed'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Mark the record status synced
  Future<void> markSynced(String id) async {
    await (_db.update(_db.syncQueueEntries)..where((t) => t.id.equals(id)))
        .write(const SyncQueueEntriesCompanion(status: Value('synced')));
  }

  /// Mark the record status failed with error message and increment retry count
  Future<void> markFailed(String id, String error) async {
    final entry = await (_db.select(_db.syncQueueEntries)..where((t) => t.id.equals(id))).getSingleOrNull();
    final currentRetry = entry?.retryCount ?? 0;
    await (_db.update(_db.syncQueueEntries)..where((t) => t.id.equals(id)))
        .write(SyncQueueEntriesCompanion(
          status: const Value('failed'),
          retryCount: Value(currentRetry + 1),
          lastError: Value(error),
        ));
  }
}

