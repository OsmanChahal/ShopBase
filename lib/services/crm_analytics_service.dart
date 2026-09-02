import 'package:supabase_flutter/supabase_flutter.dart';

/// A single date-value pair used for time-series charts.
class DateValue {
  final DateTime date;
  final double value;

  const DateValue({required this.date, required this.value});
}

/// A product name paired with its sold quantity (top-sellers chart).
class ProductQuantity {
  final String name;
  final int quantity;

  const ProductQuantity({required this.name, required this.quantity});
}

/// Service for CRM overview analytics.
///
/// All queries are scoped by `business_id` and a date range.
/// Uses the same `gte(from) + lt(to+1day)` inclusive-range pattern
/// established in [DashboardService].
class CrmAnalyticsService {
  final SupabaseClient _client;

  CrmAnalyticsService(this._client);

  // ───────────────────────── helpers ─────────────────────────

  /// Normalise from/to into UTC day boundaries: [fromUtc, toUtcExclusive).
  ({String fromStr, String toStr}) _rangeBounds(DateTime from, DateTime to) {
    final fromUtc = DateTime.utc(from.year, from.month, from.day);
    final toUtc =
        DateTime.utc(to.year, to.month, to.day).add(const Duration(days: 1));
    return (fromStr: fromUtc.toIso8601String(), toStr: toUtc.toIso8601String());
  }

  // ───────────────────── a) Revenue over time ─────────────────────

  /// Sum of `sales.total_usd` grouped by date within [from, to].
  Future<List<DateValue>> getRevenueOverTime({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bounds = _rangeBounds(from, to);

      final response = await _client
          .from('sales')
          .select('total_usd, created_at')
          .eq('business_id', businessId)
          .gte('created_at', bounds.fromStr)
          .lt('created_at', bounds.toStr)
          .order('created_at', ascending: true);

      final rows = response as List;

      // Group by date (day)
      final grouped = <DateTime, double>{};
      for (final row in rows) {
        final dt = DateTime.parse(row['created_at'] as String).toLocal();
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        grouped[dayKey] =
            (grouped[dayKey] ?? 0) + (row['total_usd'] as num).toDouble();
      }

      final result = grouped.entries
          .map((e) => DateValue(date: e.key, value: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return result;
    } catch (e) {
      throw Exception('Failed to load revenue data.');
    }
  }

  // ───────────────── b) Top-selling products (top 5) ─────────────────

  /// Top 5 products by total quantity sold within [from, to].
  Future<List<ProductQuantity>> getTopSellingProducts({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bounds = _rangeBounds(from, to);

      // 1. Get sale IDs in range
      final salesResponse = await _client
          .from('sales')
          .select('id')
          .eq('business_id', businessId)
          .gte('created_at', bounds.fromStr)
          .lt('created_at', bounds.toStr);

      final saleIds =
          (salesResponse as List).map((s) => s['id'] as String).toList();

      if (saleIds.isEmpty) return [];

      // 2. Get sale_items for those sales
      final itemsResponse = await _client
          .from('sale_items')
          .select('product_name_snapshot, quantity')
          .inFilter('sale_id', saleIds);

      final items = itemsResponse as List;
      if (items.isEmpty) return [];

      // 3. Aggregate by product name
      final totals = <String, int>{};
      for (final item in items) {
        final name = item['product_name_snapshot'] as String;
        final qty = item['quantity'] as int;
        totals[name] = (totals[name] ?? 0) + qty;
      }

      // 4. Sort descending and take top 5
      final sorted = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(5)
          .map((e) => ProductQuantity(name: e.key, quantity: e.value))
          .toList();
    } catch (e) {
      throw Exception('Failed to load top-selling products.');
    }
  }

  // ───────────────── c) Average order value ─────────────────

  /// Total revenue / number of sales in [from, to]. Returns 0 if no sales.
  Future<double> getAverageOrderValue({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bounds = _rangeBounds(from, to);

      final response = await _client
          .from('sales')
          .select('total_usd')
          .eq('business_id', businessId)
          .gte('created_at', bounds.fromStr)
          .lt('created_at', bounds.toStr);

      final rows = response as List;
      if (rows.isEmpty) return 0;

      final totalUsd = rows.fold<double>(
          0.0, (sum, row) => sum + (row['total_usd'] as num).toDouble());

      return totalUsd / rows.length;
    } catch (e) {
      throw Exception('Failed to load average order value.');
    }
  }

  // ───────────────── d) Orders over time ─────────────────

  /// Count of sales per day within [from, to].
  Future<List<DateValue>> getOrdersOverTime({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bounds = _rangeBounds(from, to);

      final response = await _client
          .from('sales')
          .select('created_at')
          .eq('business_id', businessId)
          .gte('created_at', bounds.fromStr)
          .lt('created_at', bounds.toStr)
          .order('created_at', ascending: true);

      final rows = response as List;

      final grouped = <DateTime, int>{};
      for (final row in rows) {
        final dt = DateTime.parse(row['created_at'] as String).toLocal();
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        grouped[dayKey] = (grouped[dayKey] ?? 0) + 1;
      }

      final result = grouped.entries
          .map((e) => DateValue(date: e.key, value: e.value.toDouble()))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return result;
    } catch (e) {
      throw Exception('Failed to load orders data.');
    }
  }

  // ───────────────── e) New customers over time ─────────────────

  /// Count of customers created per day within [from, to].
  Future<List<DateValue>> getNewCustomersOverTime({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final bounds = _rangeBounds(from, to);

      final response = await _client
          .from('customers')
          .select('created_at')
          .eq('business_id', businessId)
          .gte('created_at', bounds.fromStr)
          .lt('created_at', bounds.toStr)
          .order('created_at', ascending: true);

      final rows = response as List;

      final grouped = <DateTime, int>{};
      for (final row in rows) {
        final dt = DateTime.parse(row['created_at'] as String).toLocal();
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        grouped[dayKey] = (grouped[dayKey] ?? 0) + 1;
      }

      final result = grouped.entries
          .map((e) => DateValue(date: e.key, value: e.value.toDouble()))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return result;
    } catch (e) {
      throw Exception('Failed to load new customers data.');
    }
  }
}
