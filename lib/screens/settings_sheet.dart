import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late TextEditingController _businessNameController;
  late TextEditingController _rateController;

  bool _isSavingName = false;
  String? _nameErrorText;

  bool _isSavingRate = false;
  String? _rateErrorText;

  @override
  void initState() {
    super.initState();
    final business = ref.read(currentBusinessProvider);
    _businessNameController = TextEditingController(
      text: business?.name ?? '',
    );
    _rateController = TextEditingController(
      text: business?.currencyRate.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String _formatUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) return 'Never updated';

    final now = DateTime.now();
    final local = updatedAt.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  Future<void> _saveBusinessName() async {
    final name = _businessNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameErrorText = 'Business name cannot be empty');
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameErrorText = null;
    });

    try {
      await ref.read(authProvider.notifier).updateBusinessName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business name updated successfully'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nameErrorText = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _saveRate() async {
    final text = _rateController.text.trim();
    if (text.isEmpty) {
      setState(() => _rateErrorText = 'Please enter a rate');
      return;
    }

    final rate = double.tryParse(text);
    if (rate == null || rate <= 0) {
      setState(() => _rateErrorText = 'Enter a valid positive number');
      return;
    }

    setState(() {
      _isSavingRate = true;
      _rateErrorText = null;
    });

    try {
      await ref.read(authProvider.notifier).updateCurrencyRate(rate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exchange rate updated to ${rate.toStringAsFixed(0)} LBP/USD',
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rateErrorText = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRate = false);
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription plans comparison is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      nav.pop(); // Close settings sheet
      await ref.read(authProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = ref.watch(currentBusinessProvider);
    final sheetHeight = MediaQuery.of(context).size.height * 0.70;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.baseWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: AppColors.primaryPurple,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Subscription Plan Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 22,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Plan',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Free Trial',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 2. See other plans button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showComingSoon,
                            icon: const Icon(Icons.stars_outlined, size: 18),
                            label: const Text('See other plans'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Edit Business Name Section
                  Text(
                    'BUSINESS PROFILE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textGray,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.baseWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _businessNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            errorText: _nameErrorText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSavingName ? null : _saveBusinessName,
                            child: _isSavingName
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Business Name'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Currency Rate Editor Section
                  Text(
                    'CURRENCY & RATE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textGray,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.baseWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.currency_exchange_rounded,
                              size: 20,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Exchange Rate (LBP per USD)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 28),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Last updated: ${_formatUpdatedAt(business?.currencyRateUpdatedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            prefixText: 'LBP ',
                            prefixStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentDark,
                            ),
                            hintText: 'e.g. 89500',
                            errorText: _rateErrorText,
                            suffixText: '= 1 USD',
                            suffixStyle: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSavingRate ? null : _saveRate,
                            child: _isSavingRate
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Exchange Rate'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 12),

                  // 5. Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusError,
                        side: const BorderSide(color: AppColors.statusError),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
