import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dashboard_service.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

/// Provides the DashboardService instance.
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(supabaseClientProvider));
});

/// Today's sales snapshot (total + count).
final todaySnapshotProvider = FutureProvider<TodaySnapshot>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) {
    return const TodaySnapshot(totalUsd: 0, count: 0);
  }
  return ref.watch(dashboardServiceProvider).getTodaysSales(business.id);
});

/// This month's total revenue.
final monthRevenueProvider = FutureProvider<double>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  return ref.watch(dashboardServiceProvider).getMonthRevenue(business.id);
});

/// Total recurring monthly expenses.
final recurringExpensesProvider = FutureProvider<double>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  return ref
      .watch(dashboardServiceProvider)
      .getRecurringExpensesTotal(business.id);
});

/// Total one-off expenses this calendar month.
final oneOffExpensesProvider = FutureProvider<double>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  return ref
      .watch(dashboardServiceProvider)
      .getOneOffExpensesThisMonth(business.id);
});

/// Best seller product this calendar month.
final bestSellerProvider = FutureProvider<BestSellerSnapshot?>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return null;
  return ref
      .watch(dashboardServiceProvider)
      .getBestSellerThisMonth(business.id);
});

/// Inventory snapshot computed from product list.
final inventorySnapshotProvider =
    Provider<({double totalValue, int lowStockCount})>((ref) {
  final productsAsync = ref.watch(productListProvider);
  return productsAsync.when(
    data: (products) {
      final totalValue = products.fold<double>(
        0.0,
        (sum, p) => sum + (p.quantity * p.costPriceUsd),
      );
      final lowStockCount = products.where((p) => p.isLowStock).length;
      return (totalValue: totalValue, lowStockCount: lowStockCount);
    },
    loading: () => (totalValue: 0.0, lowStockCount: 0),
    error: (_, _) => (totalValue: 0.0, lowStockCount: 0),
  );
});

/// Selected date range for custom dashboard filter (null = no range selected).
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Range snapshot: only fetches when a date range is selected.
final rangeSnapshotProvider = FutureProvider<RangeSnapshot?>((ref) async {
  final range = ref.watch(selectedDateRangeProvider);
  if (range == null) return null;

  final business = ref.watch(currentBusinessProvider);
  if (business == null) return null;

  return ref.watch(dashboardServiceProvider).getRangeSnapshot(
        businessId: business.id,
        from: range.start,
        to: range.end,
      );
});
