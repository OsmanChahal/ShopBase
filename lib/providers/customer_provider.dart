import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/local_customer_repository.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'auth_provider.dart';
import 'product_provider.dart'; // for syncQueueRepositoryProvider

/// Provides the CustomerService instance (still used by CRM screens).
final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(ref.watch(supabaseClientProvider));
});

/// Provides the LocalCustomerRepository instance.
final localCustomerRepositoryProvider =
    Provider<LocalCustomerRepository>((ref) {
  return LocalCustomerRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncQueueRepositoryProvider),
  );
});

/// Fetches the customer list for the current business from the local database.
final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return [];

  final repo = ref.watch(localCustomerRepositoryProvider);
  final localCustomers = await repo.getCustomers(business.id);

  return localCustomers.map(_localCustomerToModel).toList();
});

/// Shared search query state for customer search across Customers screen & POS customer picker.
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered customer list provider sharing search-as-you-type logic.
final filteredCustomerListProvider =
    Provider<AsyncValue<List<Customer>>>((ref) {
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

/// Helper class for customer actions that operate on the local database.
/// Used from POS checkout flow for adding new customers inline.
class CustomerActions {
  final Ref ref;

  CustomerActions(this.ref);

  LocalCustomerRepository get _repo =>
      ref.read(localCustomerRepositoryProvider);

  /// Add a new customer locally (used from POS inline customer creation).
  Future<Customer> addCustomer({
    required String businessId,
    required String name,
    String? phone,
  }) async {
    final result = await _repo.addCustomer(
      businessId: businessId,
      name: name,
      phone: phone,
    );
    ref.invalidate(customerListProvider);
    return _localCustomerToModel(result);
  }
}

/// Provider for customer actions.
final customerActionsProvider = Provider<CustomerActions>((ref) {
  return CustomerActions(ref);
});

/// Convert a drift LocalCustomer row into the app-level Customer model.
Customer _localCustomerToModel(LocalCustomer lc) {
  return Customer(
    id: lc.id,
    businessId: lc.businessId,
    name: lc.name,
    phone: lc.phone,
    createdAt: lc.createdAt,
  );
}
