import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/repositories/schemes_repository.dart';
import '../datasources/schemes_local_data_source.dart';

class SchemesRepositoryImpl implements SchemesRepository {
  const SchemesRepositoryImpl(this._dataSource);

  final SchemesLocalDataSource _dataSource;

  @override
  Future<List<GovScheme>> getSchemes() => _dataSource.fetchSchemes();

  @override
  Future<GovScheme> getSchemeById(String id) => _dataSource.fetchSchemeById(id);

  @override
  Future<SchemeApplication> getApplicationStatus(String schemeId) =>
      _dataSource.fetchApplicationStatus(schemeId);

  @override
  Future<SchemeApplication> applyToScheme(String schemeId) => _dataSource.applyToScheme(schemeId);
}
