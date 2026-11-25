import 'package:flutter/material.dart' show DateTimeRange;
import '../services/crm_analytics_service.dart' show DateValue;

/// Sums daily [DateValue]s into weekly buckets keyed by the Monday that
/// starts each week, sorted by date.
List<DateValue> aggregateWeekly(List<DateValue> daily) {
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

/// Whether a chart over [range] should use weekly buckets (more than 31 days).
bool shouldUseWeekly(DateTimeRange range) {
  return range.end.difference(range.start).inDays > 31;
}

/// Horizontal grid-line interval for a chart whose largest value is
/// [maxValue], stepping through 1 / 5 / 20 / 100 / 500, then a fifth of max.
double chartGridInterval(double maxValue) {
  if (maxValue <= 0) return 1;
  if (maxValue <= 5) return 1;
  if (maxValue <= 20) return 5;
  if (maxValue <= 100) return 20;
  if (maxValue <= 500) return 100;
  if (maxValue <= 2000) return 500;
  return (maxValue / 5).ceilToDouble();
}
