import 'package:crm_pos/models/customer.dart';
import 'package:crm_pos/providers/customer_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Customer customer(String name, [String? phone]) => Customer(
      id: name,
      businessId: 'b',
      name: name,
      phone: phone,
      createdAt: DateTime(2026),
    );

void main() {
  final rami = customer('Rami Haddad', '+96170123456');
  final noPhone = customer('Lina');

  test('matches names case-insensitively', () {
    expect(customerMatchesQuery(rami, 'rami'), isTrue);
    expect(customerMatchesQuery(rami, 'HADDAD'), isTrue);
    expect(customerMatchesQuery(rami, 'lina'), isFalse);
  });

  test('matches phone substrings (the POS picker used to ignore phones)', () {
    expect(customerMatchesQuery(rami, '70123'), isTrue);
    expect(customerMatchesQuery(rami, '+961'), isTrue);
    expect(customerMatchesQuery(noPhone, '70'), isFalse);
  });

  test('trims the query; empty matches everyone', () {
    expect(customerMatchesQuery(rami, '  rami  '), isTrue);
    expect(customerMatchesQuery(noPhone, ''), isTrue);
    expect(customerMatchesQuery(noPhone, '   '), isTrue);
  });
}
