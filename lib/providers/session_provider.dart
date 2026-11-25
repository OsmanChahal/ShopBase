import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../database/initial_pull_service.dart';
import '../sync/sync_provider.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'customer_provider.dart';
import 'inventory_provider.dart';
import 'product_provider.dart';
import 'sale_provider.dart';

class SignOutOutcome {
  final bool signedOut;
  final int pending;
  final int failed;
  const SignOutOutcome.done() : signedOut = true, pending = 0, failed = 0;
  const SignOutOutcome.blocked({required this.pending, required this.failed})
    : signedOut = false;
}

/// Sign-out with the data-loss guard:
/// 1. If changes are unsynced, try to flush them first (when online).
/// 2. If any remain, refuse (unless [discardUnsynced] is true).
/// 3. Only then sign out and wipe EVERY local table.
class SessionActions {
  final Ref ref;
  SessionActions(this.ref);

  /// One-time download of an existing business's data into an empty local
  /// database (first login on this device). Refreshes the product, customer
  /// and sales lists when data was pulled. Returns whether a pull happened.
  Future<bool> pullInitialDataIfNeeded(String businessId) async {
    final pullService = InitialPullService(
      supabase: ref.read(supabaseClientProvider),
      productRepo: ref.read(localProductRepositoryProvider),
      customerRepo: ref.read(localCustomerRepositoryProvider),
      saleRepo: ref.read(localSaleRepositoryProvider),
    );

    final didPull = await pullService.pullIfNeeded(businessId);

    if (didPull) {
      // Refresh providers so UI picks up the pulled data
      ref.invalidate(productListProvider);
      ref.invalidate(customerListProvider);
      ref.invalidate(salesListProvider);
    }
    return didPull;
  }

  Future<SignOutOutcome> signOut({bool discardUnsynced = false}) async {
    final queueRepo = ref.read(syncQueueRepositoryProvider);

    if (!discardUnsynced) {
      if (await queueRepo.hasPendingOrFailed() && ref.read(isOnlineProvider)) {
        final business = ref.read(currentBusinessProvider);
        if (business != null) {
          await ref
              .read(syncOrchestratorProvider)
              .runSync(
                businessId: business.id,
                showToast: false,
                trackSyncingState: false,
              );
        }
      }
      final pending = await queueRepo.getPendingCount();
      final failed = await queueRepo.getFailedCount();
      if (pending > 0 || failed > 0) {
        return SignOutOutcome.blocked(pending: pending, failed: failed);
      }
    }

    // If this throws (e.g. offline), nothing has been wiped yet.
    final orchestrator = ref.read(syncOrchestratorProvider);
    await ref.read(authProvider.notifier).signOut();
    orchestrator.dispose();
    await _wipeLocalData();

    // Reset per-user UI state
    ref.invalidate(cartProvider);
    ref.invalidate(selectedCustomerIdProvider);
    ref.invalidate(selectedCustomerNameProvider);
    ref.invalidate(selectedInventoryIdProvider);
    ref.invalidate(accessibleInventoriesProvider);
    ref.invalidate(posInventoriesProvider);
    return const SignOutOutcome.done();
  }

  /// Clears every table (including sync_queue and sync_metadata). Looping over
  /// allTables means future tables are covered automatically.
  Future<void> _wipeLocalData() async {
    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.delete(table).go();
      }
    });
  }
}

final sessionActionsProvider = Provider<SessionActions>(
  (ref) => SessionActions(ref),
);
