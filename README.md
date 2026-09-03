# ShopBase — Pilot MVP

ShopBase is a modern Flutter-based POS and Inventory Management SaaS tailored for small businesses operating in dual-currency markets (USD / LBP).

---

## 🚀 Quick Start & Local Setup

### Prerequisites
- **Flutter SDK**: 3.11.x or later (Dart 3.x)
- **Android SDK / Studio**: Required for Android builds & emulator testing

### Installation & Running Locally
```bash
# 1. Clone the repository and navigate to root
cd d:/CRM/crm_pos

# 2. Install dependencies
flutter pub get

# 3. Run the app in debug mode
flutter run
```

---

## 🔐 Configuration (Supabase)

Supabase URL and Anon/Publishable key are configured in [`lib/main.dart`](file:///d:/CRM/crm_pos/lib/main.dart#L9-L12):

```dart
await Supabase.initialize(
  url: '****************************************',
  publishableKey: '**********************************',
);
```

### Database Tables (Supabase Schema)
- `businesses`: Tracks shop profile, `owner_id`, and USD/LBP `currency_rate`
- `products`: Product catalog, cost & sell price, stock levels, low-stock threshold
- `sales`: Head sale record (payment type, total USD/LBP, exchange rate used)
- `sale_items`: Snapshot line items for each transaction
- `customers`: Customer profiles & debt balances (`balance_usd`)
- `payments`: Debt repayment records
- `expenses`: Business expense ledger (recurring vs. one-off)

---

## 📦 Building the Release APK

To build the standalone release APK for distribution to pilot users:

```bash
flutter build apk --release
```

- **Output Path**: `build/app/outputs/flutter-apk/app-release.apk`
- **Signing Config**: Configured in `android/app/build.gradle.kts` using debug keys for seamless pilot deployment.

---

## 📌 Pilot MVP Scope & Known Limitations

This build is a focused Pilot MVP designed for initial real-world testing. The following items are intentionally out of scope for this version:

1. **Manual Exchange Rate**: Exchange rate is set manually by the business owner via Settings (no auto-fetching live bank rates).
2. **Single User per Business**: Each business is owned by one authenticated user (`owner_id = auth.uid()`). Multi-user/role management is not yet included.
3. **Online Only**: Requires an active network connection to sync transactions with Supabase. No offline local caching or queueing.
4. **Manual Receipts**: Digital receipt view generated on-screen after checkout (no hardware ESC/POS bluetooth printer integration yet).

# ShopBase
A small application for the small businesses owners to manage their business from their phones with small monthly fees
