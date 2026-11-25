import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

/// Mirrors the IntlPhoneField setup in CustomerFormScreen, to pin down the
/// package behavior the form relies on.
Widget phoneField({
  required String? storedPhone,
  required ValueChanged<String?> onSaved,
}) {
  return MaterialApp(
    home: Scaffold(
      body: IntlPhoneField(
        initialCountryCode:
            (storedPhone?.startsWith('+') ?? false) ? null : 'LB',
        initialValue: storedPhone,
        onChanged: (phone) => onSaved(
          phone.number.trim().isEmpty ? null : phone.completeNumber,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the stored number when editing a customer',
      (tester) async {
    await tester.pumpWidget(
        phoneField(storedPhone: '+96170123456', onSaved: (_) {}));
    expect(find.text('70123456'), findsOneWidget);
    expect(find.text('+961'), findsOneWidget); // country dial code
  });

  testWidgets('clearing the field saves no phone instead of "+961"',
      (tester) async {
    String? saved = 'unchanged';
    await tester.pumpWidget(phoneField(
      storedPhone: '+96170123456',
      onSaved: (v) => saved = v,
    ));
    await tester.enterText(find.byType(TextFormField), '');
    expect(saved, isNull);

    await tester.enterText(find.byType(TextFormField), '71234567');
    expect(saved, '+96171234567');
  });

  testWidgets('a new customer defaults to Lebanon', (tester) async {
    String? saved;
    await tester.pumpWidget(
        phoneField(storedPhone: null, onSaved: (v) => saved = v));
    await tester.enterText(find.byType(TextFormField), '3123456');
    expect(saved, '+9613123456');
  });
}
