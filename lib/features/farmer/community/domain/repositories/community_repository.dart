import '../entities/community_post.dart';

abstract class CommunityRepository {
  /// Newest first. All filters are optional and AND together; `q` searches
  /// title/content. `limit`/`offset` page through the server's results.
  Future<List<CommunityPost>> getPosts({
    String? crop,
    String? district,
    ProblemType? problemType,
    String? q,
    int limit,
    int offset,
  });
}
