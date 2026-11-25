// Display formatters shared by screens and widgets.
//
// These replaced per-screen copies. Changing output here changes what users
// see on several screens, so update the tests in test/utils/ deliberately.

const List<String> _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Full LBP amount with comma thousands separators, no decimals
/// (e.g. `1500000` → `"1,500,000"`, `-123456` → `"-123,456"`).
///
/// Rounds like [double.toStringAsFixed]. Values that round to zero are shown
/// as `"0"`, never `"-0"`.
String formatLbpFull(double amount) {
  final rounded = amount.toStringAsFixed(0);
  if (rounded == '-0') return '0';
  if (rounded.startsWith('-')) return '-${_groupThousands(rounded.substring(1))}';
  return _groupThousands(rounded);
}

/// Inserts a comma every three digits from the right in a digits-only string.
String _groupThousands(String digits) {
  final str = digits;
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
    count++;
  }
  return buffer.toString().split('').reversed.join();
}

/// Compact LBP amount: `"1.5M"`, `"250K"`, or the plain number below 1,000.
///
/// Amounts that would round up to `"1000K"` are shown as `"1.0M"` instead,
/// and negatives get a leading minus (`-250000` → `"-250K"`).
String formatLbpCompact(double amount) {
  if (amount < 0) {
    final abs = formatLbpCompact(-amount);
    return abs == '0' ? '0' : '-$abs';
  }
  if (amount >= 1000000 || (amount / 1000).round() >= 1000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }
  return amount.toStringAsFixed(0);
}

/// LBP amount rounded with [double.round] and comma thousands separators.
///
/// Used by the POS product grid. Unlike [formatLbpFull] it handles negatives
/// correctly, but it throws on NaN/infinity and rounds .5 away from zero.
String formatLbpRounded(double amount) => amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

/// USD amount with two decimals and a leading minus for negatives
/// (e.g. `-12.5` → `"-$12.50"`).
String formatSignedUsd(double amount) =>
    '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}';

/// 12-hour clock time, e.g. `"9:05 AM"`, `"12:30 PM"`, `"12:00 AM"`.
String formatTime12h(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final amPm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '$hour:$min $amPm';
}

/// Three-letter English month name for a 1-based [month] (1 → `"Jan"`).
String monthAbbr(int month) => _monthAbbreviations[month - 1];

/// Date as `"5 Mar 2026"`, as shown on receipts.
String formatDateDayMonYear(DateTime dt) =>
    '${dt.day} ${monthAbbr(dt.month)} ${dt.year}';

/// Display label for a sale's payment type. Anything other than `'cash'`
/// is shown as `"Card"`.
String paymentTypeLabel(String paymentType) =>
    paymentType == 'cash' ? 'Cash' : 'Card';
