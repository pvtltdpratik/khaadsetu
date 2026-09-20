import '../../domain/entities/smart_recommendation.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/recommendation_api_data_source.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  const RecommendationRepositoryImpl(this._dataSource);

  final RecommendationApiDataSource _dataSource;

  @override
  Future<SmartRecommendation> getSmartRecommendation() =>
      _dataSource.fetchSmartRecommendation();
}
