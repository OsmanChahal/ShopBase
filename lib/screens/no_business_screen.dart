import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';
import '../utils/error_text.dart';
import '../widgets/unsynced_sign_out_dialog.dart';

/// Signs out with the same unsynced-data guard as Settings: if changes are
/// still pending, explain instead of discarding them; if only failed changes
/// remain, let the user choose to discard them.
Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final actions = ref.read(sessionActionsProvider);
  try {
    final outcome = await actions.signOut();
    if (outcome.signedOut || !context.mounted) return;
    final discard = await showUnsyncedSignOutDialog(context, outcome);
    if (discard) await actions.signOut(discardUnsynced: true);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText(e)),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }
}

class NoBusinessScreen extends ConsumerWidget {
  const NoBusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 72,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Business Found',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'No business is linked to this account. Please contact support or sign in with a different account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
