import 'package:crm_pos/models/sale.dart';
import 'package:crm_pos/services/whatsapp_service.dart';
import 'package:crm_pos/utils/formatters.dart';
import 'package:crm_pos/utils/receipt_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verbatim copy of ReceiptScreen._buildReceiptMessage before extraction
/// (business-name lookup replaced by a parameter).
String legacyReceiptMessage(Sale sale, String businessName) {
  String formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  final items = sale.items ?? [];
  final localTime = sale.createdAt.toLocal();
  final dateStr = formatDate(localTime);
  final timeStr = formatTime12h(localTime);
  final paymentLabel = sale.paymentType == 'cash' ? 'Cash' : 'Card';

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

Sale sampleSale({List<SaleItem>? items, String paymentType = 'cash'}) => Sale(
      id: 's1',
      businessId: 'b1',
      totalUsd: 12.5,
      totalLbp: 1118750,
      exchangeRateUsed: 89500,
      paymentType: paymentType,
      createdAt: DateTime.utc(2026, 3, 5, 14, 7),
      items: items,
    );

const twoItems = [
  SaleItem(
    id: 'i1',
    saleId: 's1',
    productId: 'p1',
    productNameSnapshot: 'Coffee',
    quantity: 2,
    unitPriceUsd: 2.5,
    subtotalUsd: 5,
  ),
  SaleItem(
    id: 'i2',
    saleId: 's1',
    productId: 'p2',
    productNameSnapshot: 'Croissant',
    quantity: 3,
    unitPriceUsd: 2.5,
    subtotalUsd: 7.5,
  ),
];

void main() {
  group('buildReceiptMessage', () {
    test('matches the legacy screen implementation', () {
      for (final sale in [
        sampleSale(items: twoItems),
        sampleSale(items: twoItems, paymentType: 'card'),
        sampleSale(items: const []),
        sampleSale(),
      ]) {
        expect(
          buildReceiptMessage(sale: sale, businessName: 'Shop'),
          legacyReceiptMessage(sale, 'Shop'),
        );
      }
    });

    test('contains the expected lines', () {
      final msg = buildReceiptMessage(
        sale: sampleSale(items: twoItems),
        businessName: 'Shop',
      );
      expect(msg, startsWith('🧾 *Receipt from Shop*'));
      expect(msg, contains('2 x Coffee  –  \$2.50  =  \$5.00'));
      expect(msg, contains('💵 *Total: \$12.50*  (LBP 1,118,750)'));
      expect(msg, contains('💳 Payment: Cash'));
      expect(msg, endsWith('Thank you for your purchase! 🙏'));
    });
  });

  test('formatDateDayMonYear', () {
    expect(formatDateDayMonYear(DateTime(2026, 3, 5)), '5 Mar 2026');
    expect(formatDateDayMonYear(DateTime(2026, 12, 31)), '31 Dec 2026');
  });

  group('buildWhatsAppUri', () {
    test('without text', () {
      expect(buildWhatsAppUri('96170123456').toString(),
          'https://wa.me/96170123456');
    });

    test('with text matches the legacy encode-then-parse construction', () {
      const text = 'Hi & welcome 🧾\n*Total*: \$5 = 100%';
      final legacy = Uri.parse(
          'https://wa.me/96170123456?text=${Uri.encodeComponent(text)}');
      expect(buildWhatsAppUri('96170123456', text: text), legacy);
      expect(buildWhatsAppUri('96170123456', text: text).toString(),
          legacy.toString());
    });
  });
}
