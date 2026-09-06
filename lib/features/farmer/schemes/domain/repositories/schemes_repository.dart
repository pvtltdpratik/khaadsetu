import '../entities/gov_scheme.dart';
import '../entities/scheme_application.dart';

abstract class SchemesRepository {
  Future<List<GovScheme>> getSchemes();
  Future<GovScheme> getSchemeById(String id);
  Future<SchemeApplication> getApplicationStatus(String schemeId);
  Future<SchemeApplication> applyToScheme(String schemeId);
}
