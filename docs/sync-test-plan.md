# Sync test plan (critical-blocker fixes)

Manual checks for the sync fixes on `feature/multi-inventory` (items 1–6 of the
codebase audit). Most of the logic is covered by automated tests; these checks
cover the parts that need a real Supabase backend and real devices.

Every test has two variants:

- **Two devices**: phone A and phone B (or a phone plus an Android emulator),
  both signed in to the **same business**.
- **One phone**: you play "the other device" by changing data directly in the
  **Supabase dashboard** (Table Editor or SQL Editor) — that is exactly what the
  phone sees when another device syncs.

> Timing: new sales arrive within about **45 seconds** (normal sync). Checks
> for deletes, edits and offline sales run **every 5 minutes**, and also right
> after the app starts. To skip the wait, fully close and reopen the app.

---

## Before you start

1. Build and install the release APK:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`.
2. The app ID changed to `com.invaro.app`, so this installs as a **new app**
   next to the old pilot build. On the old app, go online and let it sync
   first, then uninstall it.
3. Sign in, wait for the first sync to finish (the banner disappears).
4. For one-phone tests: open your project at supabase.com → **Table Editor**
   and **SQL Editor**. Find your business id with:
   ```sql
   select id, name from businesses;
   ```
   Replace `<BUSINESS_ID>` below with it.

Record results in the checklist at the end.

---

## T1 — Release build reaches the internet (item 1)

**Steps**
1. Install the **release** APK (not `flutter run`).
2. Sign in.
3. Make a sale while online.

**Expected**: sign-in works; the sale syncs (it appears in the Supabase
`sales` table within ~1 minute). Before the fix, release builds could not
connect at all.

---

## T2 — Sales from another device appear (item 2)

### Two devices
1. On **A**, make a sale (online).
2. On **B**, open **Sales History**.

**Expected**: the sale appears on B within ~1 minute (pull down to refresh or
reopen the screen).

### One phone
1. In the SQL Editor, create a sale as if another device made it:
   ```sql
   insert into sales (id, business_id, total_usd, total_lbp,
                      exchange_rate_used, payment_type, created_at)
   values (gen_random_uuid(), '<BUSINESS_ID>', 12.50, 1118750,
           89500, 'cash', now())
   returning id;
   ```
2. Add a line item (use the id returned above):
   ```sql
   insert into sale_items (id, sale_id, product_name_snapshot, quantity,
                           unit_price_usd, subtotal_usd)
   values (gen_random_uuid(), '<SALE_ID>', 'Test item', 1, 12.50, 12.50);
   ```
   If your schema requires `product_id`, add a real product id from the
   `products` table.
3. On the phone, open **Sales History**.

**Expected**: a $12.50 / LBP 1,118,750 cash sale appears within ~1 minute;
tapping it shows "1 x Test item".

---

## T3 — Sale made offline elsewhere still arrives (item 2, late upload)

This is the case a simple "since last sync" check misses: the sale is
uploaded late but carries the older time it was made.

### Two devices
1. Put **A** in airplane mode. Make a sale on A.
2. Wait at least **15 minutes** (longer than the 10-minute overlap).
3. Turn A back online and let it sync (sale appears in Supabase).
4. On **B**, wait up to **5 minutes**, or close and reopen the app.

**Expected**: the sale appears in B's Sales History with its original
(earlier) time.

### One phone
1. Repeat the T2 SQL, but backdate the sale:
   ```sql
   insert into sales (id, business_id, total_usd, total_lbp,
                      exchange_rate_used, payment_type, created_at)
   values (gen_random_uuid(), '<BUSINESS_ID>', 7.00, 626500,
           89500, 'card', now() - interval '2 days')
   returning id;
   ```
2. Close and reopen the app (or wait 5 minutes).

**Expected**: the $7.00 card sale appears, dated two days ago.

---

## T4 — Customer edits from another device (item 3)

### Two devices
1. On **A**, edit a customer's name and phone.
2. On **B**, wait up to 5 minutes (or reopen the app), open **Customers**.

**Expected**: B shows the new name and phone.

### One phone
1. Table Editor → `customers` → change a customer's `name` (e.g. add " EDITED").
2. Close and reopen the app.

**Expected**: the customer list shows the edited name.

---

## T5 — Deletes from another device (item 3)

### Two devices
1. On **A**, delete a customer **with no sales**, and delete a product.
2. On **B**, wait up to 5 minutes (or reopen the app).

**Expected**: both disappear from B (product also gone from POS and every
location).

### One phone
1. Table Editor → delete a test customer row (one with no sales) and a test
   product row. Create test ones first if needed.
2. Close and reopen the app.

**Expected**: both are gone from the app.

---

## T6 — Refused delete is restored (item 4)

1. On the phone, delete a customer who **has sales**.
2. Wait for the sync (~1 minute).

**Expected**: an error message appears (e.g. about permission or the record
being in use), and the customer **reappears** in the list after the next sync.

> If the customer stays deleted and the row is also gone from Supabase, your
> database allows deleting customers with sales (no blocking foreign key), so
> this case can't happen on your setup — mark it **N/A**.

---

## T7 — Unsent changes are never lost (safety)

1. Put the phone in **airplane mode**.
2. Edit a customer's name, add a new product, make a sale.
3. Close and reopen the app **while still offline**.
4. Turn the internet back on and wait for the sync.

**Expected**: all three changes are still there after reopening, and all
three reach Supabase after reconnecting. Nothing you changed offline is
reverted by the server check.

---

## T8 — Large shop first login (item 6, optional)

Only needed if a business has **more than 1,000** products, customers or
sales.

1. Sign in on a fresh install (or clear app data).
2. Compare counts: Supabase (`select count(*) from products where
   business_id = '<BUSINESS_ID>';`, same for `customers`, `sales`) vs. the app.

**Expected**: the counts match. Before the fix the app stopped at 1,000.

---

## Results

| Test | Two devices / one phone | Pass / Fail / N/A | Notes |
|---|---|---|---|
| T1 Release build online | | | |
| T2 New sale from other device | | | |
| T3 Late offline sale | | | |
| T4 Customer edit | | | |
| T5 Deletes | | | |
| T6 Refused delete restored | | | |
| T7 Offline changes kept | | | |
| T8 >1,000 rows (optional) | | | |

### Clean up after one-phone tests

Use the ids returned by the `insert ... returning id` statements in T2 and T3
(items first, then the sales):

```sql
delete from sale_items where sale_id in ('<T2_SALE_ID>', '<T3_SALE_ID>');
delete from sales where id in ('<T2_SALE_ID>', '<T3_SALE_ID>');
```

The phone keeps its copy of these test sales (sales are only ever added
locally). To clear them from the phone as well, sign out and back in.
