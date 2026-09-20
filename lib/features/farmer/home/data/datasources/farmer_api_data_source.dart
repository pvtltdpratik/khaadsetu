import '../../../../../core/network/api_client.dart';
import '../../domain/entities/farmer_profile.dart';

class FarmerApiDataSource {
  const FarmerApiDataSource(this._api);

  final ApiClient _api;

  /// There is no sign-up or profile-edit screen yet, so a brand-new device
  /// would show the server's placeholder ("Farmer", no village). Saving this
  /// demo profile the first time keeps the home greeting and the schemes'
  /// land-holding eligibility check meaningful until real profile editing
  /// exists.
  static const _demoProfile = {
    'name': 'Pratik Kolhe',
    'village': 'Shirur, Pune',
    'landHoldingHectares': 1.5,
    'unreadNotificationCount': 3,
  };

  Future<FarmerProfile> fetchProfile() async {
    var json = await _api.get('/v1/farmer/profile') as Map<String, dynamic>;
    if (json['name'] == 'Farmer' && json['village'] == '') {
      json = await _api.put('/v1/farmer/profile', body: _demoProfile) as Map<String, dynamic>;
    }
    return FarmerProfile(
      name: json['name'] as String,
      village: json['village'] as String,
      unreadNotificationCount: (json['unreadNotificationCount'] as num).toInt(),
      landHoldingHectares: (json['landHoldingHectares'] as num).toDouble(),
    );
  }
}
