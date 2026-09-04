import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/tag.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/tag_provider.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import '../widgets/tag_picker_sheet.dart';
import 'customer_form_screen.dart';
import 'receipt_screen.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _customerDetailProvider =
    FutureProvider.family<Customer, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerById(customerId);
});

final _customerMonthlySalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerSalesThisMonth(customerId);
});

final _customerTotalSalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerTotalSales(customerId);
});

final _customerFavoriteProductProvider =
    FutureProvider.family<FavoriteProduct?, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerFavoriteProduct(customerId);
});

/// History period enum — includes "All Time" as default.
enum HistoryPeriod { allTime, thisWeek, thisMonth, lastMonth, custom }

/// Record used as provider family key: (customerId, fromIso?, toIso?)
typedef _SalesFilterKey = ({String id, String? from, String? to});

final _customerSalesFilteredProvider =
    FutureProvider.family<List<Sale>, _SalesFilterKey>((ref, key) async {
  DateTime? from;
  DateTime? to;
  if (key.from != null) from = DateTime.parse(key.from!);
  if (key.to != null) to = DateTime.parse(key.to!);

  return ref.watch(customerServiceProvider).getSalesForCustomerFiltered(
        key.id,
        from: from,
        to: to,
      );
});

// ── Main Screen ───────────────────────────────────────────────────────────────

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  HistoryPeriod _historyPeriod = HistoryPeriod.allTime;
  DateTimeRange? _customRange;

  _SalesFilterKey get _filterKey {
    final range = _dateRange;
    return (
      id: widget.customerId,
      from: range?.start.toIso8601String(),
      to: range?.end.toIso8601String(),
    );
  }

  DateTimeRange? get _dateRange {
    final now = DateTime.now();
    switch (_historyPeriod) {
      case HistoryPeriod.allTime:
        return null;
      case HistoryPeriod.thisWeek:
        final weekday = now.weekday; // 1 = Monday
        final monday = now.subtract(Duration(days: weekday - 1));
        return DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day),
          end: now,
        );
      case HistoryPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case HistoryPeriod.lastMonth:
        final firstOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: firstOfLastMonth, end: lastOfLastMonth);
      case HistoryPeriod.custom:
        return _customRange;
    }
  }

  void _invalidateAll() {
    ref.invalidate(_customerDetailProvider(widget.customerId));
    ref.invalidate(_customerMonthlySalesProvider(widget.customerId));
    ref.invalidate(_customerTotalSalesProvider(widget.customerId));
    ref.invalidate(_customerFavoriteProductProvider(widget.customerId));
    ref.invalidate(_customerSalesFilteredProvider(_filterKey));
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(_customerDetailProvider(widget.customerId));
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _invalidateAll,
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 56, color: AppColors.statusError),
                const SizedBox(height: 16),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(_customerDetailProvider(widget.customerId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (customer) => _CustomerDetailBody(
          customer: customer,
          customerId: widget.customerId,
          currencyRate: rate,
          historyPeriod: _historyPeriod,
          customRange: _customRange,
          filterKey: _filterKey,
          onPeriodChanged: (period) async {
            if (period == HistoryPeriod.custom) {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: _customRange ??
                    DateTimeRange(
                      start:
                          DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    ),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _customRange = picked;
                  _historyPeriod = HistoryPeriod.custom;
                });
              }
            } else {
              setState(() => _historyPeriod = period);
            }
          },
          onCustomerEdited: () {
            ref.invalidate(_customerDetailProvider(widget.customerId));
            ref.invalidate(customerListProvider);
          },
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _CustomerDetailBody extends ConsumerWidget {
  final Customer customer;
  final String customerId;
  final double currencyRate;
  final HistoryPeriod historyPeriod;
  final DateTimeRange? customRange;
  final _SalesFilterKey filterKey;
  final void Function(HistoryPeriod) onPeriodChanged;
  final VoidCallback onCustomerEdited;

  const _CustomerDetailBody({
    required this.customer,
    required this.customerId,
    required this.currencyRate,
    required this.historyPeriod,
    required this.customRange,
    required this.filterKey,
    required this.onPeriodChanged,
    required this.onCustomerEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthlyCountAsync =
        ref.watch(_customerMonthlySalesProvider(customerId));
    final totalCountAsync = ref.watch(_customerTotalSalesProvider(customerId));
    final favoriteProductAsync =
        ref.watch(_customerFavoriteProductProvider(customerId));
    final salesAsync = ref.watch(_customerSalesFilteredProvider(filterKey));
    final initial =
        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

    final hasPhone =
        customer.phone != null && customer.phone!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.primaryPurple.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  customer.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasPhone) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final changed =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerFormScreen(customer: customer),
                            ),
                          );
                          if (changed == true) onCustomerEdited();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    if (hasPhone) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _WhatsAppButton(phone: customer.phone!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Customer Tags ────────────────────────────────────────
          _CustomerTagsSection(
            customerId: customerId,
            ref: ref,
          ),

          const SizedBox(height: 16),

          // 2. Orders Stats Row
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'This Month',
                  icon: Icons.calendar_today_rounded,
                  child: monthlyCountAsync.when(
                    data: (count) => Text(
                      '$count orders',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const Text('0'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  title: 'All-Time Orders',
                  icon: Icons.shopping_bag_outlined,
                  child: totalCountAsync.when(
                    data: (count) => Text(
                      '$count total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const Text('0'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Favorite Product Card
          MetricCard(
            title: 'Favorite Product',
            icon: Icons.star_rounded,
            child: favoriteProductAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) =>
                  const Text('Could not load favorite product'),
              data: (favorite) {
                if (favorite == null) {
                  return const Row(
                    children: [
                      Icon(Icons.star_outline_rounded,
                          color: AppColors.inactiveGray),
                      SizedBox(width: 10),
                      Text(
                        'No orders recorded yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrangeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.warningOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${favorite.totalQuantity} units bought in total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 4. Order History header + period filter
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ORDER HISTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Period filter chips
          _HistoryPeriodFilter(
            selected: historyPeriod,
            customRange: customRange,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 12),

          // History list
          salesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Failed to load order history: $err'),
            ),
            data: (sales) {
              if (sales.isEmpty) {
                final isFiltered = historyPeriod != HistoryPeriod.allTime;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 40, color: AppColors.inactiveGray),
                        const SizedBox(height: 8),
                        Text(
                          isFiltered
                              ? 'No orders in this period'
                              : 'No past orders found',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final local = sale.createdAt.toLocal();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${local.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primaryPurple,
                                height: 1,
                              ),
                            ),
                            Text(
                              _monthAbbr(local.month),
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        '\$${sale.totalUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatTime(local)} · ${sale.paymentType == 'cash' ? 'Cash' : 'Card'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currencyRate > 0)
                            Text(
                              'LBP ${_formatLbp(sale.totalLbp)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          final items = await ref
                              .read(saleServiceProvider)
                              .getSaleItems(sale.id);
                          final saleWithItems =
                              sale.copyWith(items: items);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  sale: saleWithItems,
                                  isFromCheckout: false,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e
                                      .toString()
                                      .replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ap';
  }

  String _formatLbp(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}

// ── WhatsApp Button ───────────────────────────────────────────────────────────

class _WhatsAppButton extends StatelessWidget {
  final String phone;

  const _WhatsAppButton({required this.phone});

  /// Strips all non-digit characters for wa.me (international format, no +/spaces).
  String get _waPhone => phone.replaceAll(RegExp(r'\D'), '');

  Future<void> _openWhatsApp(BuildContext context) async {
    final digits = _waPhone;
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone number on file')),
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/$digits');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp — is it installed?'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp — is it installed?'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openWhatsApp(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      icon: SvgPicture.asset(
        'asset/whatsapp-color-svgrepo-com.svg',
        width: 18,
        height: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      label: const Text(
        'WhatsApp',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── History Period Filter ─────────────────────────────────────────────────────

class _HistoryPeriodFilter extends StatelessWidget {
  final HistoryPeriod selected;
  final DateTimeRange? customRange;
  final void Function(HistoryPeriod) onChanged;

  static const _labels = {
    HistoryPeriod.allTime: 'All Time',
    HistoryPeriod.thisWeek: 'This Week',
    HistoryPeriod.thisMonth: 'This Month',
    HistoryPeriod.lastMonth: 'Last Month',
    HistoryPeriod.custom: 'Custom',
  };

  const _HistoryPeriodFilter({
    required this.selected,
    required this.customRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryPeriod.values.map((period) {
          final isActive = selected == period;
          String label = _labels[period]!;
          // Show date range for custom when selected
          if (period == HistoryPeriod.custom &&
              isActive &&
              customRange != null) {
            final s = customRange!.start;
            final e = customRange!.end;
            label =
                '${s.day}/${s.month} – ${e.day}/${e.month}';
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isActive,
              onSelected: (_) => onChanged(period),
              selectedColor: AppColors.primaryPurple,
              backgroundColor: AppColors.cardSurface,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.borderLight,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Customer Tags Section ─────────────────────────────────────────────────────

class _CustomerTagsSection extends ConsumerWidget {
  final String customerId;
  final WidgetRef ref;

  const _CustomerTagsSection({
    required this.customerId,
    required this.ref,
  });

  void _showTagPicker(BuildContext context, List<Tag> currentTags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TagPickerSheet(
        customerId: customerId,
        currentTags: currentTags,
      ),
    );
  }

  Future<void> _removeTag(
      BuildContext context, WidgetRef ref, Tag tag) async {
    try {
      await ref
          .read(tagActionsProvider)
          .detachTagFromCustomer(customerId, tag.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not remove tag: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(customerTagsProvider(customerId));

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        final atMax = tags.length >= kMaxTagsPerCustomer;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Existing tag chips
                ...tags.map((tag) => Chip(
                      label: Text(tag.label),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryPurple,
                      ),
                      backgroundColor:
                          AppColors.primaryPurple.withValues(alpha: 0.06),
                      side: BorderSide(
                        color:
                            AppColors.primaryPurple.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      deleteIconColor: AppColors.primaryPurple,
                      onDeleted: () => _removeTag(context, ref, tag),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    )),

                // Add tag button (or max message)
                if (atMax)
                  Chip(
                    label: const Text('Max 4 tags'),
                    avatar: const Icon(Icons.info_outline,
                        size: 14, color: AppColors.textSecondary),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  ActionChip(
                    label: const Text('Add Tag'),
                    avatar: const Icon(Icons.add,
                        size: 16, color: AppColors.primaryPurple),
                    onPressed: () => _showTagPicker(context, tags),
                    backgroundColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
