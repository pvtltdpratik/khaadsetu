import '../../../../../core/network/api_client.dart';
import '../../domain/entities/smart_recommendation.dart';

/// The server picks the recommendation from this device's latest soil scan.
class RecommendationApiDataSource {
  const RecommendationApiDataSource(this._api);

  final ApiClient _api;

  Future<SmartRecommendation> fetchSmartRecommendation() async {
    final json = await _api.get('/v1/farmer/recommendation') as Map<String, dynamic>;
    return SmartRecommendation(
      category: RecommendationCategory.values.byName(json['category'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      actionLabel: json['actionLabel'] as String,
    );
  }
}
