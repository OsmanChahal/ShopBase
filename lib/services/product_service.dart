import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client;

  ProductService(this._client);

  /// Fetch all products for a business, sorted alphabetically by name.
  Future<List<Product>> getProducts(String businessId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products. Please try again.');
    }
  }

  /// Insert a new product. Returns the created product.
  Future<Product> addProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add product. Please try again.');
    }
  }

  /// Update an existing product. Returns the updated product.
  Future<Product> updateProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id!)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product. Please try again.');
    }
  }

  /// Delete a product by ID.
  Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product. Please try again.');
    }
  }

  /// Adjust stock quantity by a delta (positive to add, negative to subtract).
  /// Uses a read-then-write pattern — safe for single-user pilot.
  Future<Product> adjustStock(String productId, int delta) async {
    try {
      // Read current quantity
      final current = await _client
          .from('products')
          .select('quantity')
          .eq('id', productId)
          .single();

      final currentQty = current['quantity'] as int;
      final newQty = currentQty + delta;

      if (newQty < 0) {
        throw Exception('Stock cannot go below zero.');
      }

      // Update quantity and updated_at
      final response = await _client
          .from('products')
          .update({
            'quantity': newQty,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', productId)
          .select()
          .single();

      return Product.fromJson(response);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Failed to adjust stock. Please try again.');
    }
  }
}
