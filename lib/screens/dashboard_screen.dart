import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/stat_badge.dart';
import 'expense_list_screen.dart';
import 'pos_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(business?.name ?? 'Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(todaySnapshotProvider);
              ref.invalidate(monthRevenueProvider);
              ref.invalidate(recurringExpensesProvider);
              ref.invalidate(oneOffExpensesProvider);
              ref.invalidate(bestSellerProvider);
              ref.invalidate(productListProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySnapshotProvider);
          ref.invalidate(monthRevenueProvider);
          ref.invalidate(recurringExpensesProvider);
          ref.invalidate(oneOffExpensesProvider);
          ref.invalidate(bestSellerProvider);
          ref.invalidate(productListProvider);
          await ref.read(todaySnapshotProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // 1. Today's Revenue Hero Card (Gradient Variant)
            _TodayCard(rate: rate),
            const SizedBox(height: 16),

            // 2. Financial Insights (Flat Variant)
            _FinancialCard(rate: rate),
            const SizedBox(height: 16),

            // 3. Quick Actions Row (PillButtons)
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Add Sale',
                    icon: Icons.add_shopping_cart_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PosScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PillButton(
                    label: 'Manage Expenses',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ExpenseListScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Date Range Filter & Insights
            _DateRangeCard(rate: rate),
            const SizedBox(height: 16),

            // 5. Inventory Overview
            const _InventoryCard(),
            const SizedBox(height: 16),

            // 6. Best Seller Card
            const _BestSellerCard(),
          ],
        ),
      ),
    );
  }
}

/// Today's Revenue Hero MetricCard (Gradient Variant).
class _TodayCard extends ConsumerWidget {
  final double rate;
  const _TodayCard({required this.rate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayAsync = ref.watch(todaySnapshotProvider);

    return MetricCard(
      title: "Today's Sales",
      icon: Icons.today_rounded,
      isGradient: true,
      child: todayAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (error, _) => Text(
          'Failed to load today\'s data',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        data: (snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${snapshot.totalUsd.toStringAsFixed(2)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            if (rate > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'LBP ${_formatLbp(snapshot.totalUsd * rate)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${snapshot.count} sale${snapshot.count == 1 ? '' : 's'} completed today',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLbp(double amount) {
    final str = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write(',');
      buf.write(str[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }
}

/// Financial Insights MetricCard (Flat Variant with Chevron to Manage Expenses).
class _FinancialCard extends ConsumerWidget {
  final double rate;
  const _FinancialCard({required this.rate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthRevAsync = ref.watch(monthRevenueProvider);
    final recurringAsync = ref.watch(recurringExpensesProvider);
    final oneOffAsync = ref.watch(oneOffExpensesProvider);

    final isLoading =
        monthRevAsync.isLoading ||
        recurringAsync.isLoading ||
        oneOffAsync.isLoading;

    final monthRev = monthRevAsync.valueOrNull ?? 0;
    final recurring = recurringAsync.valueOrNull ?? 0;
    final oneOff = oneOffAsync.valueOrNull ?? 0;
    final netProfit = monthRev - recurring - oneOff;

    return MetricCard(
      title: 'Financial Insights',
      icon: Icons.insights_rounded,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
        );
      },
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Net Profit',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${netProfit < 0 ? '-' : ''}\$${netProfit.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: netProfit >= 0
                                ? AppColors.emeraldGreen
                                : AppColors.statusError,
                          ),
                        ),
                      ],
                    ),
                    StatBadge(
                      label: netProfit >= 0 ? '+Profit' : '-Loss',
                      backgroundColor: netProfit >= 0
                          ? AppColors.emeraldGreenBg
                          : AppColors.statusErrorBg,
                      textColor: netProfit >= 0
                          ? AppColors.emeraldGreen
                          : AppColors.statusError,
                    ),
                  ],
                ),
                const Divider(height: 20),
                _StatLine(
                  label: 'This Month Revenue',
                  value: '\$${monthRev.toStringAsFixed(2)}',
                  valueColor: AppColors.emeraldGreen,
                ),
                const SizedBox(height: 6),
                _StatLine(
                  label: 'Recurring Expenses',
                  value: '-\$${recurring.toStringAsFixed(2)}',
                  valueColor: AppColors.statusError,
                ),
                const SizedBox(height: 6),
                _StatLine(
                  label: 'One-Off Expenses',
                  value: '-\$${oneOff.toStringAsFixed(2)}',
                  valueColor: AppColors.statusError,
                ),
              ],
            ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Inventory overview card.
class _InventoryCard extends ConsumerWidget {
  const _InventoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(inventorySnapshotProvider);
    final productsAsync = ref.watch(productListProvider);

    return MetricCard(
      title: 'Inventory Overview',
      icon: Icons.inventory_2_outlined,
      child: productsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => const Text(
          'Failed to load inventory',
          style: TextStyle(color: AppColors.statusError),
        ),
        data: (_) => Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.screenBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Stock Value',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${snapshot.totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: snapshot.lowStockCount > 0
                      ? AppColors.warningOrangeBg
                      : AppColors.emeraldGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Items',
                      style: TextStyle(
                        fontSize: 11,
                        color: snapshot.lowStockCount > 0
                            ? AppColors.warningOrange
                            : AppColors.emeraldGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.lowStockCount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: snapshot.lowStockCount > 0
                            ? AppColors.warningOrange
                            : AppColors.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Best seller product (this month) card.
class _BestSellerCard extends ConsumerWidget {
  const _BestSellerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestSellerAsync = ref.watch(bestSellerProvider);

    return MetricCard(
      title: 'Best Seller (This Month)',
      icon: Icons.star_rounded,
      child: bestSellerAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => const Text('Failed to load best seller'),
        data: (snapshot) {
          if (snapshot == null) {
            return const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 24, color: AppColors.textSecondary),
                SizedBox(width: 12),
                Text(
                  'No sales recorded yet this month',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                      snapshot.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${snapshot.totalQuantity} units sold this month',
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
    );
  }
}

/// Date range filter card.
class _DateRangeCard extends ConsumerWidget {
  final double rate;
  const _DateRangeCard({required this.rate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final snapshotAsync = ref.watch(rangeSnapshotProvider);

    return MetricCard(
      title: 'Date Range Insights',
      icon: Icons.date_range_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: selectedRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now(),
                          ),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(selectedDateRangeProvider.notifier).state = picked;
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: Text(
                    selectedRange == null
                        ? 'Select Range'
                        : '${_formatDate(selectedRange.start)} - ${_formatDate(selectedRange.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (selectedRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  tooltip: 'Clear filter',
                  onPressed: () {
                    ref.read(selectedDateRangeProvider.notifier).state = null;
                  },
                ),
              ],
            ],
          ),
          if (selectedRange != null) ...[
            const SizedBox(height: 14),
            snapshotAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load range data',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              data: (snapshot) {
                if (snapshot == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    _StatLine(
                      label: 'Sales Count',
                      value: '${snapshot.salesCount}',
                      valueColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    _StatLine(
                      label: 'Revenue',
                      value: '\$${snapshot.revenueUsd.toStringAsFixed(2)}',
                      valueColor: AppColors.emeraldGreen,
                    ),
                    const SizedBox(height: 4),
                    _StatLine(
                      label: 'Expenses',
                      value: '-\$${snapshot.expensesUsd.toStringAsFixed(2)}',
                      valueColor: AppColors.statusError,
                    ),
                    const Divider(height: 12),
                    _StatLine(
                      label: 'Net Capital',
                      value:
                          '${snapshot.capitalUsd < 0 ? '-' : ''}\$${snapshot.capitalUsd.abs().toStringAsFixed(2)}',
                      valueColor: snapshot.capitalUsd >= 0
                          ? AppColors.emeraldGreen
                          : AppColors.statusError,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
