import 'package:equatable/equatable.dart';

class Farmer extends Equatable {
  const Farmer({
    required this.id,
    required this.name,
    required this.village,
    required this.phone,
    required this.activeCrop,
    required this.lastVisitDate,
    required this.needsFollowUp,
    required this.notes,
  });

  final String id;
  final String name;
  final String village;
  final String phone;
  final String activeCrop;
  final DateTime lastVisitDate;

  /// Explicitly flagged by the operator — not just derived from how long
  /// ago the last visit was, since a follow-up might be needed for reasons
  /// unrelated to timing (e.g. a pending question, a promised callback).
  final bool needsFollowUp;
  final String notes;

  @override
  List<Object?> get props =>
      [id, name, village, phone, activeCrop, lastVisitDate, needsFollowUp, notes];
}
