import '../entities/operator_center.dart';

abstract class OperatorCenterRepository {
  Future<OperatorCenter> center();

  /// Only the fields given are changed. Location and status are the admin's.
  Future<OperatorCenter> update({bool? isOpen, String? opensAt, String? closesAt, String? phone, String? operatorName});
}
