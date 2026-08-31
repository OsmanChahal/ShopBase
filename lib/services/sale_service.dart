import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';

class SaleService {
  final SupabaseClient _client;

  SaleService(this._client);

  /// Create a new sale with its line items.
  /// Returns the created Sale (without items attached — caller knows the items).
  Future<Sale> createSale({
    required String businessId,
    required double totalUsd,
    required double totalLbp,
    required double exchangeRate,
    required String paymentType,
    required List<Map<String, dynamic>> itemsJson,
    String? customerId,
  }) async {
    try {
      // 1. Insert the sale row
      final saleResponse = await _client
          .from('sales')
          .insert({
            'business_id': businessId,
            'customer_id': customerId,
            'total_usd': totalUsd,
            'total_lbp': totalLbp,
            'exchange_rate_used': exchangeRate,
            'payment_type': paymentType,
          })
          .select()
          .single();

      final sale = Sale.fromJson(saleResponse);

      // 2. Insert all sale_items rows
      final itemsWithSaleId = itemsJson.map((item) {
        return {
          ...item,
          'sale_id': sale.id,
        };
      }).toList();

      await _client.from('sale_items').insert(itemsWithSaleId);

      return sale;
    } catch (e) {
      throw Exception('Failed to create sale. Please try again.');
    }
  }

  /// Fetch all sales for a business, most recent first.
  Future<List<Sale>> getSales(String businessId) async {
    try {
      final response = await _client
          .from('sales')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales history. Please try again.');
    }
  }

  /// Fetch the line items for a specific sale.
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    try {
      final response = await _client
          .from('sale_items')
          .select()
          .eq('sale_id', saleId);

      return (response as List)
          .map((json) => SaleItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sale details. Please try again.');
    }
  }
}
