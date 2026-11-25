# ShopBase Architecture

ShopBase (Dart package `crm_pos`) is a Flutter point-of-sale, inventory and light CRM app for small shops that trade in two currencies (USD and LBP). This document maps how the app is put together. For a short command reference, see `CLAUDE.md`.

> `README.md` is partly out of date. It describes the app as online-only, single-user, with customer debt balances. In the current code the app is offline-first, has staff accounts with permissions, and has no debt balances.

---

## 1. System overview & tech stack

| Concern | Choice |
|---|---|
| UI | Flutter (Dart SDK ^3.11.5), Material 3, Inter via `google_fonts`, `fl_chart` for dashboard charts, `flutter_svg` |
| State | `flutter_riverpod` 2.x, using hand-written `Provider` / `FutureProvider` / `StateProvider` / `StreamProvider` / `StateNotifier` (no code generation) |
| Local storage | Drift (SQLite) via `drift_flutter`, database name `shopbase_local`; `shared_preferences` for small settings |
| Backend | Supabase: Auth (email + password), Postgres with row-level security, Postgres functions (RPC), Realtime **broadcast** channels |
| Connectivity | `connectivity_plus` |
| IDs | `uuid` v4, generated on the device |
| Other | `url_launcher` (WhatsApp links), `intl_phone_field` (customer phone input) |
| Platform | Android first (`applicationId com.example.crm_pos`); iOS, web and desktop folders are the unmodified Flutter scaffolding |

**Two data paths.** Core shop data (products, stock, locations, transfers, sales, customers) is written to the local database first and synced later, so it works offline. Admin and reporting features (login, staff, expenses, tags, dashboard, CRM analytics) talk to Supabase directly and need a connection.

```
                    ┌──────────────── Flutter app ────────────────┐
 Screens/Widgets ──▶ Riverpod providers
                     │                         │
       offline-first │                         │ online-only
                     ▼                         ▼
       lib/database/local_*_repository   lib/services/*_service
                     │                         │
          Drift tables + sync_queue            │
                     │                         │
       lib/sync/SyncEngine (push → pull)       │
                    └────────────┬────────────┘
                                 ▼
                 Supabase (Auth · Postgres/RLS · RPC · Realtime)
```

---

## 2. Directory structure

| Path | Responsibility |
|---|---|
| `lib/main.dart` | Entry point: `Supabase.initialize(...)`, then `runApp(ProviderScope(child: CrmPosApp()))` |
| `lib/app.dart` | `CrmPosApp`: theme, top-level routing on auth state, app lifecycle hooks into sync, global `rootScaffoldMessengerKey` |
| `lib/constants/` | Static lists (business types) |
| `lib/database/` | Drift schema (`app_database.dart`, generated `app_database.g.dart`), `database_provider.dart`, the offline repositories (`local_product/customer/sale/inventory_repository.dart`), `sync_queue_repository.dart`, `initial_pull_service.dart` |
| `lib/models/` | Plain Dart models with `fromJson`/`toJson` for Supabase rows; providers convert Drift rows into these |
| `lib/providers/` | Riverpod providers: auth/session, cart, sales, products, inventories and access, customers, staff, expenses, tags, dashboard |
| `lib/screens/` | Full screens, plus a few bottom sheets and dialogs (`settings_sheet`, `cart_panel`, `stock_adjust_dialog`) |
| `lib/services/` | Online-only Supabase access (auth, staff, expenses, tags, dashboard, CRM analytics, customer/sale queries) |
| `lib/sync/` | `sync_engine.dart` (push/pull), `sync_provider.dart` (`SyncOrchestrator`, online/syncing flags), `connectivity_service.dart` |
| `lib/theme/` | `app_colors.dart`, `inventory_design.dart` |
| `lib/widgets/` | Reusable UI pieces (product cards and tiles, connectivity banner, inventory switcher, transfer sheet, tag picker, and so on) |
| `asset/` | Bundled assets (WhatsApp SVG icon) |
| `test/` | Drift tests on an in-memory database, plus two tests that hit the live Supabase backend (`supabase_connection_test`, `full_staff_realtime_test`) |
| `android/` | Android project (Gradle Kotlin DSL) |
| `implementation_plan.md` | Historical design notes for the sync engine; does not describe the current code |
| `../crm_pos - Copy` | Stale backup of the project; not used |

---

## 3. End-to-end data flow

### 3.1 Startup and routing
1. `main.dart` initializes Supabase and wraps the app in `ProviderScope`.
2. `CrmPosApp` (`app.dart`) watches `authProvider` and switches the home widget on `AppAuthState`:
   - `loading` → splash
   - `unauthenticated` → `WelcomeScreen`
   - `authenticated` → `HomeScreen`
   - `noBusinessFound` → `NoBusinessScreen`
3. When auth becomes `authenticated`, `SyncOrchestrator.initialize()` runs (see 3.3). The `resumed` and `paused` lifecycle events are forwarded to the orchestrator.

### 3.2 Navigation inside the app
- `HomeScreen` builds up to four tabs in an `IndexedStack`. Each tab appears only if the user has its permission:
  - Dashboard needs `view_dashboard`
  - POS needs `use_pos`
  - Inventory needs `view_inventory`
  - Customers needs `manage_customers`
- The bottom navigation bar only appears when there is more than one tab. Settings opens as a bottom sheet (`SettingsSheet`).
- Every other screen is opened with `Navigator.of(context).push(MaterialPageRoute(...))`. There are **no named routes**.

### 3.3 Worked example: completing a sale (offline-first path)
1. **POS screen → cart.** The cashier adds products. `cartProvider` holds `CartItem`s (USD unit price, cost, quantity, optional price override). `cartTotalLbpProvider` shows the LBP total.
2. **Checkout.** `sale_provider.dart` computes `totalLbp = totalUsd * business.currencyRate` and calls `LocalSaleRepository.createSale(...)`.
3. **One Drift transaction** (`local_sale_repository.dart`):
   - inserts the `LocalSales` row, including `inventory_id` and the exchange rate used
   - inserts the `LocalSaleItems`, each with a cost-price snapshot
   - lowers `LocalInventoryStock` for the selected location
   - enqueues one `sale` entry in `sync_queue`
4. **UI refresh.** The sale provider invalidates `salesListProvider`, `productListProvider` and (when a customer was attached) `customerListProvider`. The receipt screen opens and can share the receipt over WhatsApp.
5. **Sync trigger.** `SyncQueueRepository.onQueueChanged` fires. The orchestrator waits 600 ms (debounce) and, if online, calls `runSync`.
6. **Push.** `SyncEngine._push` reads queue entries oldest first and switches on `operationType`. For `sale` it upserts `sales` and `sale_items` and adjusts stock on the server with delta RPCs. On success the entry is marked synced.
7. **Pull.** `SyncEngine._pull` fetches rows changed since the per-business cursor in `sync_metadata` (products, customers, inventories, inventory stock, access, transfers):
   - the server's stock quantity always wins
   - other fields use last-write-wins on `updated_at`

### 3.4 Sync triggers and failure handling
- **Triggers** (`sync_provider.dart`):
  - startup (a full sync if the queue has entries, otherwise pull only)
  - going from offline to online (`ConnectivityService`)
  - a change in the queue (600 ms debounce)
  - a 45-second timer while the app is open
  - app resume

  The orchestrator never runs two syncs at once; a request that arrives during a sync is queued to run again afterwards. `isOnlineProvider` and `isSyncingProvider` drive the connectivity banner.
- **Failures** (`sync_engine.dart`):
  - *Transient* (socket, timeout, auth refresh, HTTP client errors): the entry stays pending and the push **stops**, so later entries keep their order.
  - *Permanent* (Postgres codes `42501` RLS, `P0001` raised exception, `23505`, `23514`, `22023`, `23503`): the entry is marked rejected, a readable message is shown in a snackbar through `rootScaffoldMessengerKey`, and `_compensate` undoes the local change. For stock it re-reads stock from the server; a refused transfer is deleted locally; an inventory is restored from the server.
  - *Anything else*: the entry is marked failed and retried on a later sync.
- **First login on a device:** `InitialPullService` does a one-time full download into the empty local database.

### 3.5 Online-only flows
Expenses, tags, staff management, the dashboard and CRM analytics call `lib/services/*_service.dart` directly through the providers. These queries go straight to Supabase and fail without a connection.

### 3.6 Owner sign-up and staff onboarding
- **Owner sign-up** (`auth_service.dart`), in order:
  1. Create the user with `auth.signUp` (email + password).
  2. Insert the `businesses` row, with the business ID generated on the device and a default `currency_rate` of 89500.
  3. Insert a `business_members` row with `role: 'admin'` and `permissions {'all': true}`.
  4. Open `SubscriptionScreen`.
- **Staff invitation:**
  1. The admin creates a `staff_invitations` row with status `invited`.
  2. The staff member goes Welcome → `StaffRegisterScreen`. That screen calls RPC `staff_lookup_invitation`, then `staff_submit_name` (status becomes `awaiting_approval`), then broadcasts `new_request` on `staff_requests_<businessId>`.
  3. `StaffWaitingScreen` checks the current status once with `staff_check_status`, then listens on `invitation_status_<invitationId>`.
  4. The admin accepts or declines in `ManageStaffScreen`. This is a **direct table update** from the screen, followed by a `status_update` broadcast.
  5. `StaffPasswordSetupScreen` calls `auth.signUp`, then RPC `staff_activate_account`, then refreshes `authProvider`.

### 3.7 Sign-out
`session_provider.dart`:
1. Tries to push pending queue entries if online.
2. Signs out.
3. Deletes every Drift table, including `sync_queue` and `sync_metadata`.
4. Invalidates the session-scoped providers (cart, selected customer, selected inventory, inventory lists).

---

## 4. External APIs, webhooks & third-party dependencies

### Supabase tables
| Table | Accessed from |
|---|---|
| `businesses`, `business_members` | `auth_service` |
| `staff_invitations` | `staff_service`, `manage_staff_screen` (direct update) |
| `products` | `sync_engine`, `initial_pull_service` |
| `customers`, `sales`, `sale_items` | `sync_engine`, `initial_pull_service`, `customer_service`, `sale_service`, `dashboard_service`, `crm_analytics_service` |
| `expenses` | `expense_service`, `dashboard_service` |
| `tags`, `customer_tags` | `tag_service` |
| `inventories`, `inventory_access`, `inventory_stock`, `stock_transfers`, `stock_transfer_items` | `sync_engine` only |

### Postgres functions (RPC)
- Staff onboarding (`staff_service.dart`): `staff_lookup_invitation`, `staff_submit_name`, `staff_check_status`, `staff_activate_account`
- Stock and locations (`sync_engine.dart`): `adjust_stock`, `set_stock_prices`, `transfer_stock`, `archive_inventory` / `unarchive_inventory`

The SQL for these functions, the RLS policies and the table definitions are **not stored in this repository**. They live only in the Supabase project.

### Realtime
Broadcast channels only, all in `staff_service.dart`:
- `invitation_status_<invitationId>`, event `status_update`
- `staff_requests_<businessId>`, event `new_request`

The app does not subscribe to database change events (Postgres Changes).

### Other integrations
- **WhatsApp:** `https://wa.me/<digits>` links via `url_launcher`, for sharing a receipt with prefilled text (`receipt_screen.dart`) and opening a chat with a customer (`customer_detail_screen.dart`).

### Not present
- **Payments:** no payment gateway. `SubscriptionScreen` shows a disabled "Pay with Whish" button ("Coming soon"); "Skip for now" is the only working action.
- No webhooks, Supabase Edge Functions or Supabase Storage.
- No analytics or crash reporting.
- No deep links. `app_links` comes in only as a dependency of `supabase_flutter`; the manifest has no custom URL scheme and no auth redirect URL is configured.

---

## 5. Key conventions & gotchas

### Data and sync
- **Write path for offline entities:** write the local row **and** call `SyncQueueRepository.enqueue(operationType, payloadJson)` in the **same Drift transaction**, inside a `local_*_repository`. Don't call Supabase directly for these entities. The old `product_service.dart` is not used anywhere.
- **Adding a new synced operation:** add the enqueue call, add a `case` in `SyncEngine._push`, and decide what `_compensate` should do if the server rejects it.
- **Stock:** change it on the server only with deltas or RPCs (`adjust_stock`, `transfer_stock`, `set_stock_prices`). Never push an absolute quantity. On pull the server value replaces the local one.
- **IDs:** generate them on the device with `uuid` v4 so records can be created offline and retried safely (the push upserts by ID).
- **Database schema changes:**
  1. Bump `schemaVersion` (currently 3).
  2. Add an additive step to `onUpgrade`.
  3. Run `dart run build_runner build --delete-conflicting-outputs`.

  Never edit `app_database.g.dart` by hand. The v3 migration clears `sync_metadata` to force a full re-pull.
- **Legacy fallbacks:** when `inventoryId == null` (no locations pulled yet), the code falls back to product-level stock (`local_product_repository.dart`, `local_sale_repository.dart`, `productListProvider`). Keep both paths working until the fallback is deliberately removed.
- **Sign-out:** if you add a provider that holds data for the signed-in session, add it to the invalidate list in `session_provider.dart`.

### Roles and permissions
- There are only two roles, `admin` and `staff`. `businesses.owner_id` is stored but never used for access checks.
- Check access with `isAdminProvider` / `hasPermissionProvider(key)` (`auth_provider.dart`) or `BusinessMember.hasPermission` (admins always pass).
- Permission keys: `view_dashboard`, `use_pos`, `view_inventory`, `edit_inventory`, `manage_customers`, `manage_expenses`, `view_crm_overview`.
- Staff only see the locations granted to them in `inventory_access`.
- RLS on the server is the real enforcement. A server rejection shows up in the app as a rejected sync entry with a `42501` error.

### Currency
- Prices are stored in **USD only**. The rate (LBP per USD) is `businesses.currency_rate`; the business owner edits it in Settings.
- A sale stores `total_lbp` and `exchange_rate_used` as a snapshot, unrounded.
- Display: USD uses `toStringAsFixed(2)`. LBP uses `toStringAsFixed(0)` with a hand-written thousands separator, **copied into about seven files** (`cart_panel`, `customer_detail_screen`, `customer_list_screen`, `dashboard_screen`, `receipt_screen`, `sales_history_screen`, `product_card`). There is no shared formatter.
- Payment types: the UI offers only `cash` and `card`. `cart_panel.dart` checks for `'credit'`, but it can't be selected, and `Customer` has no balance field.

### Code hygiene
- About 40 `// NEW` and 5 `// CHANGED` markers are left over from the multi-location work. `TODO(backend)` / `TODO(UI)` comments mark unbuilt features (barcode scanner, product photos, batches, in-transit transfers, push notifications, and so on).
- Unused code: `services/product_service.dart`, `models/payment.dart`, `screens/debug_inventory_screen.dart`, `screens/placeholder_screen.dart`.
- Raw `print(...)` debugging calls remain in `staff_service.dart` and `manage_staff_screen.dart`.

### Configuration and Android
- **Hard-coded Supabase credentials:** the URL and publishable key are in `lib/main.dart` and `test/full_staff_realtime_test.dart`. There is no environment-based config.
- **Missing INTERNET permission:** `android/app/src/main/AndroidManifest.xml` doesn't declare it; only the debug and profile manifests do. **Check that a release APK can reach the network** before shipping.
- **Release signing:** release builds are signed with **debug keys** (`android/app/build.gradle.kts`, marked TODO), and `applicationId` is still the placeholder `com.example.crm_pos`. Both must change before a Play Store release.
- **Live-backend tests:** two tests in `test/` run against the real Supabase project.
