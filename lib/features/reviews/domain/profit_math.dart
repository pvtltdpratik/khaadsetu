/// The input-output calculator: what the fertilizer costs, what the extra yield is worth at the mandi, and what is
/// left. Farmers make money decisions as well as farming ones.
class ProfitResult {
  const ProfitResult({required this.cost, required this.extraQuintals, required this.extraRevenue, required this.net, required this.roiPercent, required this.breakEvenPercent});

  /// Total spent on the fertilizer.
  final double cost;

  /// Extra harvest, in quintals, over the whole farm.
  final double extraQuintals;
  final double extraRevenue;

  /// Extra revenue less the cost. Negative means it does not pay.
  final double net;

  /// Net as a percentage of the cost (null when nothing was spent).
  final double? roiPercent;

  /// The yield gain, in percent, at which it just pays for itself (null when it cannot be worked out).
  final double? breakEvenPercent;

  bool get pays => net > 0;
}

class ProfitMath {
  const ProfitMath._();

  /// [bagsPerAcre] of a product costing [pricePerBag], on [acres], expected to lift a [baselineQpa] (quintals per
  /// acre) yield by [gainPercent], sold at [pricePerQuintal].
  static ProfitResult calculate({
    required double acres,
    required double bagsPerAcre,
    required double pricePerBag,
    required double baselineQpa,
    required double gainPercent,
    required double pricePerQuintal,
  }) {
    final cost = acres * bagsPerAcre * pricePerBag;
    final extraQuintals = baselineQpa * acres * gainPercent / 100;
    final extraRevenue = extraQuintals * pricePerQuintal;
    final net = extraRevenue - cost;
    final revenuePerPercent = baselineQpa * acres * pricePerQuintal / 100;
    return ProfitResult(
      cost: cost,
      extraQuintals: extraQuintals,
      extraRevenue: extraRevenue,
      net: net,
      roiPercent: cost > 0 ? net / cost * 100 : null,
      breakEvenPercent: revenuePerPercent > 0 ? cost / revenuePerPercent : null,
    );
  }
}
