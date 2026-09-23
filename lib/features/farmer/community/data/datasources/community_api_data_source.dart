import '../../../../../core/network/api_client.dart';
import '../../domain/entities/community_post.dart';

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
