import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/crm_analytics_service.dart';
import 'auth_provider.dart';

// ─────────────────────── Period enum & state ───────────────────────

/// Preset time periods for the CRM overview.
enum CrmPeriod { thisWeek, thisMonth, lastMonth, custom }

/// The currently selected period preset.
final crmSelectedPeriodProvider =
    StateProvider<CrmPeriod>((ref) => CrmPeriod.thisMonth);

/// Stores the user-picked custom date range (only used when period == custom).
final crmCustomDateRangeProvider =
    StateProvider<DateTimeRange?>((ref) => null);

/// Derives the actual [DateTimeRange] from the selected [CrmPeriod].
final crmDateRangeProvider = Provider<DateTimeRange>((ref) {
  final period = ref.watch(crmSelectedPeriodProvider);
  final now = DateTime.now();

  switch (period) {
    case CrmPeriod.thisWeek:
      // Monday → today (ISO week starts on Monday)
      final weekday = now.weekday; // 1 = Mon, 7 = Sun
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      final end = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: end);

    case CrmPeriod.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: end);

    case CrmPeriod.lastMonth:
      final firstOfThisMonth = DateTime(now.year, now.month, 1);
      final lastDayPrev = firstOfThisMonth.subtract(const Duration(days: 1));
      final start = DateTime(lastDayPrev.year, lastDayPrev.month, 1);
      return DateTimeRange(start: start, end: lastDayPrev);

    case CrmPeriod.custom:
      final custom = ref.watch(crmCustomDateRangeProvider);
      if (custom != null) return custom;
      // Fallback to this month if custom hasn't been picked yet
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: end);
  }
});

// ─────────────────────── Service provider ───────────────────────

final crmAnalyticsServiceProvider = Provider<CrmAnalyticsService>((ref) {
  return CrmAnalyticsService(ref.watch(supabaseClientProvider));
});

// ─────────────────────── Data providers ───────────────────────

/// a) Revenue over time
final crmRevenueOverTimeProvider =
    FutureProvider<List<DateValue>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(crmDateRangeProvider);
  return ref.watch(crmAnalyticsServiceProvider).getRevenueOverTime(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});

/// b) Top-selling products (top 5)
final crmTopSellingProductsProvider =
    FutureProvider<List<ProductQuantity>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(crmDateRangeProvider);
  return ref.watch(crmAnalyticsServiceProvider).getTopSellingProducts(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});

/// c) Average order value
final crmAverageOrderValueProvider = FutureProvider<double>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  final range = ref.watch(crmDateRangeProvider);
  return ref.watch(crmAnalyticsServiceProvider).getAverageOrderValue(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});

/// d) Orders over time
final crmOrdersOverTimeProvider =
    FutureProvider<List<DateValue>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(crmDateRangeProvider);
  return ref.watch(crmAnalyticsServiceProvider).getOrdersOverTime(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});

/// e) New customers over time
final crmNewCustomersOverTimeProvider =
    FutureProvider<List<DateValue>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  final range = ref.watch(crmDateRangeProvider);
  return ref.watch(crmAnalyticsServiceProvider).getNewCustomersOverTime(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});
