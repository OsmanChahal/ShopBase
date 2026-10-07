import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

const _uuid = Uuid();

/// Enqueues operations into the sync_queue table.
/// Every local write calls this to record the operation for the sync engine.
class SyncQueueRepository {
  final AppDatabase _db;
  final _changeController = StreamController<void>.broadcast();

  SyncQueueRepository(this._db);

  /// Fires every time a new operation is enqueued — the sync orchestrator
  /// listens to this to trigger an immediate (debounced) sync.
  Stream<void> get onQueueChanged => _changeController.stream;

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
    _changeController.add(null);
  }

  Future<int> getPendingCount() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('pending'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<List<SyncQueueEntry>> getAllPending() async {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  static const int maxRetries = 5;

  Future<List<SyncQueueEntry>> getProcessableEntries() async {
    return (_db.select(_db.syncQueueEntries)
          ..where(
            (t) =>
                t.status.equals('pending') |
                (t.status.equals('failed') &
                    t.retryCount.isSmallerThanValue(maxRetries)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> getProcessableCount() async {
    final t = _db.syncQueueEntries;
    final count = countAll();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(
        t.status.equals('pending') |
            (t.status.equals('failed') &
                t.retryCount.isSmallerThanValue(maxRetries)),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // NEW: the server permanently refused this operation.
  Future<void> markRejected(String id, String error) async {
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.id.equals(id))).write(
      SyncQueueEntriesCompanion(
        status: const Value('rejected'),
        lastError: Value(error),
      ),
    );
  }

  // NEW: network/auth problem. Stays pending, retry count untouched.
  Future<void> noteTransientError(String id, String error) async {
    await (_db.update(_db.syncQueueEntries)..where((t) => t.id.equals(id)))
        .write(SyncQueueEntriesCompanion(lastError: Value(error)));
  }

  // NEW: housekeeping.
  Future<void> deleteOldFinished() async {
    final now = DateTime.now().toUtc();
    final t = _db.syncQueueEntries;
    await (_db.delete(t)..where(
          (r) =>
              (r.status.equals('synced') &
                  r.createdAt.isSmallerThanValue(
                    now.subtract(const Duration(days: 1)),
                  )) |
              (r.status.equals('rejected') &
                  r.createdAt.isSmallerThanValue(
                    now.subtract(const Duration(days: 7)),
                  )),
        ))
        .go();
  }

  Future<bool> hasPendingOrFailed() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.isIn(['pending', 'failed']));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  Future<bool> hasFailedEntries() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('failed'));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  Future<int> getFailedCount() async {
    final count = countAll();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([count])
      ..where(_db.syncQueueEntries.status.equals('failed'));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> markSynced(String id) async {
    await (_db.update(_db.syncQueueEntries)..where((t) => t.id.equals(id)))
        .write(const SyncQueueEntriesCompanion(status: Value('synced')));
  }

  Future<void> markFailed(String id, String error) async {
    final entry = await (_db.select(
      _db.syncQueueEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final currentRetry = entry?.retryCount ?? 0;
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.id.equals(id))).write(
      SyncQueueEntriesCompanion(
        status: const Value('failed'),
        retryCount: Value(currentRetry + 1),
        lastError: Value(error),
      ),
    );
  }

  void dispose() {
    _changeController.close();
  }
}
