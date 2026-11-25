import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_database.dart';
import 'local_customer_repository.dart';
import 'local_product_repository.dart';
import 'local_sale_repository.dart';
import '../sync/remote_mappers.dart';
import '../sync/supabase_paging.dart';

/// One-time initial pull from Supabase into the local SQLite database.
///
/// On first run for an existing business, fetches all products, customers,
/// sales, and sale_items from Supabase and populates the local tables.
/// Only runs once — checks if local data already exists before pulling.
class InitialPullService {
  final SupabaseClient _supabase;
  final LocalProductRepository _productRepo;
  final LocalCustomerRepository _customerRepo;
  final LocalSaleRepository _saleRepo;

  InitialPullService({
    required SupabaseClient supabase,
    required LocalProductRepository productRepo,
    required LocalCustomerRepository customerRepo,
    required LocalSaleRepository saleRepo,
  }) : _supabase = supabase,
       _productRepo = productRepo,
       _customerRepo = customerRepo,
       _saleRepo = saleRepo;

  /// Check if the initial pull is needed and perform it if so.
  /// Returns true if a pull was performed, false if it was skipped.
  Future<bool> pullIfNeeded(String businessId) async {
    // If local products already exist for this business, skip
    final hasData = await _productRepo.hasProducts(businessId);
    if (hasData) return false;

    await _pullAll(businessId);
    return true;
  }

  Future<void> _pullAll(String businessId) async {
    final now = DateTime.now().toUtc();

    // 1. Pull products
    final productsResponse = await fetchAllPages(
      () => _supabase.from('products').select().eq('business_id', businessId),
      ['id'],
    );

    final productCompanions = productsResponse
        .map((j) => productFromRemote(j, syncedAt: now))
        .toList();

    if (productCompanions.isNotEmpty) {
      await _productRepo.bulkInsertProducts(productCompanions);
    }

    // 2. Pull customers
    final customersResponse = await fetchAllPages(
      () => _supabase.from('customers').select().eq('business_id', businessId),
      ['id'],
    );

    final customerCompanions = customersResponse
        .map((j) => customerFromRemote(j, syncedAt: now))
        .toList();

    if (customerCompanions.isNotEmpty) {
      await _customerRepo.bulkInsertCustomers(customerCompanions);
    }

    // 3. Pull sales
    final salesList = await fetchAllPages(
      () => _supabase.from('sales').select().eq('business_id', businessId),
      ['id'],
    );
    if (salesList.isNotEmpty) {
      final saleCompanions = salesList.map(saleFromRemote).toList();

      await _saleRepo.bulkInsertSales(saleCompanions);

      // 4. Pull sale items for all sales
      final saleIds = salesList.map((j) => j['id'] as String).toList();

      // Fetch in batches to avoid URL length limits
      final allItemCompanions = <LocalSaleItemsCompanion>[];
      for (var i = 0; i < saleIds.length; i += 50) {
        final batchIds = saleIds.sublist(
          i,
          i + 50 > saleIds.length ? saleIds.length : i + 50,
        );
        final itemsResponse = await fetchAllPages(
          () => _supabase.from('sale_items').select().inFilter(
            'sale_id',
            batchIds,
          ),
          ['id'],
        );

        allItemCompanions.addAll(itemsResponse.map(saleItemFromRemote));
      }

      if (allItemCompanions.isNotEmpty) {
        await _saleRepo.bulkInsertSaleItems(allItemCompanions);
      }
    }
  }
}
