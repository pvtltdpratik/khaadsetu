import '../../../home/domain/entities/farmer_profile.dart';
import '../entities/gov_scheme.dart';

/// Real (if simple) eligibility logic — not a mock detail. Checks the
/// farmer's actual land holding against the scheme's cap, matching the
/// app's stated goal of matching schemes to a farmer's land details.
class SchemeEligibility {
  const SchemeEligibility._();

  static bool isEligible(FarmerProfile profile, GovScheme scheme) {
    final cap = scheme.maxLandHoldingHectares;
    if (cap == null) return true;
    return profile.landHoldingHectares <= cap;
  }
}
