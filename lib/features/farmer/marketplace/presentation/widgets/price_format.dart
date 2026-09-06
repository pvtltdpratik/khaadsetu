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
