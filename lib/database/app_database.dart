import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Table definitions ─────────────────────────────────────────────────────────

/// Local cache of products — mirrors Supabase `products` + sync metadata.
class LocalProducts extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get costPriceUsd => real()();
  RealColumn get sellPriceUsd => real()();
  IntColumn get quantity => integer()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()(); // null = never synced

  @override
  Set<Column> get primaryKey => {id};
}

/// Local cache of customers — mirrors Supabase `customers` + sync metadata.
class LocalCustomers extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()(); // null = never synced

  @override
  Set<Column> get primaryKey => {id};
}

/// Local sales log.
class LocalSales extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get businessId => text()();
  TextColumn get customerId => text().nullable()();
  RealColumn get totalUsd => real()();
  RealColumn get totalLbp => real()();
  RealColumn get exchangeRateUsed => real()();
  TextColumn get paymentType => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Line items within a sale.
class LocalSaleItems extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  TextColumn get productNameSnapshot => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPriceUsd => real()();
  RealColumn get subtotalUsd => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbound sync queue — filled by every write, consumed by session 2's sync engine.
class SyncQueueEntries extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get businessId => text()();
  TextColumn get operationType => text()(); // product_upsert | product_delete | stock_adjustment | sale | customer_upsert
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'sync_queue';
}

/// Tracks the last successful pull timestamp per business for incremental sync.
class SyncMetadataEntries extends Table {
  TextColumn get businessId => text()();
  DateTimeColumn get lastPullAt => dateTime()();

  @override
  Set<Column> get primaryKey => {businessId};

  @override
  String get tableName => 'sync_metadata';
}

// ── Database class ────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalProducts,
  LocalCustomers,
  LocalSales,
  LocalSaleItems,
  SyncQueueEntries,
  SyncMetadataEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase.defaults() : super(driftDatabase(name: 'shopbase_local'));

  // For testing — accept any QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncMetadataEntries);
          }
          if (from < 3) {
            await m.deleteTable('sync_queue');
            await m.createTable(syncQueueEntries);
          }
        },
      );
}
