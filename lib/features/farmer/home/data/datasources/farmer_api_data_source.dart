import '../../../../../core/network/api_client.dart';
import '../../domain/entities/farmer_profile.dart';

class FarmerApiDataSource {
  const FarmerApiDataSource(this._api);

  final ApiClient _api;

  Future<FarmerProfile> fetchProfile() async {
    final json = await _api.get('/v1/farmer/profile') as Map<String, dynamic>;
    return FarmerProfile(
      name: json['name'] as String,
      village: json['village'] as String,
      unreadNotificationCount: (json['unreadNotificationCount'] as num).toInt(),
      landHoldingHectares: (json['landHoldingHectares'] as num).toDouble(),
    );
  }
}
