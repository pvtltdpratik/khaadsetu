import 'package:khaadsetu_version1/core/location/place_namer.dart';
import 'package:khaadsetu_version1/features/farmer/profile/domain/profile_models.dart';
import 'package:khaadsetu_version1/features/farmer/profile/domain/profile_repository.dart';

class FakePlaceNamer implements PlaceNamer {
  FakePlaceNamer(this.place);

  final PlaceName? place;

  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async => place;
}

SavedAddress address(String id, {String label = 'Home', bool isDefault = false, double? lat}) => SavedAddress(
      addressId: id,
      label: label,
      fullName: 'Asha Patil',
      phone: '9876543210',
      line1: 'Gat 12, Near Temple',
      village: 'Shirur',
      district: 'Pune',
      pincode: '412210',
      latitude: lat,
      longitude: lat,
      isDefault: isDefault,
    );

/// An in-memory profile, with the same rules as the server where the screens rely on them.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({List<SavedAddress>? addresses, this.contactInfo = const ContactInfo(), this.activityData = const MyActivity(), Map<String, dynamic>? details})
      : stored = addresses ?? [],
        answers = details ?? {};

  final List<SavedAddress> stored;
  ContactInfo contactInfo;
  MyActivity activityData;
  Map<String, dynamic> answers;
  String? name;
  double? land;
  var _next = 100;

  @override
  Future<ContactInfo> contact() async => contactInfo;

  @override
  Future<ContactInfo> saveContact({String? email, String? phone}) async =>
      contactInfo = ContactInfo(email: email ?? contactInfo.email, phone: phone ?? contactInfo.phone, loginEmail: contactInfo.loginEmail);

  @override
  Future<String> saveName(String value) async => name = value;

  @override
  Future<void> saveLandHolding(double hectares) async => land = hectares;

  @override
  Future<List<SavedAddress>> addresses() async => [...stored]..sort((a, b) => a.isDefault == b.isDefault ? 0 : (a.isDefault ? -1 : 1));

  @override
  Future<SavedAddress> addAddress(SavedAddress a, {bool makeDefault = false}) async {
    final isDefault = stored.isEmpty || makeDefault;
    if (isDefault) _clearDefault();
    final saved = SavedAddress(
      addressId: 'addr-${_next++}',
      label: a.label,
      fullName: a.fullName,
      phone: a.phone,
      line1: a.line1,
      line2: a.line2,
      landmark: a.landmark,
      village: a.village,
      taluka: a.taluka,
      district: a.district,
      state: a.state,
      pincode: a.pincode,
      latitude: a.latitude,
      longitude: a.longitude,
      isDefault: isDefault,
    );
    stored.add(saved);
    return saved;
  }

  void _clearDefault() {
    for (var i = 0; i < stored.length; i++) {
      final s = stored[i];
      if (s.isDefault) stored[i] = _copy(s, isDefault: false);
    }
  }

  SavedAddress _copy(SavedAddress s, {bool? isDefault}) => SavedAddress(
        addressId: s.addressId,
        label: s.label,
        fullName: s.fullName,
        phone: s.phone,
        line1: s.line1,
        line2: s.line2,
        landmark: s.landmark,
        village: s.village,
        taluka: s.taluka,
        district: s.district,
        state: s.state,
        pincode: s.pincode,
        latitude: s.latitude,
        longitude: s.longitude,
        isDefault: isDefault ?? s.isDefault,
      );

  @override
  Future<SavedAddress> updateAddress(SavedAddress a) async {
    final i = stored.indexWhere((s) => s.addressId == a.addressId);
    final updated = _copy(a, isDefault: stored[i].isDefault);
    stored[i] = updated;
    return updated;
  }

  @override
  Future<void> makeDefault(String id) async {
    _clearDefault();
    final i = stored.indexWhere((s) => s.addressId == id);
    stored[i] = _copy(stored[i], isDefault: true);
  }

  @override
  Future<void> deleteAddress(String id) async {
    final gone = stored.firstWhere((s) => s.addressId == id);
    stored.removeWhere((s) => s.addressId == id);
    if (gone.isDefault && stored.isNotEmpty) stored[0] = _copy(stored[0], isDefault: true);
  }

  @override
  Future<MyActivity> activity() async => activityData;

  @override
  Future<FarmDetails> details() async => FarmDetails(Map<String, dynamic>.from(answers));

  @override
  Future<FarmDetails> saveDetails(Map<String, Object?> changes) async {
    for (final e in changes.entries) {
      if (e.value == null) {
        answers.remove(e.key);
      } else {
        answers[e.key] = e.value;
      }
    }
    return details();
  }
}
