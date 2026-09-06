import 'package:equatable/equatable.dart';

class FarmerProfile extends Equatable {
  const FarmerProfile({
    required this.name,
    required this.village,
    required this.unreadNotificationCount,
  });

  final String name;
  final String village;
  final int unreadNotificationCount;

  @override
  List<Object?> get props => [name, village, unreadNotificationCount];
}
