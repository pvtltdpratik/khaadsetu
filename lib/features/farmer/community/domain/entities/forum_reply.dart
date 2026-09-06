import 'package:equatable/equatable.dart';

class ForumReply extends Equatable {
  const ForumReply({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, authorName, body, createdAt];
}
