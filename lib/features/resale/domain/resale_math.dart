import 'resale_models.dart';

/// What a seller keeps of a sale, worked out the same way the server does it, so the form can show the
/// figure before anything is listed. The server's number is the one that counts when the sale happens.
class ResaleMath {
  const ResaleMath._();

  /// Platform 8% and center 3% on a verified purchase (the seller keeps 89%); 10% and 4% otherwise (86%).
  static ({double platformPct, double centerPct, double keepPct}) split({required bool verified}) =>
      verified ? (platformPct: 8, centerPct: 3, keepPct: 89) : (platformPct: 10, centerPct: 4, keepPct: 86);

  /// Taking the payout as cash at the center keeps 97% of the seller's share.
  static double cashKeep(PayoutMode mode) => mode == PayoutMode.cash ? 0.97 : 1.0;

  static double sellerNet({required double gross, required bool verified, required PayoutMode mode}) {
    final share = gross * split(verified: verified).keepPct / 100;
    return (share * cashKeep(mode) * 100).round() / 100;
  }

  /// "Save 22%" against the platform price.
  static int savingPercent({required double catalogPrice, required double price}) => catalogPrice <= 0 ? 0 : ((1 - price / catalogPrice) * 100).round();
}
