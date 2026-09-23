import '../entities/community_post.dart';
import '../entities/post_comment.dart';

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

  Future<PostDetail> getPostDetail(String postId);

  Future<PostComment> addComment(String postId, String content);

  /// The server toggles: returns the new state and the authoritative count.
  Future<({bool liked, int likeCount})> toggleLike(String postId);
}
