import '../../../../../core/network/api_client.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/entities/scheme_eligibility_result.dart';

/// The scheme directory and each device's applications live on the server.
/// Eligibility (land-holding cap, deadline) is enforced there again on apply,
/// so a rejected apply surfaces as an [ApiException] with a readable reason.
class SchemesApiDataSource {
  const SchemesApiDataSource(this._api);

  final ApiClient _api;

  Future<List<GovScheme>> fetchSchemes() async {
    // The whole catalog is small, so it is fetched in one go.
    final list = await _api.get('/v1/schemes', query: {'limit': '200'}) as List;
    return list.map((e) => _parseScheme(e as Map<String, dynamic>)).toList();
  }

  Future<GovScheme> fetchSchemeById(String id) async {
    return _parseScheme(await _api.get('/v1/schemes/$id') as Map<String, dynamic>);
  }

  Future<Map<String, SchemeEligibilityResult>> fetchEligibilitySummary() async {
    final list = await _api.get('/v1/schemes/eligibility') as List;
    return {for (final e in list) (e as Map<String, dynamic>)['schemeId'] as String: SchemeEligibilityResult.fromJson(e)};
  }

  Future<SchemeEligibilityResult> fetchEligibility(String id) async =>
      SchemeEligibilityResult.fromJson(await _api.get('/v1/schemes/$id/eligibility') as Map<String, dynamic>);

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
      level: json['level'] as String? ?? 'central',
      sector: json['sector'] as String? ?? 'General',
      audience: json['audience'] as String? ?? 'farmer',
      components: ((json['components'] as List?) ?? const [])
          .map((e) => SchemeComponent(title: (e as Map<String, dynamic>)['title'] as String, assistance: e['assistance'] as String))
          .toList(),
      howToApply: json['howToApply'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      website: json['website'] as String? ?? '',
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
