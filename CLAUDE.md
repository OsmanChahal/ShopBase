# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ShopBase (package name `crm_pos`) is a Flutter POS + inventory + light CRM app for small businesses in dual-currency (USD / LBP) markets. Backend is Supabase; local storage is Drift (SQLite). State management is Riverpod 2 (classic `Provider`/`FutureProvider`/`StateProvider`/`StreamProvider`, no codegen). Primary target is Android.

Note: `README.md` is partly outdated — it describes the app as online-only and single-user. The app is now **offline-first** with a sync queue, and supports staff members with per-inventory access and multiple inventories (locations). `implementation_plan.md` is a historical design doc for the sync engine. `D:\Shopbase\crm_pos - Copy` is an old backup copy; don't edit it.

## Commands

```bash
flutter pub get
flutter run                                   # debug run
flutter analyze                               # lint (flutter_lints)
flutter test                                  # all tests
flutter test test/sync_queue_repository_test.dart          # one file
flutter test --plain-name "detects failed entries"         # one test by name
dart run build_runner build --delete-conflicting-outputs   # regenerate lib/database/app_database.g.dart after Drift table changes
flutter build apk --release                   # -> build/app/outputs/flutter-apk/app-release.apk (signed with debug keys for pilot)
```

`test/supabase_connection_test.dart` and `test/full_staff_realtime_test.dart` hit the real Supabase backend; the other tests run against an in-memory Drift DB via `AppDatabase.forTesting(NativeDatabase.memory())`.

Supabase URL/key are hard-coded in `lib/main.dart`.

## Architecture

### Two data paths

1. **Offline-first (local DB + sync queue)** — products, inventory stock, inventories/locations, inventory access, stock transfers, sales, customers.
   - Writes go through `lib/database/local_*_repository.dart`. Each write updates the local Drift tables **and** enqueues an operation in `sync_queue` (via `SyncQueueRepository.enqueue(operationType, payloadJson)`) in one transaction. UI reads from the local DB.
   - IDs are generated client-side with `uuid` v4 so records can be created offline.
2. **Online-only (direct Supabase)** — `lib/services/*_service.dart` (auth, staff, expenses, tags, dashboard/CRM analytics, some customer/sale queries). Some services (e.g. `product_service.dart`) are legacy from before the offline migration; prefer the local repositories for entities that have one.

### Sync (`lib/sync/`)

- `SyncEngine` (`sync_engine.dart`): **push** then **pull**.
  - Push processes queue entries in `created_at` order, dispatching on `operationType` (`product_upsert`, `product_catalog_update`, `stock_adjustment`, `stock_prices_update`, `stock_transfer`, `inventory_*`, `inventory_access_*`, `sale`, `customer_upsert`, `customer_delete`, …). Adding a new synced operation means adding a case here plus the enqueue in a repository.
  - Error classification: transient errors (network, auth refresh) leave the entry pending and **stop** the push to preserve ordering; permanent Postgres errors (RLS `42501`, `P0001` raised exceptions, constraint violations) mark the entry rejected, surface a user-facing message, and run `_compensate` to roll back the local optimistic change (e.g. stock reconcile from server, delete a refused transfer, restore an inventory); other errors mark it failed for retry.
  - Stock quantities are changed on the server via atomic delta RPCs, never by sending absolute quantities. On pull, server quantity is authoritative; other fields merge last-write-wins on `updated_at`. Pull cursors are stored per business in `sync_metadata`.
- `SyncOrchestrator` (`sync_provider.dart`): started from `app.dart` once auth is `authenticated`. Triggers sync on startup, offline→online transitions (`ConnectivityService`), local queue changes (600 ms debounce), a 45 s periodic timer, and app resume. Guards against concurrent runs. Exposes `isOnlineProvider` / `isSyncingProvider`.
- `lib/database/initial_pull_service.dart` does a one-time full pull into an empty local DB for an existing business.

### Local database (`lib/database/app_database.dart`)

Drift tables are prefixed `Local*` plus `SyncQueueEntries` and `SyncMetadataEntries`. Current `schemaVersion` is 3; when changing tables, bump the version, add an additive step to `onUpgrade`, and regenerate `app_database.g.dart` (never edit the `.g.dart` by hand). The v3 migration clears `sync_metadata` to force a full re-pull. Sign-out (`session_provider.dart`) wipes every local table (including the queue) and invalidates session-scoped providers — add new session-scoped providers to that invalidate list.

### Multi-inventory

Stock lives per inventory in `LocalInventoryStock` (products are the catalog; catalog edits vs per-inventory price/stock edits are separate operations). `currentInventoryIdProvider` / `selectedInventoryIdProvider` pick the active location; when no inventories have been pulled yet, providers fall back to the legacy product-level stock read. Staff see only inventories granted in `LocalInventoryAccess`; owners/admins hold all rows. Sales record `inventory_id` and a cost-price snapshot per line item.

### App structure

- `main.dart` → `app.dart` (`CrmPosApp`): theme (Inter via google_fonts, colors from `theme/app_colors.dart`), routing on `AppAuthState` (loading / unauthenticated → `WelcomeScreen` / authenticated → `HomeScreen` / noBusinessFound → `NoBusinessScreen`).
- `providers/auth_provider.dart` holds auth status and `currentBusinessProvider`; most providers watch it and return empty when there is no business.
- `models/` are plain Dart classes with `fromJson`/`toJson` for Supabase rows; providers map Drift rows to these models.
- Screens use `rootScaffoldMessengerKey` (in `app.dart`) for global snackbars, including sync rejection messages.
