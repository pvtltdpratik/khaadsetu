import 'package:equatable/equatable.dart';

import 'community_post.dart';

/// One answer/comment on a post. A comment is one of three kinds, decided by
/// the two flags: a plain farmer/expert reply, an AI draft still awaiting
/// review ([isAiGenerated] && !isAgronomistVerified), or an AI answer an
/// agronomist has reviewed and vouched for (both true, [agronomistName] set).
class PostComment extends Equatable {
  const PostComment({
    required this.commentId,
    required this.postId,
    required this.farmerName,
    required this.content,
    required this.isAiGenerated,
    required this.isAgronomistVerified,
    required this.agronomistName,
    required this.createdAt,
  });

  final String commentId;
  final String postId;
  final String farmerName;
  final String content;
  final bool isAiGenerated;
  final bool isAgronomistVerified;
  final String? agronomistName;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [commentId, postId, farmerName, content, isAiGenerated, isAgronomistVerified, agronomistName, createdAt];
}

/// A post plus everything the detail screen needs beyond the feed's card.
class PostDetail extends Equatable {
  const PostDetail({required this.post, required this.comments, required this.likedByMe});

  final CommunityPost post;
  final List<PostComment> comments;
  final bool likedByMe;

  @override
  List<Object?> get props => [post, comments, likedByMe];
}
