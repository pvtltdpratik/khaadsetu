import 'package:equatable/equatable.dart';

/// What kind of advice a [SmartRecommendation] is about. The presentation
/// layer maps this to an icon/color — kept out of the domain entity so this
/// layer stays Flutter-free.
enum RecommendationCategory { nutrient, water, pest, harvest }

/// The single most relevant thing the app wants to surface to the farmer
/// right now — the hero card on the home screen. A real backend would derive
/// this from the latest soil scan, weather, and crop calendar; here it's a
/// fixed mock standing in for that logic.
class SmartRecommendation extends Equatable {
  const SmartRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final RecommendationCategory category;
  final String title;
  final String description;
  final String actionLabel;

  @override
  List<Object?> get props => [category, title, description, actionLabel];
}
