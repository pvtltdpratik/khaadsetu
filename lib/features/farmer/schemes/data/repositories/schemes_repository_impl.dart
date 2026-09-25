import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/entities/scheme_eligibility_result.dart';
import '../../domain/repositories/schemes_repository.dart';
import '../datasources/schemes_api_data_source.dart';

class SchemesRepositoryImpl implements SchemesRepository {
  const SchemesRepositoryImpl(this._dataSource);

  final SchemesApiDataSource _dataSource;

  @override
  Future<List<GovScheme>> getSchemes() => _dataSource.fetchSchemes();

  @override
  Future<GovScheme> getSchemeById(String id) => _dataSource.fetchSchemeById(id);

  @override
  Future<SchemeApplication> getApplicationStatus(String schemeId) =>
      _dataSource.fetchApplicationStatus(schemeId);

  @override
  Future<SchemeApplication> applyToScheme(String schemeId) => _dataSource.applyToScheme(schemeId);

  @override
  Future<Map<String, SchemeEligibilityResult>> eligibilitySummary() => _dataSource.fetchEligibilitySummary();

  @override
  Future<SchemeEligibilityResult> eligibility(String schemeId) => _dataSource.fetchEligibility(schemeId);
}
