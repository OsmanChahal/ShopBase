import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../providers/crm_overview_provider.dart';
import '../providers/customer_provider.dart';
import '../services/crm_analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/customer_list_tile.dart';
import '../widgets/floating_action_pill.dart';
import '../widgets/metric_card.dart';
import '../widgets/stat_badge.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import 'home_screen.dart'; // for customerTabTapNotifier

/// Family provider to fetch monthly order count for a customer list row.
final _customerMonthlyOrderCountProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerSalesThisMonth(customerId);
});

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  /// 0 = Overview, 1 = Customers
  int _selectedSection = 0;
  late final TextEditingController _searchController;

  /// Tracks the last seen value of [customerTabTapNotifier] so we can
  /// detect re-selection of the Customers tab and reset to Overview.
  int _lastTabTap = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(customerSearchQueryProvider),
    );
    _lastTabTap = customerTabTapNotifier.value;
    customerTabTapNotifier.addListener(_onCustomerTabTapped);
  }

  void _onCustomerTabTapped() {
    final current = customerTabTapNotifier.value;
    if (current != _lastTabTap) {
      _lastTabTap = current;
      if (mounted && _selectedSection != 0) {
        setState(() => _selectedSection = 0);
      }
    }
  }

  @override
  void dispose() {
    customerTabTapNotifier.removeListener(_onCustomerTabTapped);
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
  }

  void _navigateToDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customer.id),
      ),
    );
  }

  void _invalidateOverview() {
    ref.invalidate(crmRevenueOverTimeProvider);
    ref.invalidate(crmTopSellingProductsProvider);
    ref.invalidate(crmAverageOrderValueProvider);
    ref.invalidate(crmOrdersOverTimeProvider);
    ref.invalidate(crmNewCustomersOverTimeProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              if (_selectedSection == 0) {
                _invalidateOverview();
              } else {
                ref.invalidate(customerListProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Segmented control ───
          _SectionSwitcher(
            selectedIndex: _selectedSection,
            onChanged: (i) => setState(() => _selectedSection = i),
          ),

          // ─── Section body ───
          Expanded(
            child: _selectedSection == 0
                ? const _OverviewSection()
                : _CustomerListSection(
                    searchController: _searchController,
                    onAdd: _navigateToAdd,
                    onTapCustomer: _navigateToDetail,
                  ),
          ),
        ],
      ),
      // Only show the FAB on the Customers list section
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _selectedSection == 1
          ? FloatingActionPill(
              icon: Icons.person_add_rounded,
              onPressed: _navigateToAdd,
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEGMENTED CONTROL
// ═══════════════════════════════════════════════════════════════════

class _SectionSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SectionSwitcher({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _tab('Overview', 0),
            _tab('Customers', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

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

// ═══════════════════════════════════════════════════════════════════
// CHART HELPERS
// ═══════════════════════════════════════════════════════════════════

/// Aggregates daily [DateValue] data into weekly buckets
/// (week starting on Monday).
List<DateValue> _aggregateWeekly(List<DateValue> daily) {
  if (daily.isEmpty) return [];
  final grouped = <DateTime, double>{};
  for (final dv in daily) {
    // Monday of the ISO week
    final weekday = dv.date.weekday; // 1=Mon
    final monday = dv.date.subtract(Duration(days: weekday - 1));
    final key = DateTime(monday.year, monday.month, monday.day);
    grouped[key] = (grouped[key] ?? 0) + dv.value;
  }
  final result = grouped.entries
      .map((e) => DateValue(date: e.key, value: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return result;
}

/// Returns true if the range spans more than 31 days → use weekly.
bool _shouldUseWeekly(DateTimeRange range) {
  return range.end.difference(range.start).inDays > 31;
}

/// Formats a date for axis labels.
String _axisDateLabel(DateTime dt, bool isWeekly) {
  if (isWeekly) {
    return '${dt.day}/${dt.month}';
  }
  return '${dt.day}/${dt.month}';
}

Widget _emptyState(String message) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 40, color: AppColors.inactiveGray.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// a) REVENUE OVER TIME — Line Chart
// ═══════════════════════════════════════════════════════════════════

class _RevenueChart extends StatelessWidget {
  final List<DateValue> data;
  final DateTimeRange range;

  const _RevenueChart({required this.data, required this.range});

  @override
  Widget build(BuildContext context) {
    final isWeekly = _shouldUseWeekly(range);
    final displayData = isWeekly ? _aggregateWeekly(data) : data;

    return MetricCard(
      title: 'Revenue Over Time',
      icon: Icons.trending_up_rounded,
      child: displayData.isEmpty
          ? _emptyState('No sales in this period')
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calcInterval(
                        displayData.map((d) => d.value).reduce(math.max)),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: _lineTitles(displayData, isWeekly),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        displayData.length,
                        (i) => FlSpot(i.toDouble(), displayData[i].value),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.primaryPurple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: displayData.length <= 14,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.primaryPurple,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color:
                            AppColors.primaryPurple.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.primaryPurpleDark.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final dv = displayData[spot.x.toInt()];
                        return LineTooltipItem(
                          '\$${dv.value.toStringAsFixed(2)}\n${_axisDateLabel(dv.date, isWeekly)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  minY: 0,
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// b) TOP-SELLING PRODUCTS — Bar Chart
// ═══════════════════════════════════════════════════════════════════

class _TopProductsChart extends StatelessWidget {
  final List<ProductQuantity> data;

  const _TopProductsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Top-Selling Products',
      icon: Icons.leaderboard_rounded,
      child: data.isEmpty
          ? _emptyState('No products sold in this period')
          : SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (data.first.quantity * 1.2).ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calcInterval(
                        data.first.quantity.toDouble()),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final name = data[idx].name;
                          return SideTitleWidget(
                            meta: meta,
                            child: SizedBox(
                              width: 56,
                              child: Text(
                                name.length > 8
                                    ? '${name.substring(0, 7)}…'
                                    : name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].quantity.toDouble(),
                          width: 22,
                          color: AppColors.primaryPurple,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.primaryPurpleDark.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[groupIndex].name}\n${rod.toY.toInt()} units',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// c) AVERAGE ORDER VALUE — Stat Card
// ═══════════════════════════════════════════════════════════════════

class _AverageOrderCard extends StatelessWidget {
  final double avgValue;
  final double rate;

  const _AverageOrderCard({required this.avgValue, required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MetricCard(
      title: 'Average Order Value',
      icon: Icons.paid_outlined,
      child: avgValue == 0
          ? _emptyState('No sales in this period')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${avgValue.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (rate > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'LBP ${_formatLbp(avgValue * rate)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
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

// ═══════════════════════════════════════════════════════════════════
// d) ORDERS PER PERIOD — Bar Chart
// ═══════════════════════════════════════════════════════════════════

class _OrdersChart extends StatelessWidget {
  final List<DateValue> data;
  final DateTimeRange range;

  const _OrdersChart({required this.data, required this.range});

  @override
  Widget build(BuildContext context) {
    final isWeekly = _shouldUseWeekly(range);
    final displayData = isWeekly ? _aggregateWeekly(data) : data;

    return MetricCard(
      title: 'Orders Per Period',
      icon: Icons.shopping_cart_outlined,
      child: displayData.isEmpty
          ? _emptyState('No orders in this period')
          : SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (displayData
                              .map((d) => d.value)
                              .reduce(math.max) *
                          1.2)
                      .ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calcInterval(
                        displayData.map((d) => d.value).reduce(math.max)),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: _barTitles(displayData, isWeekly),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(displayData.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: displayData[i].value,
                          width: displayData.length > 14 ? 8 : 18,
                          color: AppColors.primaryPurpleLight,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.primaryPurpleDark.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dv = displayData[groupIndex];
                        return BarTooltipItem(
                          '${rod.toY.toInt()} orders\n${_axisDateLabel(dv.date, isWeekly)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// e) NEW CUSTOMERS OVER TIME — Line Chart
// ═══════════════════════════════════════════════════════════════════

class _NewCustomersChart extends StatelessWidget {
  final List<DateValue> data;
  final DateTimeRange range;

  const _NewCustomersChart({required this.data, required this.range});

  @override
  Widget build(BuildContext context) {
    final isWeekly = _shouldUseWeekly(range);
    final displayData = isWeekly ? _aggregateWeekly(data) : data;

    return MetricCard(
      title: 'New Customers',
      icon: Icons.person_add_alt_1_rounded,
      child: displayData.isEmpty
          ? _emptyState('No new customers in this period')
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calcInterval(
                        displayData.map((d) => d.value).reduce(math.max)),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: _lineTitles(displayData, isWeekly),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        displayData.length,
                        (i) => FlSpot(i.toDouble(), displayData[i].value),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.emeraldGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: displayData.length <= 14,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.emeraldGreen,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color:
                            AppColors.emeraldGreen.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.primaryPurpleDark.withValues(alpha: 0.9),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final dv = displayData[spot.x.toInt()];
                        return LineTooltipItem(
                          '${dv.value.toInt()} customer${dv.value.toInt() == 1 ? '' : 's'}\n${_axisDateLabel(dv.date, isWeekly)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  minY: 0,
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED CHART TITLE BUILDERS
// ═══════════════════════════════════════════════════════════════════

FlTitlesData _lineTitles(List<DateValue> data, bool isWeekly) {
  // Show at most 7 labels to avoid overcrowding
  final interval = data.length <= 7 ? 1 : (data.length / 6).ceil();

  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (value, meta) {
          if (value == meta.max || value == meta.min) {
            return const SizedBox.shrink();
          }
          String label;
          if (value >= 1000) {
            label = '${(value / 1000).toStringAsFixed(1)}k';
          } else {
            label = value % 1 == 0
                ? value.toInt().toString()
                : value.toStringAsFixed(1);
          }
          return Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: interval.toDouble(),
        getTitlesWidget: (value, meta) {
          final idx = value.toInt();
          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              _axisDateLabel(data[idx].date, isWeekly),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    ),
  );
}

FlTitlesData _barTitles(List<DateValue> data, bool isWeekly) {
  final interval = data.length <= 7 ? 1 : (data.length / 6).ceil();

  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        getTitlesWidget: (value, meta) {
          if (value == meta.max || value == meta.min) {
            return const SizedBox.shrink();
          }
          return Text(
            value.toInt().toString(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: interval.toDouble(),
        getTitlesWidget: (value, meta) {
          final idx = value.toInt();
          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              _axisDateLabel(data[idx].date, isWeekly),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Compute a nice interval for horizontal grid lines.
double _calcInterval(double maxValue) {
  if (maxValue <= 0) return 1;
  if (maxValue <= 5) return 1;
  if (maxValue <= 20) return 5;
  if (maxValue <= 100) return 20;
  if (maxValue <= 500) return 100;
  if (maxValue <= 2000) return 500;
  return (maxValue / 5).ceilToDouble();
}

// ═══════════════════════════════════════════════════════════════════
// CUSTOMER LIST SECTION (extracted unchanged from original)
// ═══════════════════════════════════════════════════════════════════

class _CustomerListSection extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onAdd;
  final void Function(Customer) onTapCustomer;

  const _CustomerListSection({
    required this.searchController,
    required this.onAdd,
    required this.onTapCustomer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredCustomersAsync = ref.watch(filteredCustomerListProvider);
    final totalCustomersAsync = ref.watch(customerListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchBar(
            controller: searchController,
            hintText: 'Search by name or phone...',
            onChanged: (val) {
              ref.read(customerSearchQueryProvider.notifier).state = val;
            },
            onClear: () {
              ref.read(customerSearchQueryProvider.notifier).state = '';
            },
          ),
        ),

        // Total customer count subtitle
        totalCustomersAsync.when(
          data: (allCustomers) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              '${allCustomers.length} total customer${allCustomers.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Customer list
        Expanded(
          child: filteredCustomersAsync.when(
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
                    const Text(
                      'Failed to load customers',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().replaceAll('Exception: ', ''),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(customerListProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (customers) {
              if (customers.isEmpty) {
                final query = ref.watch(customerSearchQueryProvider);
                if (query.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 56, color: AppColors.inactiveGray),
                        const SizedBox(height: 12),
                        Text(
                          'No customers match "$query"',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 72,
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No customers yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first customer',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(customerListProvider);
                  await ref.read(customerListProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerRowItem(
                      customer: customer,
                      onTap: () => onTapCustomer(customer),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerRowItem extends ConsumerWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerRowItem({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderCountAsync =
        ref.watch(_customerMonthlyOrderCountProvider(customer.id));

    final badge = orderCountAsync.when(
      data: (count) => StatBadge.purple(
        label: '$count order${count == 1 ? '' : 's'}',
        icon: Icons.shopping_bag_outlined,
      ),
      loading: () => StatBadge.purple(label: '...'),
      error: (_, _) => null,
    );

    return CustomerListTile(
      customer: customer,
      trailingBadge: badge,
      onTap: onTap,
    );
  }
}
