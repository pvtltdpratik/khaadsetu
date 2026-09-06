import 'package:equatable/equatable.dart';

enum ProblemType { pest, disease, nutrientDeficiency, weather, market, general }

/// A community forum post. [crop] and [district] are plain tags (no
/// classification logic attached, unlike [ProblemType]) used purely for
/// filtering and display.
class ForumPost extends Equatable {
  const ForumPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.body,
    required this.crop,
    required this.district,
    required this.problemType,
    required this.createdAt,
    required this.replyCount,
    required this.likeCount,
  });

  final String id;
  final String authorName;
  final String title;
  final String body;
  final String crop;
  final String district;
  final ProblemType problemType;
  final DateTime createdAt;
  final int replyCount;
  final int likeCount;

  @override
  List<Object?> get props => [
        id,
        authorName,
        title,
        body,
        crop,
        district,
        problemType,
        createdAt,
        replyCount,
        likeCount,
      ];
}
