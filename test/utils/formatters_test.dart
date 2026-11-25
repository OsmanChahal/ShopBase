import 'package:crm_pos/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

// Verbatim copies of the screen-local helpers that formatters.dart replaced.
// The parity tests prove the shared versions behave identically.

String legacyLbpFull(double amount) {
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

String legacyLbpShort(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }
  return amount.toStringAsFixed(0);
}

String legacyPosLbp(double v) => v.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

String legacyTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ap = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:${dt.minute.toString().padLeft(2, '0')} $ap';
}

const amounts = <double>[
  0, 0.4, 0.5, 1, 1.5, 2.5, 12, 999, 999.5, 1000, 1499, 1500, 12345, 123456,
  999499, 999500, 999999, 1000000, 1049999, 1050000, 89500, 8950000,
  123456789.5, -0.4, -1, -12, -999, -1000, -12345, -123456, -1234567,
];

void main() {
  group('formatLbpFull', () {
    test('matches the legacy screen implementation for non-negative amounts',
        () {
      for (final a in amounts.where((a) => a >= 0)) {
        expect(formatLbpFull(a), legacyLbpFull(a), reason: 'amount $a');
      }
    });

    test('formats typical values', () {
      expect(formatLbpFull(0), '0');
      expect(formatLbpFull(999), '999');
      expect(formatLbpFull(1000), '1,000');
      expect(formatLbpFull(8950000), '8,950,000');
    });

    test('formats negatives without a stray separator (bug fix)', () {
      expect(legacyLbpFull(-123456), '-,123,456'); // the old bug
      expect(formatLbpFull(-123456), '-123,456');
      expect(formatLbpFull(-1234567), '-1,234,567');
      expect(formatLbpFull(-12345), '-12,345');
      expect(formatLbpFull(-999), '-999');
    });

    test('never shows negative zero', () {
      expect(formatLbpFull(-0.4), '0');
      expect(formatLbpFull(-1), '-1');
    });
  });

  group('formatLbpCompact', () {
    test('matches the legacy implementation except the fixed cases', () {
      for (final a in amounts.where((a) => a >= 0 && (a < 999500 || a >= 1e6))) {
        expect(formatLbpCompact(a), legacyLbpShort(a), reason: 'amount $a');
      }
    });

    test('formats K/M', () {
      expect(formatLbpCompact(950), '950');
      expect(formatLbpCompact(250000), '250K');
      expect(formatLbpCompact(1500000), '1.5M');
    });

    test('shows 1.0M instead of 1000K (bug fix)', () {
      expect(legacyLbpShort(999999), '1000K'); // the old bug
      expect(formatLbpCompact(999999), '1.0M');
      expect(formatLbpCompact(999500), '1.0M');
      expect(formatLbpCompact(999499), '999K');
    });

    test('negatives get a leading minus', () {
      expect(formatLbpCompact(-250000), '-250K');
      expect(formatLbpCompact(-1500000), '-1.5M');
      expect(formatLbpCompact(-12), '-12');
      expect(formatLbpCompact(-0.4), '0');
    });
  });

  group('formatLbpRounded', () {
    test('matches the legacy POS implementation for all sample amounts', () {
      for (final a in amounts) {
        expect(formatLbpRounded(a), legacyPosLbp(a), reason: 'amount $a');
      }
    });

    test('rounds half away from zero and handles negatives', () {
      expect(formatLbpRounded(2.5), '3');
      expect(formatLbpRounded(-123456), '-123,456');
    });
  });

  group('formatSignedUsd', () {
    test('formats positive, zero and negative values', () {
      expect(formatSignedUsd(12.5), '\$12.50');
      expect(formatSignedUsd(0), '\$0.00');
      expect(formatSignedUsd(-12.5), '-\$12.50');
    });

    test('matches the dashboard inline expression', () {
      for (final x in amounts) {
        final legacy = '${x < 0 ? '-' : ''}\$${x.abs().toStringAsFixed(2)}';
        expect(formatSignedUsd(x), legacy, reason: 'amount $x');
      }
    });
  });

  group('formatTime12h', () {
    test('matches the legacy implementation for every hour and some minutes',
        () {
      for (var h = 0; h < 24; h++) {
        for (final m in [0, 5, 30, 59]) {
          final dt = DateTime(2026, 1, 1, h, m);
          expect(formatTime12h(dt), legacyTime(dt), reason: '$h:$m');
        }
      }
    });

    test('handles midnight and noon', () {
      expect(formatTime12h(DateTime(2026, 1, 1, 0, 0)), '12:00 AM');
      expect(formatTime12h(DateTime(2026, 1, 1, 12, 30)), '12:30 PM');
      expect(formatTime12h(DateTime(2026, 1, 1, 9, 5)), '9:05 AM');
    });
  });

  test('monthAbbr maps 1..12', () {
    expect(
      [for (var m = 1; m <= 12; m++) monthAbbr(m)],
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    );
  });

  test('paymentTypeLabel', () {
    expect(paymentTypeLabel('cash'), 'Cash');
    expect(paymentTypeLabel('card'), 'Card');
    expect(paymentTypeLabel('credit'), 'Card');
  });
}
