import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/customer.dart';
import '../models/tag.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_detail_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/tag_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import '../widgets/offline_scope_boundary.dart';
import '../widgets/tag_picker_sheet.dart';
import 'customer_form_screen.dart';
import 'receipt_screen.dart';
import '../utils/formatters.dart';
import '../utils/phone.dart';
import '../services/whatsapp_service.dart';
import '../utils/error_text.dart';

part 'customer_detail/detail_body.dart';
part 'customer_detail/detail_widgets.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  HistoryPeriod _historyPeriod = HistoryPeriod.allTime;
  DateTimeRange? _customRange;

  CustomerSalesFilterKey get _filterKey =>
      customerSalesFilterKey(widget.customerId, _dateRange);

  DateTimeRange? get _dateRange =>
      historyPeriodRange(_historyPeriod, customRange: _customRange);

  void _invalidateAll() {
    ref.invalidate(customerDetailProvider(widget.customerId));
    ref.invalidate(customerMonthlySalesProvider(widget.customerId));
    ref.invalidate(customerTotalSalesProvider(widget.customerId));
    ref.invalidate(customerFavoriteProductProvider(widget.customerId));
    ref.invalidate(customerSalesFilteredProvider(_filterKey));
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _invalidateAll,
          ),
        ],
      ),
      body: OfflineScopeBoundary(
        child: customerAsync.when(
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
                  errorText(error),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(customerDetailProvider(widget.customerId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (customer) => _CustomerDetailBody(
          customer: customer,
          customerId: widget.customerId,
          currencyRate: rate,
          historyPeriod: _historyPeriod,
          customRange: _customRange,
          filterKey: _filterKey,
          onPeriodChanged: (period) async {
            if (period == HistoryPeriod.custom) {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: _customRange ??
                    DateTimeRange(
                      start:
                          DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    ),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _customRange = picked;
                  _historyPeriod = HistoryPeriod.custom;
                });
              }
            } else {
              setState(() => _historyPeriod = period);
            }
          },
          onCustomerEdited: () {
            ref.invalidate(customerDetailProvider(widget.customerId));
            ref.invalidate(customerListProvider);
          },
        ),
      ),
    ),
  );
}
}
