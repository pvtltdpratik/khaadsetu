import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_api_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl(this._dataSource);

  final CommunityApiDataSource _dataSource;

  @override
  Future<List<CommunityPost>> getPosts({
    String? crop,
    String? district,
    ProblemType? problemType,
    String? q,
    int limit = 20,
    int offset = 0,
  }) {
    return _dataSource.fetchPosts(
      crop: crop,
      district: district,
      problemType: problemType,
      q: q,
      limit: limit,
      offset: offset,
    );
  }
}
