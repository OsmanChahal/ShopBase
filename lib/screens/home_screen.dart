import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/initial_pull_service.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../sync/sync_provider.dart';
import 'customer_list_screen.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'product_list_screen.dart';
import 'settings_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0; // Start on Dashboard tab
  bool _isPulling = true;
  String? _pullError;

  @override
  void initState() {
    super.initState();
    // Trigger initial pull on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitialPull());
  }

  Future<void> _runInitialPull() async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      setState(() => _isPulling = false);
      return;
    }

    try {
      final pullService = InitialPullService(
        supabase: ref.read(supabaseClientProvider),
        productRepo: ref.read(localProductRepositoryProvider),
        customerRepo: ref.read(localCustomerRepositoryProvider),
        saleRepo: ref.read(localSaleRepositoryProvider),
      );

      final didPull = await pullService.pullIfNeeded(business.id);

      if (didPull) {
        // Refresh providers so UI picks up the pulled data
        ref.invalidate(productListProvider);
        ref.invalidate(customerListProvider);
        ref.invalidate(salesListProvider);
      }

      if (mounted) {
        setState(() {
          _isPulling = false;
          _pullError = null;
        });
      }

      // Start the sync orchestrator (connectivity listening + startup sync)
      await ref.read(syncOrchestratorProvider).initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPulling = false;
          _pullError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final canViewDashboard = ref.watch(hasPermissionProvider('view_dashboard'));
    final canUsePos = ref.watch(hasPermissionProvider('use_pos'));
    final canViewInventory = ref.watch(hasPermissionProvider('view_inventory'));
    final canManageCustomers = ref.watch(
      hasPermissionProvider('manage_customers'),
    );

    final List<Widget> availableScreens = [];
    final List<BottomNavigationBarItem> availableItems = [];

    if (canViewDashboard) {
      availableScreens.add(const DashboardScreen());
      availableItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      );
    }
    if (canUsePos) {
      availableScreens.add(const PosScreen());
      availableItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_outlined),
          activeIcon: Icon(Icons.point_of_sale),
          label: 'POS',
        ),
      );
    }
    if (canViewInventory) {
      availableScreens.add(const ProductListScreen());
      availableItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
      );
    }
    if (canManageCustomers) {
      availableScreens.add(const CustomerListScreen());
      availableItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Customers',
        ),
      );
    }

    int activeIndex = _currentIndex;
    if (activeIndex >= availableScreens.length) {
      activeIndex = 0;
    }

    // Show loading overlay during initial pull
    if (_isPulling) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Setting up local database...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error with retry if pull failed
    if (_pullError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to set up local database',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _pullError!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPulling = true;
                      _pullError = null;
                    });
                    _runInitialPull();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (availableScreens.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Permissions')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Your staff account has no active permissions assigned. Please ask your administrator to grant you access.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: _openSettings,
          tooltip: 'Settings',
          heroTag: 'settings',
          child: const Icon(Icons.settings, size: 20),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: activeIndex, children: availableScreens),
      bottomNavigationBar: availableItems.length > 1
          ? BottomNavigationBar(
              currentIndex: activeIndex,
              onTap: _onTabTapped,
              items: availableItems,
            )
          : null,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openSettings,
        tooltip: 'Settings',
        heroTag: 'settings',
        child: const Icon(Icons.settings, size: 20),
      ),
    );
  }
}
