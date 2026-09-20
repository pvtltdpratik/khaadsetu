import '../../../../../core/network/api_client.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_reply.dart';

class CommunityApiDataSource {
  const CommunityApiDataSource(this._api);

  final ApiClient _api;

  Future<List<ForumPost>> fetchPosts() async {
    final list = await _api.get('/v1/community/posts') as List;
    return list.map((e) => _parsePost(e as Map<String, dynamic>)).toList();
  }

  Future<ForumPost> fetchPostById(String id) async {
    return _parsePost(await _api.get('/v1/community/posts/$id') as Map<String, dynamic>);
  }

  Future<List<ForumReply>> fetchReplies(String postId) async {
    final list = await _api.get('/v1/community/posts/$postId/replies') as List;
    return list.map((e) => _parseReply(e as Map<String, dynamic>)).toList();
  }

  ForumPost _parsePost(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      crop: json['crop'] as String,
      district: json['district'] as String,
      problemType: ProblemType.values.byName(json['problemType'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      replyCount: (json['replyCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
    );
  }

  ForumReply _parseReply(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
