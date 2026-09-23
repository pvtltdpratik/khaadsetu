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

  /// Returns the created post. Throws on validation/network failure.
  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String cropTag,
    required String districtTag,
    required ProblemType problemTypeTag,
  });

  Future<PostDetail> getPostDetail(String postId);

  Future<PostComment> addComment(String postId, String content);

  /// The server toggles: returns the new state and the authoritative count.
  Future<({bool liked, int likeCount})> toggleLike(String postId);
}
