import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'auth_provider.dart';

/// Provides the CustomerService instance.
final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(ref.watch(supabaseClientProvider));
});

/// Fetches the customer list for the current business.
final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];
  return ref.watch(customerServiceProvider).getCustomers(business.id);
});

/// Shared search query state for customer search across Customers screen & POS customer picker.
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered customer list provider sharing search-as-you-type logic.
final filteredCustomerListProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(customerListProvider);
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();

  return customersAsync.whenData((customers) {
    if (query.isEmpty) return customers;
    return customers
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.phone != null && c.phone!.contains(query)))
        .toList();
  });
});

/// Helper class for customer actions that need to invalidate the list.
class CustomerActions {
  final Ref ref;

  CustomerActions(this.ref);

  CustomerService get _service => ref.read(customerServiceProvider);

  Future<Customer> addCustomer(Customer customer) async {
    final result = await _service.addCustomer(customer);
    ref.invalidate(customerListProvider);
    return result;
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final result = await _service.updateCustomer(customer);
    ref.invalidate(customerListProvider);
    return result;
  }

  Future<void> deleteCustomer(String customerId) async {
    await _service.deleteCustomer(customerId);
    ref.invalidate(customerListProvider);
  }
}

/// Provider for customer actions.
final customerActionsProvider = Provider<CustomerActions>((ref) {
  return CustomerActions(ref);
});
