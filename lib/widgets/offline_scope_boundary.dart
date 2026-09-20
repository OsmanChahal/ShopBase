import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_provider.dart';
import '../theme/app_colors.dart';

/// Wraps online-dependent content with an offline check.
/// If the device is offline, renders a friendly empty state ("This needs an internet connection to load")
/// with an icon consistent with the rest of the app instead of attempting remote Supabase queries.
/// When the device reconnects, automatically renders [child].
class OfflineScopeBoundary extends ConsumerWidget {
  final Widget child;
  final String? message;
  final String? subtitle;

  const OfflineScopeBoundary({
    super.key,
    required this.child,
    this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (!isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.primaryPurple.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'This needs an internet connection to load',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? 'Connect to the internet to access this screen',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
