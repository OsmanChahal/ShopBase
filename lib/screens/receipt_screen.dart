import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Sale sale;
  final bool isFromCheckout; // true = just completed, show "New Sale" button
  /// Business name — forwarded from checkout for the WhatsApp message header.
  final String? businessName;
  /// Only set from checkout. Controls share button visibility and message.
  final String? customerName;
  final String? customerPhone;

  const ReceiptScreen({
    super.key,
    required this.sale,
    this.isFromCheckout = false,
    this.businessName,
    this.customerName,
    this.customerPhone,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isOpening = false;

  /// Show the WhatsApp share button only when:
  /// - This is a fresh checkout (not viewing a historical receipt)
  /// - A customer was connected
  /// - That customer has a phone number on file
  bool get _showShareButton =>
      widget.isFromCheckout &&
      widget.customerPhone != null &&
      widget.customerPhone!.isNotEmpty;

  /// Strips all non-digit characters — produces the digits-only international
  /// number required by wa.me (e.g. "96170123456").
  String get _cleanedPhone =>
      (widget.customerPhone ?? '').replaceAll(RegExp(r'\D'), '');

  /// Builds the plain-text WhatsApp receipt message from the sale data.
  String _buildReceiptMessage() {
    final sale = widget.sale;
    final items = sale.items ?? [];
    final localTime = sale.createdAt.toLocal();
    final business = ref.read(currentBusinessProvider);
    final businessName =
        widget.businessName ?? business?.name ?? 'Our Store';

    final dateStr = _formatDate(localTime);
    final timeStr = _formatTime(localTime);
    final paymentLabel =
        sale.paymentType == 'cash' ? 'Cash' : 'Card';

    final buffer = StringBuffer();
    buffer.writeln('🧾 *Receipt from $businessName*');
    buffer.writeln();
    buffer.writeln('📅 $dateStr - $timeStr');
    buffer.writeln();

    for (final item in items) {
      final unitPrice = item.unitPriceUsd.toStringAsFixed(2);
      final lineTotal = item.subtotalUsd.toStringAsFixed(2);
      buffer.writeln(
          '${item.quantity} x ${item.productNameSnapshot}  –  \$$unitPrice  =  \$$lineTotal');
    }

    buffer.writeln();
    buffer.writeln(
        '💵 *Total: \$${sale.totalUsd.toStringAsFixed(2)}*  (LBP ${_formatLbp(sale.totalLbp)})');
    buffer.writeln('💳 Payment: $paymentLabel');
    buffer.writeln();
    buffer.write('Thank you for your purchase! 🙏');

    return buffer.toString();
  }

  Future<void> _openWhatsApp() async {
    final phone = _cleanedPhone;
    if (phone.isEmpty) return;

    setState(() => _isOpening = true);

    try {
      final message = _buildReceiptMessage();
      final encoded = Uri.encodeComponent(message);
      final uri = Uri.parse('https://wa.me/$phone?text=$encoded');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp — is it installed?'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp — is it installed?'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
    // After WhatsApp opens (or fails), owner stays on this screen.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final business = ref.watch(currentBusinessProvider);
    final items = widget.sale.items ?? [];
    final localTime = widget.sale.createdAt.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFromCheckout ? 'Sale Complete' : 'Receipt'),
        automaticallyImplyLeading: !widget.isFromCheckout,
        leading: widget.isFromCheckout
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success icon (only on fresh checkout)
            if (widget.isFromCheckout) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sale Completed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Receipt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Business name
                  Text(
                    business?.name ?? 'Business',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SALE RECEIPT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timestamp
                  Text(
                    '${_formatDate(localTime)} at ${_formatTime(localTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _DashedDivider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Column headers
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('Item',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            )),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('Qty',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            )),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text('Price',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            )),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text('Total',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Line items
                  ...items.map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productNameSnapshot,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '\$${item.unitPriceUsd.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '\$${item.subtotalUsd.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),
                  _DashedDivider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total (USD)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      Text(
                        '\$${widget.sale.totalUsd.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total (LBP)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          )),
                      Text(
                        'LBP ${_formatLbp(widget.sale.totalLbp)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _DashedDivider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Payment type + rate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.sale.paymentType == 'cash'
                                ? Icons.payments_outlined
                                : Icons.credit_card,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.sale.paymentType == 'cash'
                                ? 'Cash'
                                : 'Card',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rate: ${widget.sale.exchangeRateUsed.toStringAsFixed(0)} LBP/USD',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── WhatsApp Share button ──────────────────────────────────
            // Shown only when: fresh checkout + customer connected + has phone
            if (_showShareButton)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isOpening ? null : _openWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF25D366).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isOpening
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : SvgPicture.asset(
                          'asset/whatsapp-color-svgrepo-com.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                  label: Text(
                    _isOpening ? 'Opening WhatsApp…' : 'Share via WhatsApp',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            if (_showShareButton) const SizedBox(height: 8),

            // New Sale button (only from checkout)
            if (widget.isFromCheckout)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('New Sale',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour =
        dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
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

/// A simple dashed divider line.
class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
