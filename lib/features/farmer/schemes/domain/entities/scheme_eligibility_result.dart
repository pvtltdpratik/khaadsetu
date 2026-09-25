import 'package:equatable/equatable.dart';

/// Where a farmer stands on a scheme, worked out by the server from their saved answers.
enum EligibilityStatus {
  /// Every rule that can be checked is met.
  eligible,

  /// Nothing rules them out, but some answers are still missing.
  possible,

  /// At least one rule is not met.
  notEligible,

  /// No rules to check: open to everyone.
  open;

  static EligibilityStatus parse(Object? raw) => EligibilityStatus.values.firstWhere((s) => s.name == raw, orElse: () => EligibilityStatus.possible);
}

enum CheckStatus {
  met,
  notMet,
  unknown,

  /// A condition that cannot be checked from a profile (shown, not scored).
  info;

  static CheckStatus parse(Object? raw) => CheckStatus.values.firstWhere((s) => s.name == raw, orElse: () => CheckStatus.info);
}

class EligibilityCheck extends Equatable {
  const EligibilityCheck({required this.label, required this.status, this.needs});

  factory EligibilityCheck.fromJson(Map<String, dynamic> json) =>
      EligibilityCheck(label: json['label'] as String, status: CheckStatus.parse(json['status']), needs: json['needs'] as String?);

  final String label;
  final CheckStatus status;

  /// The profile answer that would settle an unknown check.
  final String? needs;

  @override
  List<Object?> get props => [label, status, needs];
}

class SchemeEligibilityResult extends Equatable {
  const SchemeEligibilityResult({required this.schemeId, required this.status, required this.met, required this.total, this.missing = const [], this.checks = const []});

  factory SchemeEligibilityResult.fromJson(Map<String, dynamic> json) => SchemeEligibilityResult(
        schemeId: json['schemeId'] as String,
        status: EligibilityStatus.parse(json['status']),
        met: (json['met'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        missing: ((json['missing'] as List?) ?? const []).cast<String>(),
        checks: ((json['checks'] as List?) ?? const []).map((e) => EligibilityCheck.fromJson(e as Map<String, dynamic>)).toList(),
      );

  final String schemeId;
  final EligibilityStatus status;
  final int met;
  final int total;

  /// Profile answers still needed to be sure (keys of the farm details).
  final List<String> missing;
  final List<EligibilityCheck> checks;

  @override
  List<Object?> get props => [schemeId, status, met, total, missing, checks];
}
