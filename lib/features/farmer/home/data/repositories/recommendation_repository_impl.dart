import '../../domain/entities/smart_recommendation.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/recommendation_fake_data_source.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  const RecommendationRepositoryImpl(this._dataSource);

  final RecommendationFakeDataSource _dataSource;

  @override
  Future<SmartRecommendation> getSmartRecommendation() =>
      _dataSource.fetchSmartRecommendation();
}
