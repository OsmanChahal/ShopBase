import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/cart_provider.dart';
import '../providers/inventory_provider.dart';

/// Switches the working inventory. If the cart has items, asks first and
/// clears it (decision: one sale = one inventory). Returns false if cancelled.
Future<bool> switchInventoryWithConfirm(
  BuildContext context,
  WidgetRef ref,
  LocalInventory inv,
) async {
  final currentId = ref.read(currentInventoryIdProvider).valueOrNull;
  if (inv.id == currentId) return true;
  if (ref.read(cartProvider).isNotEmpty) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch location?'),
        content: const Text(
          'Your cart has items from the current location. '
          'Switching will clear the cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Switch & clear'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    ref.read(cartProvider.notifier).clear();
  }
  await ref.read(selectedInventoryIdProvider.notifier).select(inv.id);
  return true;
}
