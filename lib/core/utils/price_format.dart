/// Formats a rupee amount with thousands separators, e.g. 132500 -> "1,32,500"
/// (Indian digit grouping: last 3 digits, then groups of 2). Hand-rolled
/// rather than pulling in `intl` for one formatting rule.
String formatRupees(double amount) {
  final whole = amount.round().toString();
  if (whole.length <= 3) return '₹$whole';

  final lastThree = whole.substring(whole.length - 3);
  var remaining = whole.substring(0, whole.length - 3);
  final groups = <String>[];
  while (remaining.length > 2) {
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) groups.insert(0, remaining);
  return '₹${groups.join(',')},$lastThree';
}

/// Like [formatRupees], but keeps the paise when there are some: 42.86 -> "₹42.86", 900 -> "₹900". For bills, where
/// a rate or a tax amount is exact.
String formatRupeesExact(double amount) {
  final cents = (amount.abs() * 100).round();
  final sign = amount < 0 && cents > 0 ? '-' : '';
  final whole = formatRupees((cents ~/ 100).toDouble());
  final paise = cents % 100;
  return paise == 0 ? '$sign$whole' : '$sign$whole.${paise.toString().padLeft(2, '0')}';
}
