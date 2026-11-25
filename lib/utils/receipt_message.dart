import '../models/sale.dart';
import 'formatters.dart';

/// Plain-text receipt sent over WhatsApp after checkout.
///
/// Times are shown in the device's local time zone. Items come from
/// [Sale.items]; a sale without loaded items produces a receipt with no lines.
String buildReceiptMessage({
  required Sale sale,
  required String businessName,
}) {
  final items = sale.items ?? [];
  final localTime = sale.createdAt.toLocal();

  final dateStr = formatDateDayMonYear(localTime);
  final timeStr = formatTime12h(localTime);
  final paymentLabel = paymentTypeLabel(sale.paymentType);

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
      '💵 *Total: \$${sale.totalUsd.toStringAsFixed(2)}*  (LBP ${formatLbpFull(sale.totalLbp)})');
  buffer.writeln('💳 Payment: $paymentLabel');
  buffer.writeln();
  buffer.write('Thank you for your purchase! 🙏');

  return buffer.toString();
}
