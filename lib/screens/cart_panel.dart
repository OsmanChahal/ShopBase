import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../models/tag.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/tag_provider.dart';
import '../sync/sync_provider.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/tag_picker_sheet.dart';
import 'receipt_screen.dart';
import '../utils/formatters.dart';
import '../utils/error_text.dart';

part 'cart_panel/cart_item_row.dart';
part 'cart_panel/customer_picker.dart';
part 'cart_panel/inline_customer_tags.dart';

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
            content: Text(errorText(e)),
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
    showDialog(
      context: context,
      builder: (_) => _PriceOverrideDialog(item: item),
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
                                  content: Text(errorText(e)),
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
                          value: 'LBP ${formatLbpFull(totalLbp)}',
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
                        _CustomerPickerSection(theme: theme),

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
}


/// Dialog for overriding a cart line's unit price. A widget (rather than an
/// inline builder) so the text controller is disposed with the dialog.
class _PriceOverrideDialog extends ConsumerStatefulWidget {
  final CartItem item;

  const _PriceOverrideDialog({required this.item});

  @override
  ConsumerState<_PriceOverrideDialog> createState() =>
      _PriceOverrideDialogState();
}

class _PriceOverrideDialogState extends ConsumerState<_PriceOverrideDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.item.effectivePrice.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final item = widget.item;
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
            controller: _controller,
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
            final val = double.tryParse(_controller.text);
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
  }
}
