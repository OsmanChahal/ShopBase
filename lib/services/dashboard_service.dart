import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';

/// Dashboard aggregate data classes.
class TodaySnapshot {
  final double totalUsd;
  final int count;
  const TodaySnapshot({required this.totalUsd, required this.count});
}

class BestSellerSnapshot {
  final String productName;
  final int totalQuantity;

  const BestSellerSnapshot({
    required this.productName,
    required this.totalQuantity,
  });
}

/// Snapshot for a custom date range.
class RangeSnapshot {
  final double revenueUsd;
  final int salesCount;
  final double expensesUsd;
  final List<Sale> sales;

  const RangeSnapshot({
    required this.revenueUsd,
    required this.salesCount,
    required this.expensesUsd,
    required this.sales,
  });

  double get capitalUsd => revenueUsd - expensesUsd;
}

class DashboardService {
  final SupabaseClient _client;

  DashboardService(this._client);

  /// Get today's sales snapshot: total USD and count.
  Future<TodaySnapshot> getTodaysSales(String businessId) async {
    try {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);

      final response = await _client
          .from('sales')
          .select('total_usd')
          .eq('business_id', businessId)
          .gte('created_at', todayStart.toIso8601String());

      final rows = response as List;
      final totalUsd = rows.fold<double>(
          0.0, (sum, row) => sum + (row['total_usd'] as num).toDouble());

      return TodaySnapshot(totalUsd: totalUsd, count: rows.length);
    } catch (e) {
      throw Exception('Failed to load today\'s sales.');
    }
  }

  /// Get this calendar month's total revenue.
  Future<double> getMonthRevenue(String businessId) async {
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);

      final response = await _client
          .from('sales')
          .select('total_usd')
          .eq('business_id', businessId)
          .gte('created_at', monthStart.toIso8601String());

      final rows = response as List;
      return rows.fold<double>(
          0.0, (sum, row) => sum + (row['total_usd'] as num).toDouble());
    } catch (e) {
      throw Exception('Failed to load month revenue.');
    }
  }

  /// Get total of recurring expenses (all time — these are monthly fixed costs).
  Future<double> getRecurringExpensesTotal(String businessId) async {
    try {
      final response = await _client
          .from('expenses')
          .select('amount_usd')
          .eq('business_id', businessId)
          .eq('is_recurring', true);

      final rows = response as List;
      return rows.fold<double>(
          0.0, (sum, row) => sum + (row['amount_usd'] as num).toDouble());
    } catch (e) {
      throw Exception('Failed to load recurring expenses.');
    }
  }

  /// Get total of one-off expenses created this calendar month.
  Future<double> getOneOffExpensesThisMonth(String businessId) async {
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);

      final response = await _client
          .from('expenses')
          .select('amount_usd')
          .eq('business_id', businessId)
          .eq('is_recurring', false)
          .gte('created_at', monthStart.toIso8601String());

      final rows = response as List;
      return rows.fold<double>(
          0.0, (sum, row) => sum + (row['amount_usd'] as num).toDouble());
    } catch (e) {
      throw Exception('Failed to load one-off expenses.');
    }
  }

  /// Get the best selling product this calendar month (highest total quantity sold).
  /// Returns null if no sales exist this month.
  Future<BestSellerSnapshot?> getBestSellerThisMonth(String businessId) async {
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);

      // Fetch all sales for this month
      final salesResponse = await _client
          .from('sales')
          .select('id')
          .eq('business_id', businessId)
          .gte('created_at', monthStart.toIso8601String());

      final sales = salesResponse as List;
      if (sales.isEmpty) return null;

      final saleIds = sales.map((s) => s['id'] as String).toList();

      // Fetch sale_items for these sales
      final itemsResponse = await _client
          .from('sale_items')
          .select('product_name_snapshot, quantity')
          .inFilter('sale_id', saleIds);

      final items = itemsResponse as List;
      if (items.isEmpty) return null;

      final totals = <String, int>{};
      for (final item in items) {
        final name = item['product_name_snapshot'] as String;
        final qty = item['quantity'] as int;
        totals[name] = (totals[name] ?? 0) + qty;
      }

      String? topName;
      int topQty = 0;
      for (final entry in totals.entries) {
        if (entry.value > topQty) {
          topName = entry.key;
          topQty = entry.value;
        }
      }

      if (topName == null) return null;

      return BestSellerSnapshot(productName: topName, totalQuantity: topQty);
    } catch (e) {
      throw Exception('Failed to load best seller.');
    }
  }

  /// Get a snapshot for a custom date range (inclusive of both dates).
  /// [from] is the start of the first day, [to] is the end of the last day.
  Future<RangeSnapshot> getRangeSnapshot({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // Ensure 'to' includes the full day by bumping to start of next day
      final fromUtc = DateTime.utc(from.year, from.month, from.day);
      final toUtc =
          DateTime.utc(to.year, to.month, to.day).add(const Duration(days: 1));

      final fromStr = fromUtc.toIso8601String();
      final toStr = toUtc.toIso8601String();

      // Fetch sales in range
      final salesResponse = await _client
          .from('sales')
          .select()
          .eq('business_id', businessId)
          .gte('created_at', fromStr)
          .lt('created_at', toStr)
          .order('created_at', ascending: false);

      final sales = (salesResponse as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();

      final revenueUsd = sales.fold<double>(
          0.0, (sum, s) => sum + s.totalUsd);
      final salesCount = sales.length;

      // Fetch expenses in range (both recurring and one-off)
      final expensesResponse = await _client
          .from('expenses')
          .select('amount_usd')
          .eq('business_id', businessId)
          .gte('created_at', fromStr)
          .lt('created_at', toStr);

      final expenseRows = expensesResponse as List;
      final expensesUsd = expenseRows.fold<double>(
          0.0, (sum, row) => sum + (row['amount_usd'] as num).toDouble());

      return RangeSnapshot(
        revenueUsd: revenueUsd,
        salesCount: salesCount,
        expensesUsd: expensesUsd,
        sales: sales,
      );
    } catch (e) {
      throw Exception('Failed to load data for selected range.');
    }
  }
}
