import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/farmer_api_data_source.dart';
import '../../data/datasources/recommendation_api_data_source.dart';
import '../../data/repositories/farmer_repository_impl.dart';
import '../../data/repositories/recommendation_repository_impl.dart';
import '../../domain/entities/farmer_profile.dart';
import '../../domain/entities/smart_recommendation.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../../domain/repositories/recommendation_repository.dart';

final farmerRepositoryProvider = Provider<FarmerRepository>((ref) {
  return FarmerRepositoryImpl(FarmerApiDataSource(ref.watch(apiClientProvider)));
});

final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepositoryImpl(RecommendationApiDataSource(ref.watch(apiClientProvider)));
});

final farmerProfileProvider = FutureProvider.autoDispose<FarmerProfile>((ref) {
  return ref.watch(farmerRepositoryProvider).getProfile();
});

final smartRecommendationProvider =
    FutureProvider.autoDispose<SmartRecommendation>((ref) {
  return ref.watch(recommendationRepositoryProvider).getSmartRecommendation();
});
