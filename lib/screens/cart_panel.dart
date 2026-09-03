import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../widgets/loading_overlay.dart';
import 'customer_form_screen.dart';
import 'receipt_screen.dart';

class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  bool _isCheckingOut = false;

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    final paymentType = ref.read(paymentTypeProvider);
    final customerId = ref.read(selectedCustomerIdProvider);
    final customerName = ref.read(selectedCustomerNameProvider);

    // Validate customer for credit sales
    if (paymentType == 'credit' && (customerId == null || customerId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a customer for credit sales'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isCheckingOut = true);

    try {
      final sale = await ref.read(saleActionsProvider).checkout(
            cartItems: cart,
            exchangeRate: business.currencyRate,
            paymentType: paymentType,
            businessId: business.id,
            customerId: customerId,
          );

      // Clear cart on success
      ref.read(cartProvider.notifier).clear();
      ref.read(paymentTypeProvider.notifier).state = 'cash';
      ref.read(selectedCustomerIdProvider.notifier).state = null;
      ref.read(selectedCustomerNameProvider.notifier).state = null;

      if (!mounted) return;

      // Resolve customer phone for the share button on the receipt screen.
      // Only look it up if a customer was actually connected.
      String? customerPhone;
      if (customerId != null && customerId.isNotEmpty) {
        try {
          final customers = ref.read(customerListProvider).valueOrNull ?? [];
          final match = customers.where((c) => c.id == customerId).firstOrNull;
          customerPhone =
              (match?.phone != null && match!.phone!.isNotEmpty)
                  ? match.phone
                  : null;
        } catch (_) {
          customerPhone = null;
        }
      }

      _goToReceipt(
        sale: sale,
        businessName: business.name,
        customerName: customerName,
        customerPhone: customerPhone,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _goToReceipt({
    required Sale sale,
    required String businessName,
    String? customerName,
    String? customerPhone,
  }) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          sale: sale,
          isFromCheckout: true,
          businessName: businessName,
          customerName: customerName,
          customerPhone: customerPhone,
        ),
      ),
    );
  }

  void _showPriceOverrideDialog(CartItem item) {
    final controller = TextEditingController(
      text: item.effectivePrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Price — ${item.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original price: \$${item.unitPriceUsd.toStringAsFixed(2)}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              Text(
                'Cost price: \$${item.costPriceUsd.toStringAsFixed(2)}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'New price (USD)',
                  prefixText: '\$ ',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset to original price
                ref
                    .read(cartProvider.notifier)
                    .setOverridePrice(item.productId, null);
                Navigator.of(ctx).pop();
              },
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null && val >= 0) {
                  ref
                      .read(cartProvider.notifier)
                      .setOverridePrice(item.productId, val);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final totalUsd = ref.watch(cartTotalUsdProvider);
    final totalLbp = ref.watch(cartTotalLbpProvider);
    final currencyDisplay = ref.watch(currencyDisplayProvider);
    final paymentType = ref.watch(paymentTypeProvider);
    final business = ref.watch(currentBusinessProvider);
    final rate = business?.currencyRate ?? 0;

    return LoadingOverlay(
      isLoading: _isCheckingOut,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          actions: [
            if (cart.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  ref.read(cartProvider.notifier).clear();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                label: const Text('Clear',
                    style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
        body: cart.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 72,
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap products on the POS screen to add them',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return _CartItemRow(
                          item: item,
                          currencyRate: rate,
                          onIncrement: () {
                            try {
                              ref
                                  .read(cartProvider.notifier)
                                  .incrementQuantity(item.productId);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', '')),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                          onDecrement: () {
                            ref
                                .read(cartProvider.notifier)
                                .decrementQuantity(item.productId);
                          },
                          onRemove: () {
                            ref
                                .read(cartProvider.notifier)
                                .removeFromCart(item.productId);
                          },
                          onEditPrice: () =>
                              _showPriceOverrideDialog(item),
                        );
                      },
                    ),
                  ),

                  // Bottom checkout section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Currency toggle
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'USD',
                              label: Text('USD'),
                              icon: Icon(Icons.attach_money, size: 18),
                            ),
                            ButtonSegment(
                              value: 'LBP',
                              label: Text('LBP'),
                              icon: Icon(Icons.currency_exchange, size: 18),
                            ),
                          ],
                          selected: {currencyDisplay},
                          onSelectionChanged: (val) {
                            ref.read(currencyDisplayProvider.notifier).state =
                                val.first;
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            selectedForegroundColor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Totals
                        _TotalRow(
                          label: 'Total (USD)',
                          value: '\$${totalUsd.toStringAsFixed(2)}',
                          isPrimary: currencyDisplay == 'USD',
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        _TotalRow(
                          label: 'Total (LBP)',
                          value: 'LBP ${_formatLbpFull(totalLbp)}',
                          isPrimary: currencyDisplay == 'LBP',
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Rate: ${rate.toStringAsFixed(0)} LBP/USD',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Payment type
                        Row(
                          children: [
                            Text(
                              'Payment:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'cash',
                                    label: Text('Cash'),
                                    icon: Icon(Icons.payments_outlined,
                                        size: 18),
                                  ),
                                  ButtonSegment(
                                    value: 'card',
                                    label: Text('Card'),
                                    icon: Icon(Icons.credit_card, size: 18),
                                  ),
                                ],
                                selected: {paymentType},
                                onSelectionChanged: (val) {
                                  ref
                                      .read(paymentTypeProvider.notifier)
                                      .state = val.first;
                                },
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor:
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                  selectedForegroundColor:
                                      theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Connect with Customer section (Always visible, optional)
                        const SizedBox(height: 12),
                        _CustomerPickerSection(ref: ref, theme: theme),

                        const SizedBox(height: 16),

                        // Checkout button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: cart.isEmpty || _isCheckingOut
                                ? null
                                : _checkout,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isCheckingOut ? 'Processing...' : 'Checkout',
                              style: const TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatLbpFull(double amount) {
    // Format with thousand separators
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}

/// A single cart item row.
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final double currencyRate;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onEditPrice;

  const _CartItemRow({
    required this.item,
    required this.currencyRate,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onEditPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBelowCost = item.isBelowCost;

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBelowCost
              ? const Color(0xFFFEE2E2)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isBelowCost
              ? Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5))
              : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Below-cost warning
            if (isBelowCost)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Price below cost (\$${item.costPriceUsd.toStringAsFixed(2)})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Product name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: onEditPrice,
                        child: Row(
                          children: [
                            if (item.hasDiscount) ...[
                              Text(
                                '\$${item.unitPriceUsd.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '\$${item.effectivePrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isBelowCost
                                    ? theme.colorScheme.error
                                    : item.hasDiscount
                                        ? const Color(0xFF16A34A)
                                        : null,
                                fontWeight: item.hasDiscount
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QtyButton(
                        icon: item.quantity == 1
                            ? Icons.delete_outline
                            : Icons.remove,
                        onTap: onDecrement,
                        color: item.quantity == 1
                            ? theme.colorScheme.error
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: onIncrement,
                      ),
                    ],
                  ),
                ),

                // Subtotal
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Text(
                    '\$${item.subtotalUsd.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small icon button for +/- quantity.
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// A row displaying a total label and value.
class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;
  final ThemeData theme;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.isPrimary,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isPrimary
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
        ),
        Text(
          value,
          style: isPrimary
              ? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
        ),
      ],
    );
  }
}

/// Connect with Customer section for POS sales.
class _CustomerPickerSection extends ConsumerWidget {
  final WidgetRef ref;
  final ThemeData theme;

  const _CustomerPickerSection({required this.ref, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedName = ref.watch(selectedCustomerNameProvider);
    final selectedId = ref.watch(selectedCustomerIdProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedId != null
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                'Connect with Customer (Optional)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedId != null && selectedName != null)
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(selectedName),
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        selectedName.isNotEmpty
                            ? selectedName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      ref.read(selectedCustomerIdProvider.notifier).state =
                          null;
                      ref.read(selectedCustomerNameProvider.notifier).state =
                          null;
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => _showCustomerPicker(context, ref),
                  child: const Text('Change'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCustomerPicker(context, ref),
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('Connect Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomerPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CustomerSearchSheet(
          ref: ref,
          onSelect: (customer) {
            ref.read(selectedCustomerIdProvider.notifier).state = customer.id;
            ref.read(selectedCustomerNameProvider.notifier).state =
                customer.name;
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }
}

/// Bottom sheet for searching and selecting a customer, with an inline "Add New Customer" button.
class _CustomerSearchSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final void Function(Customer) onSelect;

  const _CustomerSearchSheet({
    required this.ref,
    required this.onSelect,
  });

  @override
  ConsumerState<_CustomerSearchSheet> createState() =>
      _CustomerSearchSheetState();
}

class _CustomerSearchSheetState
    extends ConsumerState<_CustomerSearchSheet> {
  String _query = '';

  Future<void> _addNewCustomer(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );

    if (changed == true && mounted) {
      // Invalidate customer list to get fresh list
      ref.invalidate(customerListProvider);
      final customers = await ref.read(customerListProvider.future);
      if (customers.isNotEmpty && mounted) {
        // Automatically select the newest customer (most recently added)
        final newest = customers.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
        widget.onSelect(newest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customerListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Customer',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addNewCustomer(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                onChanged: (val) => setState(() => _query = val),
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: customersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Failed to load customers: $err'),
                  ),
                  data: (customers) {
                    final filtered = _query.isEmpty
                        ? customers
                        : customers
                            .where((c) => c.name
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No customers found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _addNewCustomer(context),
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Create New Customer'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: c.phone != null && c.phone!.isNotEmpty
                              ? Text(c.phone!)
                              : null,
                          onTap: () => widget.onSelect(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
