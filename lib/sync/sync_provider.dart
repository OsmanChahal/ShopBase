import 'dart:async';
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
import '../providers/inventory_provider.dart';

final isOnlineProvider = StateProvider<bool>((ref) => true);
final isSyncingProvider = StateProvider<bool>((ref) => false);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    ref.watch(syncQueueRepositoryProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.stopListening());
  return service;
});

class SyncOrchestrator {
  final Ref _ref;
  bool _initialized = false;
  String? _businessId;

  StreamSubscription<void>? _queueChangeSubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  bool _syncRunning = false;
  bool _syncQueuedAgain = false;

  SyncOrchestrator(this._ref);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final business = _ref.read(currentBusinessProvider);
    if (business == null) return;

    final businessId = business.id;
    _businessId = businessId;
    final connectivityService = _ref.read(connectivityServiceProvider);
    final queueRepo = _ref.read(syncQueueRepositoryProvider);

    connectivityService.onConnectivityChange = (isOnline) {
      _ref.read(isOnlineProvider.notifier).state = isOnline;
    };

    connectivityService.onOnline = () async {
      dev.log('[SyncOrchestrator] Online transition — triggering sync');
      await runSync(businessId: businessId, showToast: true);
    };

    connectivityService.startListening();

    // NEW: listen for local writes and trigger a short-debounced sync,
    // so changes reach Supabase within about a second instead of waiting
    // for the app to close/reopen or the connection to drop and return.
    _queueChangeSubscription = queueRepo.onQueueChanged.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (_ref.read(isOnlineProvider)) {
          runSync(
            businessId: businessId,
            showToast: false,
            trackSyncingState: false,
          );
        }
      });
    });

    // NEW: periodic pull while the app is open, so other devices' changes
    // (e.g. the owner adding a product) reach this device without needing
    // a manual reconnect or app restart.
    _startPeriodicSync(businessId);

    final isOnline = await connectivityService.checkConnectivity();
    _ref.read(isOnlineProvider.notifier).state = isOnline;

    if (isOnline) {
      final hasPending = await queueRepo.hasPendingOrFailed();
      if (hasPending) {
        dev.log('[SyncOrchestrator] Startup: pending entries found, syncing');
        await runSync(businessId: businessId, showToast: true);
      } else {
        dev.log('[SyncOrchestrator] Startup: no pending entries, pulling only');
        await runSync(businessId: businessId, showToast: false);
      }
    } else {
      dev.log('[SyncOrchestrator] Startup: offline, will sync when online');
    }
  }

  void _startPeriodicSync(String businessId) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_ref.read(isOnlineProvider)) {
        runSync(businessId: businessId, showToast: false);
      }
    });
  }

  /// Call when the app returns to the foreground (wired from app.dart).
  void onAppResumed() {
    if (_businessId == null) return;
    runSync(businessId: _businessId!, showToast: false);
  }

  /// Call when the app goes to the background — pauses the periodic timer
  /// so it's not running uselessly while the app isn't visible.
  void onAppPaused() {
    _periodicTimer?.cancel();
  }

  Future<void> runSync({
    required String businessId,
    bool showToast = true,
    bool trackSyncingState = true,
  }) async {
    // NEW: prevent overlapping sync runs — if one is already in progress,
    // just remember to run once more right after it finishes.
    if (_syncRunning) {
      _syncQueuedAgain = true;
      return;
    }
    _syncRunning = true;

    final syncEngine = _ref.read(syncEngineProvider);
    final queueRepo = _ref.read(syncQueueRepositoryProvider);

    if (trackSyncingState) _ref.read(isSyncingProvider.notifier).state = true;

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
      if (trackSyncingState)
        _ref.read(isSyncingProvider.notifier).state = false;
      _syncRunning = false;
      if (_syncQueuedAgain) {
        _syncQueuedAgain = false;
        runSync(
          businessId: businessId,
          showToast: false,
          trackSyncingState: false,
        );
      }
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

  void _invalidateProviders() {
    _ref.invalidate(productListProvider);
    _ref.invalidate(customerListProvider);
    _ref.invalidate(salesListProvider);
    _ref.invalidate(accessibleInventoriesProvider);
    _ref.invalidate(posInventoriesProvider);
  }

  void dispose() {
    _queueChangeSubscription?.cancel();
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
  }
}

final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  ref.watch(currentBusinessProvider.select((b) => b?.id));
  final orchestrator = SyncOrchestrator(ref);
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});
