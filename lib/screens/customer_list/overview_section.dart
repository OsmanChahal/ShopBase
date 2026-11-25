part of '../customer_list_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// OVERVIEW SECTION
// ═══════════════════════════════════════════════════════════════════

class _OverviewSection extends ConsumerWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    final revenueAsync = ref.watch(crmRevenueOverTimeProvider);
    final topProductsAsync = ref.watch(crmTopSellingProductsProvider);
    final avgOrderAsync = ref.watch(crmAverageOrderValueProvider);
    final ordersAsync = ref.watch(crmOrdersOverTimeProvider);
    final newCustomersAsync = ref.watch(crmNewCustomersOverTimeProvider);

    final isLoading = revenueAsync.isLoading ||
        topProductsAsync.isLoading ||
        avgOrderAsync.isLoading ||
        ordersAsync.isLoading ||
        newCustomersAsync.isLoading;

    final hasError = revenueAsync.hasError ||
        topProductsAsync.hasError ||
        avgOrderAsync.hasError ||
        ordersAsync.hasError ||
        newCustomersAsync.hasError;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        // ─── Period selector ───
        const _PeriodSelector(),
        const SizedBox(height: 14),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.statusError),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load overview data',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(crmRevenueOverTimeProvider);
                      ref.invalidate(crmTopSellingProductsProvider);
                      ref.invalidate(crmAverageOrderValueProvider);
                      ref.invalidate(crmOrdersOverTimeProvider);
                      ref.invalidate(crmNewCustomersOverTimeProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // a) Revenue Over Time
          _RevenueChart(
            data: revenueAsync.valueOrNull ?? [],
            range: ref.watch(crmDateRangeProvider),
          ),
          const SizedBox(height: 14),

          // b) Top-Selling Products
          _TopProductsChart(
            data: topProductsAsync.valueOrNull ?? [],
          ),
          const SizedBox(height: 14),

          // c) Average Order Value
          _AverageOrderCard(
            avgValue: avgOrderAsync.valueOrNull ?? 0,
            rate: rate,
          ),
          const SizedBox(height: 14),

          // d) Orders Per Period
          _OrdersChart(
            data: ordersAsync.valueOrNull ?? [],
            range: ref.watch(crmDateRangeProvider),
          ),
          const SizedBox(height: 14),

          // e) New Customers Over Time
          _NewCustomersChart(
            data: newCustomersAsync.valueOrNull ?? [],
            range: ref.watch(crmDateRangeProvider),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PERIOD SELECTOR
// ═══════════════════════════════════════════════════════════════════

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector();

  static const _labels = {
    CrmPeriod.thisWeek: 'This Week',
    CrmPeriod.thisMonth: 'This Month',
    CrmPeriod.lastMonth: 'Last Month',
    CrmPeriod.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(crmSelectedPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CrmPeriod.values.map((period) {
          final isActive = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_labels[period]!),
              selected: isActive,
              onSelected: (_) async {
                if (period == CrmPeriod.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: ref.read(crmCustomDateRangeProvider) ??
                        DateTimeRange(
                          start: DateTime.now()
                              .subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    ref.read(crmCustomDateRangeProvider.notifier).state =
                        picked;
                    ref.read(crmSelectedPeriodProvider.notifier).state =
                        CrmPeriod.custom;
                  }
                } else {
                  ref.read(crmSelectedPeriodProvider.notifier).state = period;
                }
              },
              selectedColor: AppColors.primaryPurple,
              backgroundColor: AppColors.cardSurface,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}
