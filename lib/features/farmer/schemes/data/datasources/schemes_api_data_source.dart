import '../../../../../core/network/api_client.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';

/// The scheme directory and each device's applications live on the server.
/// Eligibility (land-holding cap, deadline) is enforced there again on apply,
/// so a rejected apply surfaces as an [ApiException] with a readable reason.
class SchemesApiDataSource {
  const SchemesApiDataSource(this._api);

  final ApiClient _api;

  Future<List<GovScheme>> fetchSchemes() async {
    final list = await _api.get('/v1/schemes') as List;
    return list.map((e) => _parseScheme(e as Map<String, dynamic>)).toList();
  }

  Future<GovScheme> fetchSchemeById(String id) async {
    return _parseScheme(await _api.get('/v1/schemes/$id') as Map<String, dynamic>);
  }

  Future<SchemeApplication> fetchApplicationStatus(String schemeId) async {
    return _parseApplication(await _api.get('/v1/schemes/$schemeId/application') as Map<String, dynamic>);
  }

  Future<SchemeApplication> applyToScheme(String schemeId) async {
    return _parseApplication(await _api.post('/v1/schemes/$schemeId/apply') as Map<String, dynamic>);
  }

  GovScheme _parseScheme(Map<String, dynamic> json) {
    final deadline = json['applicationDeadline'] as String?;
    return GovScheme(
      id: json['id'] as String,
      name: json['name'] as String,
      agency: json['agency'] as String,
      category: SchemeCategory.values.byName(json['category'] as String),
      description: json['description'] as String,
      benefit: json['benefit'] as String,
      eligibilityCriteria: (json['eligibilityCriteria'] as List).cast<String>(),
      maxLandHoldingHectares: (json['maxLandHoldingHectares'] as num?)?.toDouble(),
      applicationDeadline: deadline == null ? null : DateTime.parse(deadline).toLocal(),
    );
  }

  SchemeApplication _parseApplication(Map<String, dynamic> json) {
    final applied = json['appliedDate'] as String?;
    return SchemeApplication(
      schemeId: json['schemeId'] as String,
      status: ApplicationStatus.values.byName(json['status'] as String),
      appliedDate: applied == null ? null : DateTime.parse(applied).toLocal(),
    );
  }
}
