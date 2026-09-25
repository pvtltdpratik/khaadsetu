import 'profile_models.dart';

/// Everything on the farmer's profile page. One interface so screens can be tested with a fake.
abstract class ProfileRepository {
  Future<ContactInfo> contact();

  /// Saves whichever of the two is given; the other stays as it was.
  Future<ContactInfo> saveContact({String? email, String? phone});

  Future<String> saveName(String name);

  /// The total land the farmer works, in hectares (schemes cap benefits by it).
  Future<void> saveLandHolding(double hectares);

  Future<List<SavedAddress>> addresses();
  Future<SavedAddress> addAddress(SavedAddress address, {bool makeDefault = false});
  Future<SavedAddress> updateAddress(SavedAddress address);
  Future<void> makeDefault(String addressId);
  Future<void> deleteAddress(String addressId);

  Future<MyActivity> activity();

  Future<FarmDetails> details();

  /// A partial update: a null value forgets that answer.
  Future<FarmDetails> saveDetails(Map<String, Object?> changes);
}
