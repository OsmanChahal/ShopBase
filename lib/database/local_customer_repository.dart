import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'sync_queue_repository.dart';

const _uuid = Uuid();

/// Repository for customer CRUD against the local SQLite database.
/// Used by POS customer picker and inline "Add New" customer flow.
class LocalCustomerRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  LocalCustomerRepository(this._db, this._syncQueue);

  /// Fetch all customers for a business, sorted alphabetically.
  Future<List<LocalCustomer>> getCustomers(String businessId) async {
    return (_db.select(_db.localCustomers)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Fetch a single customer by ID.
  Future<LocalCustomer?> getCustomerById(String id) async {
    return (_db.select(
      _db.localCustomers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Check if any customers exist for a business (initial pull guard).
  Future<bool> hasCustomers(String businessId) async {
    final count = countAll();
    final query = _db.selectOnly(_db.localCustomers)
      ..addColumns([count])
      ..where(_db.localCustomers.businessId.equals(businessId));
    final result = await query.getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  /// Update an existing customer. Enqueues a customer_upsert with the
  /// full updated record (customers have no delta-style fields like
  /// products' quantity, so a plain full overwrite is safe here).
  Future<LocalCustomer> updateCustomer({
    required String id,
    required String businessId,
    required String name,
    String? phone,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      await (_db.update(_db.localCustomers)..where((t) => t.id.equals(id))).write(
        LocalCustomersCompanion(name: Value(name), phone: Value(phone)),
      );

      await _syncQueue.enqueue(
        operationType: 'customer_upsert',
        payloadJson: jsonEncode({
          'id': id,
          'business_id': businessId,
          'name': name,
          'phone': phone,
        }),
      );

      return (await getCustomerById(id))!;
    });
  }

  /// Delete a customer. Enqueues a customer_delete operation.
  Future<void> deleteCustomer(String id) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      await (_db.delete(_db.localCustomers)..where((t) => t.id.equals(id))).go();

      await _syncQueue.enqueue(
        operationType: 'customer_delete',
        payloadJson: jsonEncode({'customer_id': id}),
      );
    });
  }

  /// Add a new customer locally. Generates a UUID, inserts into local DB,
  /// and enqueues a customer_upsert operation.
  Future<LocalCustomer> addCustomer({
    required String businessId,
    required String name,
    String? phone,
  }) async {
    // Local write + sync_queue enqueue commit together, so a crash can't leave
    // a change saved locally but never queued for sync.
    return _db.transaction(() async {
      final id = _uuid.v4();
      final now = DateTime.now().toUtc();

      final companion = LocalCustomersCompanion.insert(
        id: id,
        businessId: businessId,
        name: name,
        phone: Value(phone),
        createdAt: now,
        lastSyncedAt: const Value(null),
      );

      await _db.into(_db.localCustomers).insert(companion);

      // Enqueue for sync
      await _syncQueue.enqueue(
        operationType: 'customer_upsert',
        payloadJson: jsonEncode({
          'id': id,
          'business_id': businessId,
          'name': name,
          'phone': phone,
        }),
      );

      return (await getCustomerById(id))!;
    });
  }

  /// Batch insert customers from the initial pull (no sync queue entries needed).
  Future<void> bulkInsertCustomers(
    List<LocalCustomersCompanion> customers,
  ) async {
    await _db.batch((batch) {
      batch.insertAll(_db.localCustomers, customers);
    });
  }
}
