import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/farmer_fake_data_source.dart';
import '../../data/datasources/recommendation_fake_data_source.dart';
import '../../data/repositories/farmer_repository_impl.dart';
import '../../data/repositories/recommendation_repository_impl.dart';
import '../../domain/entities/farmer_profile.dart';
import '../../domain/entities/smart_recommendation.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../../domain/repositories/recommendation_repository.dart';

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  return FarmerRepositoryImpl(FarmerFakeDataSource());
});

final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepositoryImpl(RecommendationFakeDataSource());
});

final farmerProfileProvider = FutureProvider.autoDispose<FarmerProfile>((ref) {
  return ref.watch(farmerRepositoryProvider).getProfile();
});

final smartRecommendationProvider =
    FutureProvider.autoDispose<SmartRecommendation>((ref) {
  return ref.watch(recommendationRepositoryProvider).getSmartRecommendation();
});
