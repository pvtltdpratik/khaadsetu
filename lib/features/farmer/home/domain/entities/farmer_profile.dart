import 'package:equatable/equatable.dart';

class FarmerProfile extends Equatable {
  const FarmerProfile({
    required this.name,
    required this.village,
    required this.unreadNotificationCount,
    required this.landHoldingHectares,
  });

  final String name;
  final String village;
  final int unreadNotificationCount;

  /// Used to check eligibility against government schemes that cap benefits
  /// by land size (e.g. "small and marginal farmers").
  final double landHoldingHectares;

  @override
  List<Object?> get props => [name, village, unreadNotificationCount, landHoldingHectares];
}
