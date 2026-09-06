abstract class EarningsRepository {
  /// Commission rate as a percentage (e.g. 5.0 for 5%) — set by the
  /// platform, so this is the one piece of earnings data that would
  /// genuinely come from a backend. Everything else is derived from orders.
  Future<double> getCommissionRatePercent();
}
