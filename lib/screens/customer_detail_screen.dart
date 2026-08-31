import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import 'customer_form_screen.dart';
import 'receipt_screen.dart';

/// Provider to fetch a single customer's data.
final _customerDetailProvider =
    FutureProvider.family<Customer, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerById(customerId);
});

/// Provider to fetch monthly sales count.
final _customerMonthlySalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerSalesThisMonth(customerId);
});

/// Provider to fetch total sales count.
final _customerTotalSalesProvider =
    FutureProvider.family<int, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getCustomerTotalSales(customerId);
});

/// Provider to fetch favorite product.
final _customerFavoriteProductProvider =
    FutureProvider.family<FavoriteProduct?, String>((ref, customerId) async {
  return ref
      .watch(customerServiceProvider)
      .getCustomerFavoriteProduct(customerId);
});

/// Provider to fetch sales for a customer.
final _customerSalesProvider =
    FutureProvider.family<List<Sale>, String>((ref, customerId) async {
  return ref.watch(customerServiceProvider).getSalesForCustomer(customerId);
});

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(_customerDetailProvider(customerId));
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(_customerDetailProvider(customerId));
              ref.invalidate(_customerMonthlySalesProvider(customerId));
              ref.invalidate(_customerTotalSalesProvider(customerId));
              ref.invalidate(_customerFavoriteProductProvider(customerId));
              ref.invalidate(_customerSalesProvider(customerId));
            },
          ),
        ],
      ),
      body: customerAsync.when(
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
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(_customerDetailProvider(customerId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (customer) => _CustomerDetailBody(
          customer: customer,
          customerId: customerId,
          currencyRate: rate,
        ),
      ),
    );
  }
}

class _CustomerDetailBody extends ConsumerWidget {
  final Customer customer;
  final String customerId;
  final double currencyRate;

  const _CustomerDetailBody({
    required this.customer,
    required this.customerId,
    required this.currencyRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthlyCountAsync =
        ref.watch(_customerMonthlySalesProvider(customerId));
    final totalCountAsync = ref.watch(_customerTotalSalesProvider(customerId));
    final favoriteProductAsync =
        ref.watch(_customerFavoriteProductProvider(customerId));
    final salesAsync = ref.watch(_customerSalesProvider(customerId));
    final initial = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  customer.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CustomerFormScreen(customer: customer),
                        ),
                      );
                      if (changed == true) {
                        ref.invalidate(_customerDetailProvider(customerId));
                        ref.invalidate(customerListProvider);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Orders Stats Row
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'This Month',
                  icon: Icons.calendar_today_rounded,
                  child: monthlyCountAsync.when(
                    data: (count) => Text(
                      '$count orders',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const Text('0'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  title: 'All-Time Orders',
                  icon: Icons.shopping_bag_outlined,
                  child: totalCountAsync.when(
                    data: (count) => Text(
                      '$count total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emeraldGreen,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const Text('0'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Favorite Product Card
          MetricCard(
            title: 'Favorite Product',
            icon: Icons.star_rounded,
            child: favoriteProductAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Text('Could not load favorite product'),
              data: (favorite) {
                if (favorite == null) {
                  return const Row(
                    children: [
                      Icon(Icons.star_outline_rounded,
                          color: AppColors.inactiveGray),
                      SizedBox(width: 10),
                      Text(
                        'No orders recorded yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrangeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.warningOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${favorite.totalQuantity} units bought in total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 4. Order History
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ORDER HISTORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),

          salesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Failed to load order history: $err'),
            ),
            data: (sales) {
              if (sales.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 40, color: AppColors.inactiveGray),
                        SizedBox(height: 8),
                        Text(
                          'No past orders found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final local = sale.createdAt.toLocal();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${local.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.primaryPurple,
                                height: 1,
                              ),
                            ),
                            Text(
                              _monthAbbr(local.month),
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        '\$${sale.totalUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatTime(local)} · ${sale.paymentType == 'cash' ? 'Cash' : 'Card'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currencyRate > 0)
                            Text(
                              'LBP ${_formatLbp(sale.totalLbp)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          final items = await ref
                              .read(saleServiceProvider)
                              .getSaleItems(sale.id);
                          final saleWithItems = sale.copyWith(items: items);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // pop loader
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  sale: saleWithItems,
                                  isFromCheckout: false,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ap';
  }

  String _formatLbp(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}
