part of '../customer_list_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// CHART HELPERS
// ═══════════════════════════════════════════════════════════════════

/// Formats a date for axis labels.
String _axisDateLabel(DateTime dt, bool isWeekly) {
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
    final isWeekly = shouldUseWeekly(range);
    final displayData = isWeekly ? aggregateWeekly(data) : data;

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
                    horizontalInterval: chartGridInterval(
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
                    horizontalInterval: chartGridInterval(
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
                      'LBP ${formatLbpFull(avgValue * rate)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
    );
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
    final isWeekly = shouldUseWeekly(range);
    final displayData = isWeekly ? aggregateWeekly(data) : data;

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
                    horizontalInterval: chartGridInterval(
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
    final isWeekly = shouldUseWeekly(range);
    final displayData = isWeekly ? aggregateWeekly(data) : data;

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
                    horizontalInterval: chartGridInterval(
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
