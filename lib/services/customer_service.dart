import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../models/sale.dart';

/// Data class for a customer's favorite product.
class FavoriteProduct {
  final String productName;
  final int totalQuantity;

  const FavoriteProduct({
    required this.productName,
    required this.totalQuantity,
  });
}

class CustomerService {
  final SupabaseClient _client;

  CustomerService(this._client);

  /// Fetch all customers for a business, sorted alphabetically.
  Future<List<Customer>> getCustomers(String businessId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Customer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customers. Please try again.');
    }
  }

  /// Fetch a single customer by ID.
  Future<Customer> getCustomerById(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load customer. Please try again.');
    }
  }

  /// Insert a new customer. Returns the created customer.
  Future<Customer> addCustomer(Customer customer) async {
    try {
      final response = await _client
          .from('customers')
          .insert(customer.toJson())
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add customer. Please try again.');
    }
  }

  /// Update an existing customer (name/phone only). Returns the updated customer.
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response = await _client
          .from('customers')
          .update({
            'name': customer.name,
            'phone': customer.phone,
          })
          .eq('id', customer.id)
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update customer. Please try again.');
    }
  }

  /// Delete a customer by ID.
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _client.from('customers').delete().eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to delete customer. Please try again.');
    }
  }

  /// Fetch sales for a specific customer, most recent first.
  Future<List<Sale>> getSalesForCustomer(String customerId) async {
    try {
      final response = await _client
          .from('sales')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customer sales. Please try again.');
    }
  }

  /// Count of sales for a customer this calendar month.
  Future<int> getCustomerSalesThisMonth(String customerId) async {
    try {
      final now = DateTime.now().toUtc();
      final monthStart = DateTime.utc(now.year, now.month, 1);

      final response = await _client
          .from('sales')
          .select('id')
          .eq('customer_id', customerId)
          .gte('created_at', monthStart.toIso8601String());

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to load monthly sales count.');
    }
  }

  /// Total count of all sales linked to a customer (all-time).
  Future<int> getCustomerTotalSales(String customerId) async {
    try {
      final response = await _client
          .from('sales')
          .select('id')
          .eq('customer_id', customerId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to load total sales count.');
    }
  }

  /// Get the customer's favorite product (highest total quantity purchased).
  /// Returns null if the customer has no orders.
  Future<FavoriteProduct?> getCustomerFavoriteProduct(
      String customerId) async {
    try {
      // Get all sale IDs for this customer
      final salesResponse = await _client
          .from('sales')
          .select('id')
          .eq('customer_id', customerId);

      final saleIds = (salesResponse as List)
          .map((row) => row['id'] as String)
          .toList();

      if (saleIds.isEmpty) return null;

      // Get all sale items for those sales
      final itemsResponse = await _client
          .from('sale_items')
          .select('product_name_snapshot, quantity')
          .inFilter('sale_id', saleIds);

      final items = itemsResponse as List;
      if (items.isEmpty) return null;

      // Aggregate by product name
      final totals = <String, int>{};
      for (final item in items) {
        final name = item['product_name_snapshot'] as String;
        final qty = item['quantity'] as int;
        totals[name] = (totals[name] ?? 0) + qty;
      }

      // Find the top product
      String? topName;
      int topQty = 0;
      for (final entry in totals.entries) {
        if (entry.value > topQty) {
          topName = entry.key;
          topQty = entry.value;
        }
      }

      if (topName == null) return null;

      return FavoriteProduct(productName: topName, totalQuantity: topQty);
    } catch (e) {
      throw Exception('Failed to load favorite product.');
    }
  }

  /// Get the last order date for a customer.
  Future<DateTime?> getCustomerLastOrderDate(String customerId) async {
    try {
      final response = await _client
          .from('sales')
          .select('created_at')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(1);

      final rows = response as List;
      if (rows.isEmpty) return null;
      return DateTime.parse(rows.first['created_at'] as String);
    } catch (e) {
      return null;
    }
  }
}
