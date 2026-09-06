import '../../domain/entities/farmer_profile.dart';

class FarmerFakeDataSource {
  Future<FarmerProfile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const FarmerProfile(
      name: 'Pratik Kolhe',
      village: 'Shirur, Pune',
      unreadNotificationCount: 3,
      landHoldingHectares: 1.5,
    );
  }
}
