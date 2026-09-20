# Session 2: Sync Engine (Push + Pull)

Build the sync engine that processes the `sync_queue` (push) and pulls remote changes (pull), triggered by offline→online transitions and app startup.

## User Action Required

> [!IMPORTANT]
> **Run this SQL in Supabase before testing:**
> ```sql
> create or replace function adjust_stock(p_product_id uuid, p_delta integer)
> returns void as $$
> begin
>   update products
>   set quantity = greatest(0, quantity + p_delta),
>       updated_at = now()
>   where id = p_product_id;
> end;
> $$ language plpgsql security definer;
> ```

---

## Proposed Changes

### Phase 1: Dependencies

---

#### [MODIFY] [pubspec.yaml](file:///d:/ShopBase/crm_pos/pubspec.yaml)

Add `connectivity_plus: ^6.1.4` (not currently in the project).

---

### Phase 2: Extend Sync Queue Repository

---

#### [MODIFY] [sync_queue_repository.dart](file:///d:/ShopBase/crm_pos/lib/database/sync_queue_repository.dart)

Add methods needed by the sync engine:
- `getProcessableEntries()` → `SELECT * FROM sync_queue WHERE status IN ('pending', 'failed') ORDER BY created_at ASC`
- `markSynced(id)` → update status to `'synced'`
- `markFailed(id, error)` → update status to `'failed'`, increment `retry_count`, set `last_error`
- `hasPendingOrFailed()` → bool check for startup trigger

---

### Phase 3: Sync Engine

---

#### [NEW] `lib/sync/sync_engine.dart`

Core sync logic — one class, two phases:

**Push phase** — process queue entries in `created_at` order:

| Operation | Supabase Action | Safety |
|-----------|----------------|--------|
| `product_upsert` | Upsert into `products` by `id`. Strip `quantity` from payload as safety check | Idempotent upsert |
| `product_delete` | Delete from `products` by `id`. Treat "not found" as success | Idempotent |
| `stock_adjustment` | RPC `adjust_stock(product_id, delta)` | Atomic delta, clamped at 0 |
| `sale` | Upsert `sales` row + upsert each `sale_items` row, then call `adjust_stock` per stock delta | Upsert = safe retry |
| `customer_upsert` | Upsert into `customers` by `id` | Idempotent upsert |

Each entry: try → success = `markSynced` / failure = `markFailed` + continue to next entry.

**Pull phase** — runs after push, regardless of push failures:

1. Read `last_pull_at` timestamp from local storage (per business, stored in a simple key-value in the local DB — a new `SyncMetadata` table with `business_id` + `last_pull_at`)
2. Fetch products where `updated_at > last_pull_at` from Supabase
3. Merge each into `local_products`:
   - Non-quantity fields: LWW using `updated_at` — only overwrite if server's `updated_at` > local's `updated_at`
   - `quantity`: **always take server's value** (server is authoritative after push applied all deltas)
4. Same for customers (LWW on all fields using `updated_at` — no quantity concern)
5. Update `last_pull_at` to the timestamp of this pull

Dependencies: `SupabaseClient`, `AppDatabase`, `SyncQueueRepository`

---

### Phase 4: Schema Change — Sync Metadata Table

---

#### [MODIFY] [app_database.dart](file:///d:/ShopBase/crm_pos/lib/database/app_database.dart)

Add a `SyncMetadata` table to track the last pull timestamp per business:
```dart
class SyncMetadataEntries extends Table {
  TextColumn get businessId => text()();
  DateTimeColumn get lastPullAt => dateTime()();

  @override
  Set<Column> get primaryKey => {businessId};

  @override
  String get tableName => 'sync_metadata';
}
```

Add to `@DriftDatabase(tables: [...])`. Bump `schemaVersion` to 2 with a migration that creates the new table.

---

### Phase 5: Connectivity Service + Sync Orchestration

---

#### [NEW] `lib/sync/connectivity_service.dart`

Wraps `connectivity_plus` and provides:
- A `Stream<bool>` of online/offline state
- A method `isOnline()` for one-shot checks
- Detects offline→online transitions and triggers `SyncEngine.sync()`

#### [NEW] `lib/sync/sync_provider.dart`

Riverpod wiring:
- `syncEngineProvider` — provides the `SyncEngine` singleton
- `connectivityServiceProvider` — provides the `ConnectivityService` singleton
- `syncOrchestratorProvider` — a provider that listens to connectivity changes and triggers sync. Also triggers sync on startup if there are pending/failed entries and device is online

---

### Phase 6: Startup Integration

---

#### [MODIFY] [home_screen.dart](file:///d:/ShopBase/crm_pos/lib/screens/home_screen.dart)

After the initial pull completes, initialize the sync orchestrator:
- Read `syncOrchestratorProvider` to start listening for connectivity changes
- If online + pending queue entries exist → trigger immediate sync

---

### Phase 7: Code Generation & Verification

---

- Run `dart run build_runner build` (for the new `SyncMetadata` table)
- Run `flutter analyze`

---

## File Summary

| Action | File | Purpose |
|--------|------|---------|
| MODIFY | `pubspec.yaml` | Add `connectivity_plus` |
| MODIFY | `app_database.dart` | Add `SyncMetadata` table, bump schema |
| MODIFY | `sync_queue_repository.dart` | Add sync engine query methods |
| NEW | `lib/sync/sync_engine.dart` | Push + Pull logic |
| NEW | `lib/sync/connectivity_service.dart` | Online/offline detection |
| NEW | `lib/sync/sync_provider.dart` | Riverpod wiring + orchestration |
| MODIFY | `home_screen.dart` | Start sync orchestrator after initial pull |

## Verification Plan

### Automated Tests
- `dart run build_runner build` — schema + code gen succeeds
- `flutter analyze` — 0 issues

### Manual Verification (in order per user request)
1. **Push phase stock deltas first**: Perform offline sales + stock adjustments → go online → verify Supabase quantities match expected values exactly
2. **Full queue processing**: Offline product CRUD + customers + sales → go online → verify all entries marked `synced`
3. **Kill-and-resume**: Kill app while offline with pending entries → reopen → go online → confirm queue processes without duplicates
4. **Failure resilience**: Break one Supabase call → sync → confirm failed item is marked `failed`, others still process → fix the call → next sync retries and succeeds
5. **Pull phase**: Edit a product directly in Supabase → trigger sync → confirm local data updated
