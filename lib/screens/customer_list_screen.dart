import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../providers/crm_overview_provider.dart';
import '../providers/customer_provider.dart';
import '../services/crm_analytics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/customer_list_tile.dart';
import '../widgets/floating_action_pill.dart';
import '../widgets/metric_card.dart';
import '../widgets/offline_scope_boundary.dart';
import '../widgets/stat_badge.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import '../utils/chart_buckets.dart';
import '../utils/formatters.dart';
import '../utils/error_text.dart';
import '../constants/permissions.dart';

part 'customer_list/overview_section.dart';
part 'customer_list/overview_charts.dart';
part 'customer_list/customer_list_section.dart';

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
  /// 0 = Overview, 1 = Customers
  int _selectedSection = 0;
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

  void _invalidateOverview() {
    ref.invalidate(crmRevenueOverTimeProvider);
    ref.invalidate(crmTopSellingProductsProvider);
    ref.invalidate(crmAverageOrderValueProvider);
    ref.invalidate(crmOrdersOverTimeProvider);
    ref.invalidate(crmNewCustomersOverTimeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final canViewOverview = ref.watch(hasPermissionProvider(Permissions.viewCrmOverview));
    final showOverview = canViewOverview && _selectedSection == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              if (showOverview) {
                _invalidateOverview();
              } else {
                ref.invalidate(customerListProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Segmented control ───
          if (canViewOverview)
            _SectionSwitcher(
              selectedIndex: _selectedSection,
              onChanged: (i) => setState(() => _selectedSection = i),
            ),

          // ─── Section body ───
          Expanded(
            child: showOverview
                ? const OfflineScopeBoundary(child: _OverviewSection())
                : _CustomerListSection(
                    searchController: _searchController,
                    onAdd: _navigateToAdd,
                    onTapCustomer: _navigateToDetail,
                  ),
          ),
        ],
      ),
      // Only show the FAB on the Customers list section
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: !showOverview
          ? FloatingActionPill(
              icon: Icons.person_add_rounded,
              onPressed: _navigateToAdd,
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEGMENTED CONTROL
// ═══════════════════════════════════════════════════════════════════

class _SectionSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SectionSwitcher({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _tab('Overview', 0),
            _tab('Customers', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
