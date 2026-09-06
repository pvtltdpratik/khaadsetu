import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';

/// Stands in for a remote schemes-directory API. Holds application status
/// in memory so [applyToScheme] actually changes what a later read sees.
class SchemesFakeDataSource {
  static final List<GovScheme> _schemes = [
    GovScheme(
      id: 'scheme-pmkisan',
      name: 'PM-KISAN Income Support',
      agency: 'Dept. of Agriculture & Farmers Welfare',
      category: SchemeCategory.incomeSupport,
      description: 'Direct income support paid to landholding farmer '
          'families to help with input costs across the season.',
      benefit: '₹6,000 per year, in 3 installments',
      eligibilityCriteria: const [
        'Must own cultivable agricultural land',
        'Family-based landholding; no income-tax payer in the family',
      ],
      maxLandHoldingHectares: null,
      applicationDeadline: null,
    ),
    GovScheme(
      id: 'scheme-fasalbima',
      name: 'PM Fasal Bima Yojana',
      agency: 'Ministry of Agriculture & Farmers Welfare',
      category: SchemeCategory.insurance,
      description: 'Subsidized crop insurance covering yield loss from '
          'natural calamities, pests, and disease.',
      benefit: 'Subsidized premium; claim payout based on assessed yield loss',
      eligibilityCriteria: const [
        'Any farmer growing a notified crop in a notified area',
        'Enroll through your bank or Common Service Centre before the season cutoff',
      ],
      maxLandHoldingHectares: null,
      applicationDeadline: DateTime.now().add(const Duration(days: 42)),
    ),
    GovScheme(
      id: 'scheme-pkvy',
      name: 'Paramparagat Krishi Vikas Yojana',
      agency: 'Ministry of Agriculture & Farmers Welfare',
      category: SchemeCategory.subsidy,
      description: 'Supports small and marginal farmers converting to '
          'organic farming methods through cluster-based groups.',
      benefit: '₹50,000 per hectare over 3 years for organic conversion',
      eligibilityCriteria: const [
        'Land holding up to 2 hectares',
        'Willingness to join or form a farmer cluster group',
      ],
      maxLandHoldingHectares: 2.0,
      applicationDeadline: null,
    ),
    GovScheme(
      id: 'scheme-kcc',
      name: 'Kisan Credit Card',
      agency: 'Dept. of Financial Services',
      category: SchemeCategory.creditSupport,
      description: 'Short-term credit for crop production and allied '
          'activities at a subsidized interest rate.',
      benefit: 'Loans up to ₹3 lakh at subsidized interest',
      eligibilityCriteria: const [
        'Any farmer with cultivable land, or a tenant/sharecropper',
        'Valid land records or a crop-sharing agreement',
      ],
      maxLandHoldingHectares: null,
      applicationDeadline: null,
    ),
    GovScheme(
      id: 'scheme-mechanization',
      name: 'Sub-Mission on Agricultural Mechanization',
      agency: 'Dept. of Agriculture & Farmers Welfare',
      category: SchemeCategory.subsidy,
      description: 'Subsidy for marginal farmers purchasing small farm '
          'equipment such as sprayers and power tillers.',
      benefit: '40-50% subsidy on eligible equipment purchases',
      eligibilityCriteria: const [
        'Land holding up to 1 hectare (marginal farmer)',
        'Must not have received the same equipment subsidy in the past 5 years',
      ],
      maxLandHoldingHectares: 1.0,
      applicationDeadline: DateTime.now().add(const Duration(days: 20)),
    ),
  ];

  final Map<String, SchemeApplication> _applications = {
    // Seeded so the application-status screen has something to show
    // immediately, without depending on tapping "Apply" first.
    'scheme-fasalbima': SchemeApplication(
      schemeId: 'scheme-fasalbima',
      status: ApplicationStatus.underReview,
      appliedDate: DateTime.now().subtract(const Duration(days: 6)),
    ),
  };

  Future<List<GovScheme>> fetchSchemes() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.unmodifiable(_schemes);
  }

  Future<GovScheme> fetchSchemeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _schemes.firstWhere((s) => s.id == id);
  }

  Future<SchemeApplication> fetchApplicationStatus(String schemeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _applications[schemeId] ??
        SchemeApplication(schemeId: schemeId, status: ApplicationStatus.notApplied, appliedDate: null);
  }

  Future<SchemeApplication> applyToScheme(String schemeId) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final application = SchemeApplication(
      schemeId: schemeId,
      status: ApplicationStatus.submitted,
      appliedDate: DateTime.now(),
    );
    _applications[schemeId] = application;
    return application;
  }
}
