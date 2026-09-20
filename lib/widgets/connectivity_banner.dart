import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_provider.dart';
import '../theme/app_colors.dart';

/// Top banner displayed across offline-first screens (POS, Inventory)
/// indicating offline status or active synchronization in progress.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    // When online and idle, show nothing
    if (isOnline && !isSyncing) {
      return const SizedBox.shrink();
    }

    // When back online and sync is actively in progress
    if (isSyncing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: AppColors.primaryPurple,
        child: const SafeArea(
          bottom: false,
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  "You're back online — syncing...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // When offline: persistent banner
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: AppColors.primaryPurpleDark,
      child: const SafeArea(
        bottom: false,
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "You're offline — changes will sync automatically.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
