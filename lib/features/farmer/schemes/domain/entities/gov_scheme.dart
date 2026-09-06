import 'package:equatable/equatable.dart';

enum SchemeCategory { incomeSupport, insurance, subsidy, creditSupport, training }

/// A government scheme listing. [maxLandHoldingHectares] is the one
/// eligibility rule modeled here (null = open to any landholding) — real
/// schemes have more criteria, but this is the one the mock farmer profile
/// can actually be checked against (see [SchemeEligibility]).
class GovScheme extends Equatable {
  const GovScheme({
    required this.id,
    required this.name,
    required this.agency,
    required this.category,
    required this.description,
    required this.benefit,
    required this.eligibilityCriteria,
    required this.maxLandHoldingHectares,
    required this.applicationDeadline,
  });

  final String id;
  final String name;
  final String agency;
  final SchemeCategory category;
  final String description;
  final String benefit;
  final List<String> eligibilityCriteria;
  final double? maxLandHoldingHectares;
  final DateTime? applicationDeadline;

  @override
  List<Object?> get props => [
        id,
        name,
        agency,
        category,
        description,
        benefit,
        eligibilityCriteria,
        maxLandHoldingHectares,
        applicationDeadline,
      ];
}
