import '../../../../../core/network/api_client.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/post_comment.dart';

class CommunityApiDataSource {
  const CommunityApiDataSource(this._api);

  final ApiClient _api;

  Future<List<CommunityPost>> fetchPosts({
    String? crop,
    String? district,
    ProblemType? problemType,
    String? q,
    required int limit,
    required int offset,
  }) async {
    final list = await _api.get('/v1/community/posts', query: {
      'crop': crop,
      'district': district,
      'problemType': problemType?.name,
      'q': q,
      'limit': '$limit',
      'offset': '$offset',
    }) as List;
    return list.map((e) => _parsePost(e as Map<String, dynamic>)).toList();
  }

  Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String cropTag,
    required String districtTag,
    required ProblemType problemTypeTag,
  }) async {
    final json = await _api.post('/v1/community/posts', body: {
      'title': title,
      'content': content,
      'cropTag': cropTag,
      'districtTag': districtTag,
      'problemTypeTag': problemTypeTag.name,
    });
    return _parsePost(json as Map<String, dynamic>);
  }

  Future<PostDetail> fetchPostDetail(String postId) async {
    final json = await _api.get('/v1/community/posts/$postId') as Map<String, dynamic>;
    return PostDetail(
      post: _parsePost(json),
      likedByMe: json['likedByMe'] as bool? ?? false,
      comments: (json['comments'] as List).map((e) => _parseComment(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<PostComment> postComment(String postId, String content) async {
    final json = await _api.post('/v1/community/posts/$postId/comments', body: {'content': content});
    return _parseComment(json as Map<String, dynamic>);
  }

  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    final json = await _api.post('/v1/community/posts/$postId/like') as Map<String, dynamic>;
    return (liked: json['liked'] as bool, likeCount: (json['likeCount'] as num).toInt());
  }

  PostComment _parseComment(Map<String, dynamic> json) {
    return PostComment(
      commentId: json['commentId'] as String,
      postId: json['postId'] as String,
      farmerName: json['farmerName'] as String,
      content: json['content'] as String,
      isAiGenerated: json['isAiGenerated'] as bool,
      isAgronomistVerified: json['isAgronomistVerified'] as bool,
      agronomistName: json['agronomistName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  CommunityPost _parsePost(Map<String, dynamic> json) {
    return CommunityPost(
      postId: json['postId'] as String,
      farmerId: json['farmerId'] as String,
      farmerName: json['farmerName'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      cropTag: json['cropTag'] as String,
      districtTag: json['districtTag'] as String,
      problemTypeTag: ProblemType.values.byName(json['problemTypeTag'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      commentCount: (json['commentCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
    );
  }
}
