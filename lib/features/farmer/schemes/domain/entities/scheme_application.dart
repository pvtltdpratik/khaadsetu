import 'package:equatable/equatable.dart';

enum ApplicationStatus { notApplied, submitted, underReview, approved, rejected }

class SchemeApplication extends Equatable {
  const SchemeApplication({
    required this.schemeId,
    required this.status,
    required this.appliedDate,
  });

  final String schemeId;
  final ApplicationStatus status;
  final DateTime? appliedDate;

  @override
  List<Object?> get props => [schemeId, status, appliedDate];
}
