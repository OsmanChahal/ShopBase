import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../services/customer_service.dart';
import 'customer_provider.dart';

// Data for the customer detail screen. These read from Supabase through
// CustomerService (online-only), unlike the customer list, which is local.

final customerDetailProvider =
    FutureProvider.family<Customer, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerById(customerId);
});

final customerMonthlySalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerSalesThisMonth(customerId);
});

final customerTotalSalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerTotalSales(customerId);
});

final customerFavoriteProductProvider =
    FutureProvider.family<FavoriteProduct?, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerFavoriteProduct(customerId);
});

/// Sales-history period filter on the customer detail screen.
enum HistoryPeriod { allTime, thisWeek, thisMonth, lastMonth, custom }

/// Family key for [customerSalesFilteredProvider]: customer id plus the
/// optional range bounds as ISO-8601 strings (records compare by value).
typedef CustomerSalesFilterKey = ({String id, String? from, String? to});

/// Builds the [customerSalesFilteredProvider] key for a customer and range.
CustomerSalesFilterKey customerSalesFilterKey(
  String customerId,
  DateTimeRange? range,
) {
  return (
    id: customerId,
    from: range?.start.toIso8601String(),
    to: range?.end.toIso8601String(),
  );
}

final customerSalesFilteredProvider =
    FutureProvider.family<List<Sale>, CustomerSalesFilterKey>((ref, key) async {
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

/// Date range for a [HistoryPeriod], or null for all time.
///
/// Note: this intentionally differs from `crmDateRangeProvider` — "this week"
/// and "this month" end at [now] (not midnight), and an unset custom range
/// returns null rather than falling back to this month.
DateTimeRange? historyPeriodRange(
  HistoryPeriod period, {
  DateTimeRange? customRange,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  switch (period) {
    case HistoryPeriod.allTime:
      return null;
    case HistoryPeriod.thisWeek:
      final weekday = current.weekday; // 1 = Monday
      final monday = current.subtract(Duration(days: weekday - 1));
      return DateTimeRange(
        start: DateTime(monday.year, monday.month, monday.day),
        end: current,
      );
    case HistoryPeriod.thisMonth:
      return DateTimeRange(
        start: DateTime(current.year, current.month, 1),
        end: current,
      );
    case HistoryPeriod.lastMonth:
      final firstOfLastMonth = DateTime(current.year, current.month - 1, 1);
      final lastOfLastMonth = DateTime(current.year, current.month, 0);
      return DateTimeRange(start: firstOfLastMonth, end: lastOfLastMonth);
    case HistoryPeriod.custom:
      return customRange;
  }
}
