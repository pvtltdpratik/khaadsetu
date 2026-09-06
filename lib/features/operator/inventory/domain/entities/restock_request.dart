import 'package:equatable/equatable.dart';

enum RestockRequestStatus { pending, approved, fulfilled }

class RestockRequest extends Equatable {
  const RestockRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.requestedQuantity,
    required this.status,
    required this.requestedDate,
  });

  final String id;
  final String itemId;
  final String itemName;
  final int requestedQuantity;
  final RestockRequestStatus status;
  final DateTime requestedDate;

  @override
  List<Object?> get props =>
      [id, itemId, itemName, requestedQuantity, status, requestedDate];
}
