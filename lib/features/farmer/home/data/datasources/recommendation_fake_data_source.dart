import '../../domain/entities/smart_recommendation.dart';

class RecommendationFakeDataSource {
  Future<SmartRecommendation> fetchSmartRecommendation() async {
    await Future.delayed(const Duration(milliseconds: 550));
    return const SmartRecommendation(
      category: RecommendationCategory.nutrient,
      title: 'Time to top-dress with Nitrogen',
      description: 'Your last soil scan showed low Nitrogen. Applying urea '
          'now, before the next watering, should improve your wheat yield.',
      actionLabel: 'View soil report',
    );
  }
}
