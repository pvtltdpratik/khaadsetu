import '../../../../core/network/api_client.dart';
import '../domain/profile_models.dart';
import '../domain/profile_repository.dart';

class ProfileApiRepository implements ProfileRepository {
  const ProfileApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<ContactInfo> contact() async => ContactInfo.fromJson(await _api.get('/v1/farmer/contact') as Map<String, dynamic>);

  @override
  Future<ContactInfo> saveContact({String? email, String? phone}) async =>
      ContactInfo.fromJson(await _api.put('/v1/farmer/contact', body: {'email': ?email, 'phone': ?phone}) as Map<String, dynamic>);

  @override
  Future<String> saveName(String name) async {
    final json = await _api.put('/v1/farmer/profile', body: {'name': name}) as Map<String, dynamic>;
    return json['name'] as String;
  }

  @override
  Future<void> saveLandHolding(double hectares) async {
    await _api.put('/v1/farmer/profile', body: {'landHoldingHectares': hectares});
  }

  @override
  Future<List<SavedAddress>> addresses() async {
    final list = await _api.get('/v1/farmer/addresses') as List;
    return list.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SavedAddress> addAddress(SavedAddress address, {bool makeDefault = false}) async =>
      SavedAddress.fromJson(await _api.post('/v1/farmer/addresses', body: {...address.toBody(), 'isDefault': makeDefault}) as Map<String, dynamic>);

  @override
  Future<SavedAddress> updateAddress(SavedAddress address) async =>
      SavedAddress.fromJson(await _api.patch('/v1/farmer/addresses/${address.addressId}', body: address.toBody()) as Map<String, dynamic>);

  @override
  Future<void> makeDefault(String addressId) async {
    await _api.post('/v1/farmer/addresses/$addressId/default');
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await _api.delete('/v1/farmer/addresses/$addressId');
  }

  @override
  Future<MyActivity> activity() async => MyActivity.fromJson(await _api.get('/v1/community/mine') as Map<String, dynamic>);

  @override
  Future<FarmDetails> details() async => FarmDetails.fromJson(await _api.get('/v1/farmer/details') as Map<String, dynamic>);

  @override
  Future<FarmDetails> saveDetails(Map<String, Object?> changes) async =>
      FarmDetails.fromJson(await _api.put('/v1/farmer/details', body: changes) as Map<String, dynamic>);
}
