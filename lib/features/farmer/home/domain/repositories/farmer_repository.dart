import '../entities/farmer_profile.dart';

abstract class FarmerRepository {
  Future<FarmerProfile> getProfile();
}
