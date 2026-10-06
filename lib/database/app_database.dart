import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Table definitions ─────────────────────────────────────────────────────────

/// Local cache of products — mirrors Supabase `products` + sync metadata.
/// NOTE: quantity / prices / threshold here are the legacy Main-inventory
/// mirror. Per-inventory values live in LocalInventoryStock (below).
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
  DateTimeColumn get lastSyncedAt =>
      dateTime().nullable()(); // null = never synced

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
  DateTimeColumn get lastSyncedAt =>
      dateTime().nullable()(); // null = never synced

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
  // NEW: which inventory this sale was made from. Nullable so rows created
  // before this version stay valid (null = legacy / Main).
  TextColumn get inventoryId => text().nullable()();

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
  // NEW: cost price at the moment of sale, used for per-inventory profit.
  // Nullable: old rows have no snapshot (profit treats null as unknown).
  RealColumn get costPriceUsdSnapshot => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── NEW: multi-inventory tables ───────────────────────────────────────────────

/// NEW: a stock location (branch, online store, warehouse...).
/// Mirrors Supabase `inventories`. Never deleted, only archived.
@DataClassName('LocalInventory')
class LocalInventories extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// NEW: per-inventory stock + prices for a catalog product.
/// Mirrors Supabase `inventory_stock`. Quantity here only changes through
/// signed deltas (same rule as before), never by overwriting from the UI.
@DataClassName('LocalStockRow')
class LocalInventoryStock extends Table {
  TextColumn get productId => text()();
  TextColumn get inventoryId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get sellPriceUsd => real()();
  RealColumn get costPriceUsd => real()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {productId, inventoryId};
}

/// NEW: which staff member may use / view / edit which inventory.
/// Mirrors Supabase `inventory_access`.
@DataClassName('LocalInventoryAccessRow')
class LocalInventoryAccess extends Table {
  TextColumn get inventoryId => text()();
  TextColumn get userId => text()();
  BoolColumn get canPos => boolean().withDefault(const Constant(false))();
  BoolColumn get canView => boolean().withDefault(const Constant(false))();
  BoolColumn get canEdit => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {inventoryId, userId};
}

/// NEW: transfer history header. Mirrors Supabase `stock_transfers`.
@DataClassName('LocalStockTransfer')
class LocalStockTransfers extends Table {
  TextColumn get id => text()(); // client-generated UUID (idempotency key)
  TextColumn get businessId => text()();
  TextColumn get fromInventoryId => text()();
  TextColumn get toInventoryId => text()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// NEW: transfer history line items. Mirrors Supabase `stock_transfer_items`.
@DataClassName('LocalStockTransferItem')
class LocalStockTransferItems extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get transferId => text()();
  TextColumn get productId => text().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get productNameSnapshot => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Sync tables (unchanged) ───────────────────────────────────────────────────

/// Outbound sync queue — filled by every write, consumed by session 2's sync engine.
class SyncQueueEntries extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get operationType =>
      text()(); // product_upsert | product_delete | stock_adjustment | sale | customer_upsert (+ more added in later steps)
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

@DriftDatabase(
  tables: [
    LocalProducts,
    LocalCustomers,
    LocalSales,
    LocalSaleItems,
    // NEW: multi-inventory tables
    LocalInventories,
    LocalInventoryStock,
    LocalInventoryAccess,
    LocalStockTransfers,
    LocalStockTransferItems,
    SyncQueueEntries,
    SyncMetadataEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase.defaults() : super(driftDatabase(name: 'shopbase_local'));

  // For testing — accept any QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3; // CHANGED: was 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncMetadataEntries);
      }
      // NEW: v2 -> v3 (multi-inventory). Purely additive: existing rows and
      // the pending sync_queue are untouched.
      if (from < 3) {
        await m.createTable(localInventories);
        await m.createTable(localInventoryStock);
        await m.createTable(localInventoryAccess);
        await m.createTable(localStockTransfers);
        await m.createTable(localStockTransferItems);
        await m.addColumn(localSales, localSales.inventoryId);
        await m.addColumn(localSaleItems, localSaleItems.costPriceUsdSnapshot);
        await m.database.customStatement('DELETE FROM sync_metadata');
      }
    },
  );
}
