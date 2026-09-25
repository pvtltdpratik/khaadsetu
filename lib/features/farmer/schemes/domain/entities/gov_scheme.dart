import 'package:equatable/equatable.dart';

enum SchemeCategory { incomeSupport, insurance, subsidy, creditSupport, training, marketing, livestock, processing }

/// One kind of help inside a programme, with what it pays, e.g. "Tractor up to 40 HP" and "₹45,000 or 25% of cost".
class SchemeComponent extends Equatable {
  const SchemeComponent({required this.title, required this.assistance});

  final String title;
  final String assistance;

  @override
  List<Object?> get props => [title, assistance];
}

/// A government scheme listing. Whether the farmer qualifies is decided on the server from
/// what they saved on their profile (see SchemeEligibilityResult); the app only shows it.
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
    this.level = 'central',
    this.sector = 'General',
    this.audience = 'farmer',
    this.components = const [],
    this.howToApply = '',
    this.contact = '',
    this.website = '',
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

  /// 'central' or 'state'.
  final String level;

  /// The group it is listed under: "Soil & fertilizer", "Insurance", ...
  final String sector;

  /// Who it is for: 'farmer', 'group' (FPOs, cooperatives, SHGs) or 'enterprise'.
  final String audience;
  final List<SchemeComponent> components;
  final String howToApply;
  final String contact;
  final String website;

  bool get isForFarmers => audience == 'farmer';

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
        level,
        sector,
        audience,
        components,
        howToApply,
        contact,
        website,
      ];
}
