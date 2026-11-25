import 'package:flutter/material.dart';
import '../providers/session_provider.dart';

/// Explains why sign-out was blocked by unsynced changes.
///
/// When only failed (unsyncable) changes remain, offers "Discard & sign out"
/// and returns true if the user chose it. When changes are still pending,
/// it only tells the user to reconnect and returns false.
Future<bool> showUnsyncedSignOutDialog(
  BuildContext context,
  SignOutOutcome outcome,
) async {
  final onlyFailed = outcome.pending == 0;
  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Can't sign out yet"),
      content: Text(
        onlyFailed
            ? '${outcome.failed} change(s) could not be synced to the server. '
                  'Signing out now will permanently discard them.'
            : '${outcome.pending} change(s) have not synced yet. '
                  'Connect to the internet and try again, so nothing is lost.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(onlyFailed ? 'Cancel' : 'OK'),
        ),
        if (onlyFailed)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Discard & sign out'),
          ),
      ],
    ),
  );
  return discard == true;
}
