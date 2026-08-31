import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/customer_list_tile.dart';
import '../widgets/floating_action_pill.dart';
import '../widgets/stat_badge.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

/// Family provider to fetch monthly order count for a customer list row.
final _customerMonthlyOrderCountProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerSalesThisMonth(customerId);
});

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(customerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
  }

  void _navigateToDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customer.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomersAsync = ref.watch(filteredCustomerListProvider);
    final totalCustomersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(customerListProvider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search by name or phone...',
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).state = val;
              },
              onClear: () {
                ref.read(customerSearchQueryProvider.notifier).state = '';
              },
            ),
          ),

          // Total customer count subtitle
          totalCustomersAsync.when(
            data: (allCustomers) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                '${allCustomers.length} total customer${allCustomers.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Customer list
          Expanded(
            child: filteredCustomersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 56, color: AppColors.statusError),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load customers',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(customerListProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  final query = ref.watch(customerSearchQueryProvider);
                  if (query.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 56, color: AppColors.inactiveGray),
                          const SizedBox(height: 12),
                          Text(
                            'No customers match "$query"',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 72,
                            color: AppColors.primaryPurple.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No customers yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap + to add your first customer',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(customerListProvider);
                    await ref.read(customerListProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _CustomerRowItem(
                        customer: customer,
                        onTap: () => _navigateToDetail(customer),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionPill(
        icon: Icons.person_add_rounded,
        onPressed: _navigateToAdd,
      ),
    );
  }
}

class _CustomerRowItem extends ConsumerWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerRowItem({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderCountAsync =
        ref.watch(_customerMonthlyOrderCountProvider(customer.id));

    final badge = orderCountAsync.when(
      data: (count) => StatBadge.purple(
        label: '$count order${count == 1 ? '' : 's'}',
        icon: Icons.shopping_bag_outlined,
      ),
      loading: () => StatBadge.purple(label: '...'),
      error: (_, _) => null,
    );

    return CustomerListTile(
      customer: customer,
      trailingBadge: badge,
      onTap: onTap,
    );
  }
}
