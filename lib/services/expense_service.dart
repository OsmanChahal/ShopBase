import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  final SupabaseClient _client;

  ExpenseService(this._client);

  /// Fetch all expenses for a business, most recent first.
  Future<List<Expense>> getExpenses(String businessId) async {
    try {
      final response = await _client
          .from('expenses')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expenses. Please try again.');
    }
  }

  /// Insert a new expense. Returns the created expense.
  Future<Expense> addExpense(Expense expense) async {
    try {
      final response = await _client
          .from('expenses')
          .insert(expense.toJson())
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add expense. Please try again.');
    }
  }

  /// Update an existing expense. Returns the updated expense.
  Future<Expense> updateExpense(Expense expense) async {
    try {
      final response = await _client
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id!)
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense. Please try again.');
    }
  }

  /// Delete an expense by ID.
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _client.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense. Please try again.');
    }
  }
}
