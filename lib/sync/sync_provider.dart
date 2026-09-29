import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../database/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../theme/app_colors.dart';
import 'connectivity_service.dart';
import 'sync_engine.dart';

/// Reactive provider for online/offline connectivity state.
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// Reactive provider indicating whether a sync push/pull cycle is actively running.
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Provides the SyncEngine singleton.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    ref.watch(syncQueueRepositoryProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});

/// Provides the ConnectivityService singleton.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.stopListening());
  return service;
});

/// Orchestrator that ties connectivity detection to the sync engine.
/// Call `initialize()` once after the app is ready (initial pull done).
class SyncOrchestrator {
  final Ref _ref;
  bool _initialized = false;

  SyncOrchestrator(this._ref);

  /// Initialize: start listening for connectivity changes and trigger
  /// an initial sync if there are pending entries and we're online.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final business = _ref.read(currentBusinessProvider);
    if (business == null) return;

    final businessId = business.id;
    final connectivityService = _ref.read(connectivityServiceProvider);
    final queueRepo = _ref.read(syncQueueRepositoryProvider);

    // Synchronize reactive isOnlineProvider with connectivity service
    connectivityService.onConnectivityChange = (isOnline) {
      _ref.read(isOnlineProvider.notifier).state = isOnline;
    };

    // Set up the offline→online callback
    connectivityService.onOnline = () async {
      dev.log('[SyncOrchestrator] Online transition — triggering sync');
      await runSync(businessId: businessId, showToast: true);
    };

    // Start listening for connectivity changes
    connectivityService.startListening();

    // Startup sync: if online and there are pending/failed entries, sync now
    final isOnline = await connectivityService.checkConnectivity();
    _ref.read(isOnlineProvider.notifier).state = isOnline;

    if (isOnline) {
      final hasPending = await queueRepo.hasPendingOrFailed();
      if (hasPending) {
        dev.log('[SyncOrchestrator] Startup: pending entries found, syncing');
        await runSync(businessId: businessId, showToast: true);
      } else {
        // Even if no pending pushes, do a pull to get any remote changes silently
        dev.log('[SyncOrchestrator] Startup: no pending entries, pulling only');
        await runSync(businessId: businessId, showToast: false);
      }
    } else {
      dev.log('[SyncOrchestrator] Startup: offline, will sync when online');
    }
  }

  /// Run a full sync pass (push + pull) with status management and optional user notification.
  Future<void> runSync({
    required String businessId,
    bool showToast = true,
  }) async {
    final syncEngine = _ref.read(syncEngineProvider);
    final queueRepo = _ref.read(syncQueueRepositoryProvider);

    _ref.read(isSyncingProvider.notifier).state = true;

    try {
      await syncEngine.sync(businessId);
      _invalidateProviders();

      if (showToast) {
        final hasFailed = await queueRepo.hasFailedEntries();
        if (hasFailed) {
          _showSyncPendingToast();
        } else {
          _showSyncSuccessToast();
        }
      }
    } catch (e, st) {
      dev.log('[SyncOrchestrator] Error during sync: $e\n$st');
      if (showToast) {
        _showSyncPendingToast();
      }
    } finally {
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  void _showSyncSuccessToast() {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'All changes synced',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  void _showSyncPendingToast() {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Some changes are pending and will sync automatically',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
        backgroundColor: AppColors.primaryPurpleDark,
      ),
    );
  }

  /// Invalidate UI providers so screens pick up synced data.
  void _invalidateProviders() {
    _ref.invalidate(productListProvider);
    _ref.invalidate(customerListProvider);
    _ref.invalidate(salesListProvider);
  }
}

/// Provides the SyncOrchestrator singleton.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref);
});
