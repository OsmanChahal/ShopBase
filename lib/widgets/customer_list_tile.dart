import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../theme/app_colors.dart';
import 'stat_badge.dart';

/// Reusable customer list tile with avatar (initials circle), name, phone, and optional status badge.
class CustomerListTile extends StatelessWidget {
  final Customer customer;
  final String? statusLabel;
  final StatBadge? trailingBadge;
  final VoidCallback onTap;

  const CustomerListTile({
    super.key,
    required this.customer,
    this.statusLabel,
    this.trailingBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primaryPurple,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: customer.phone != null && customer.phone!.isNotEmpty
            ? Text(
                customer.phone!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailingBadge ??
            (statusLabel != null
                ? StatBadge.purple(label: statusLabel!)
                : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20)),
      ),
    );
  }
}
