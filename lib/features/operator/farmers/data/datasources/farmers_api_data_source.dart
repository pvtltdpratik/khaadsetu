import '../../../../../core/network/api_client.dart';
import '../../domain/entities/farmer.dart';

class FarmersApiDataSource {
  const FarmersApiDataSource(this._api);

  final ApiClient _api;

  Future<List<Farmer>> fetchFarmers() async {
    final list = await _api.get('/v1/operator/farmers') as List;
    return list.map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  Future<Farmer> fetchFarmerById(String id) async {
    return _parse(await _api.get('/v1/operator/farmers/$id') as Map<String, dynamic>);
  }

  Farmer _parse(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'] as String,
      name: json['name'] as String,
      village: json['village'] as String,
      phone: json['phone'] as String,
      activeCrop: json['activeCrop'] as String,
      lastVisitDate: DateTime.parse(json['lastVisitDate'] as String).toLocal(),
      needsFollowUp: json['needsFollowUp'] as bool,
      notes: json['notes'] as String,
    );
  }
}
