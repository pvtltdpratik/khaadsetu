import 'package:equatable/equatable.dart';

/// The village center this operator runs.
class OperatorCenter extends Equatable {
  const OperatorCenter({
    required this.centerId,
    required this.name,
    required this.village,
    required this.district,
    required this.operatorName,
    required this.phone,
    required this.isOpen,
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });

  factory OperatorCenter.fromJson(Map<String, dynamic> json) => OperatorCenter(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: json['village'] as String,
        district: (json['district'] as String?) ?? '',
        operatorName: (json['operatorName'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        isOpen: json['isOpen'] as bool,
        opensAt: json['opensAt'] as String,
        closesAt: json['closesAt'] as String,
        status: json['status'] as String,
      );

  final String centerId;
  final String name;
  final String village;
  final String district;
  final String operatorName;
  final String phone;

  /// The operator's own switch. Farmers also need the hours below to allow it.
  final bool isOpen;
  final String opensAt;
  final String closesAt;
  final String status;

  String get place => district.isEmpty ? village : '$village, $district';

  @override
  List<Object?> get props => [centerId, name, village, district, operatorName, phone, isOpen, opensAt, closesAt, status];
}
