import 'package:equatable/equatable.dart';

enum ProblemType { pest, disease, nutrientDeficiency, weather, market, general }

/// A community forum post. [cropTag] and [districtTag] are plain tags (no
/// classification logic attached, unlike [problemTypeTag]) used purely for
/// filtering and display. [commentCount]/[likeCount] are computed by the
/// server, not maintained client-side.
class CommunityPost extends Equatable {
  const CommunityPost({
    required this.postId,
    required this.farmerId,
    required this.farmerName,
    required this.title,
    required this.content,
    required this.cropTag,
    required this.districtTag,
    required this.problemTypeTag,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    required this.likeCount,
  });

  final String postId;
  final String farmerId;
  final String farmerName;
  final String title;
  final String content;
  final String cropTag;
  final String districtTag;
  final ProblemType problemTypeTag;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final int likeCount;

  CommunityPost copyWith({int? commentCount, int? likeCount}) => CommunityPost(
        postId: postId,
        farmerId: farmerId,
        farmerName: farmerName,
        title: title,
        content: content,
        cropTag: cropTag,
        districtTag: districtTag,
        problemTypeTag: problemTypeTag,
        createdAt: createdAt,
        updatedAt: updatedAt,
        commentCount: commentCount ?? this.commentCount,
        likeCount: likeCount ?? this.likeCount,
      );

  @override
  List<Object?> get props => [
        postId,
        farmerId,
        farmerName,
        title,
        content,
        cropTag,
        districtTag,
        problemTypeTag,
        createdAt,
        updatedAt,
        commentCount,
        likeCount,
      ];
}
