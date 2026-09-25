import '../entities/gov_scheme.dart';
import '../entities/scheme_application.dart';
import '../entities/scheme_eligibility_result.dart';

abstract class SchemesRepository {
  Future<List<GovScheme>> getSchemes();
  Future<GovScheme> getSchemeById(String id);
  Future<SchemeApplication> getApplicationStatus(String schemeId);
  Future<SchemeApplication> applyToScheme(String schemeId);

  /// How the farmer stands on every scheme, from the answers saved on their profile.
  Future<Map<String, SchemeEligibilityResult>> eligibilitySummary();

  /// The same for one scheme, with each rule spelled out.
  Future<SchemeEligibilityResult> eligibility(String schemeId);
}
