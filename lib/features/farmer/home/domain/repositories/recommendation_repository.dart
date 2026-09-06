import '../entities/smart_recommendation.dart';

abstract class RecommendationRepository {
  Future<SmartRecommendation> getSmartRecommendation();
}
