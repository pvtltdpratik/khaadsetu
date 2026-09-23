import '../../domain/entities/community_post.dart';
import '../../domain/entities/post_comment.dart';
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

  @override
  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String cropTag,
    required String districtTag,
    required ProblemType problemTypeTag,
  }) {
    return _dataSource.createPost(
      title: title,
      content: content,
      cropTag: cropTag,
      districtTag: districtTag,
      problemTypeTag: problemTypeTag,
    );
  }

  @override
  Future<PostDetail> getPostDetail(String postId) => _dataSource.fetchPostDetail(postId);

  @override
  Future<PostComment> addComment(String postId, String content) => _dataSource.postComment(postId, content);

  @override
  Future<({bool liked, int likeCount})> toggleLike(String postId) => _dataSource.toggleLike(postId);
}
