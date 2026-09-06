import 'package:equatable/equatable.dart';

class ProductReview extends Equatable {
  const ProductReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String id;
  final String authorName;

  /// 1-5.
  final int rating;
  final String comment;
  final DateTime date;

  @override
  List<Object?> get props => [id, authorName, rating, comment, date];
}
