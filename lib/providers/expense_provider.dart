import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';

/// Provides the ExpenseService instance.
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(ref.watch(supabaseClientProvider));
});

/// Fetches the expense list for the current business.
final expenseListProvider = FutureProvider<List<Expense>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ref.watch(expenseServiceProvider).getExpenses(business.id);
});

/// Helper class for expense actions that need to invalidate the list.
class ExpenseActions {
  final Ref ref;

  ExpenseActions(this.ref);

  ExpenseService get _service => ref.read(expenseServiceProvider);

  Future<Expense> addExpense(Expense expense) async {
    final result = await _service.addExpense(expense);
    ref.invalidate(expenseListProvider);
    return result;
  }

  Future<Expense> updateExpense(Expense expense) async {
    final result = await _service.updateExpense(expense);
    ref.invalidate(expenseListProvider);
    return result;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _service.deleteExpense(expenseId);
    ref.invalidate(expenseListProvider);
  }
}

/// Provider for expense actions.
final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref);
});
