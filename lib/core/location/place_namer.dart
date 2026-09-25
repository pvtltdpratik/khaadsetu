import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../../features/farmer/centers/domain/entities/nearby_center.dart';
import '../../features/farmer/centers/presentation/providers/centers_providers.dart';

/// A place in words, worked out from a GPS position ("Shirur, Pune").
class PlaceName extends Equatable {
  const PlaceName({this.street = '', this.village = '', this.taluka = '', this.district = '', this.state = '', this.pincode = ''});

  final String street;
  final String village;
  final String taluka;
  final String district;
  final String state;
  final String pincode;

  /// What to show on a small line: "Shirur, Pune", or whichever parts we know.
  String get short {
    final parts = <String>[village, district].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return [taluka, state].where((p) => p.isNotEmpty).join(', ');
    return parts.join(', ');
  }

  bool get isEmpty => short.isEmpty;

  @override
  List<Object?> get props => [street, village, taluka, district, state, pincode];
}

/// Turns coordinates into a [PlaceName]. Swappable so tests need no platform plugin.
abstract class PlaceNamer {
  Future<PlaceName?> nameOf(double latitude, double longitude);
}

/// Uses the phone's own geocoder (Google Play services on Android). It can fail with no
/// network; callers then fall back to "your current location".
class GeocodingPlaceNamer implements PlaceNamer {
  const GeocodingPlaceNamer();

  @override
  Future<PlaceName?> nameOf(double latitude, double longitude) async {
    try {
      final marks = await geo.Geocoding().placemarkFromCoordinates(latitude, longitude).timeout(const Duration(seconds: 8));
      if (marks.isEmpty) return null;
      final m = marks.first;
      String clean(String? s) => (s ?? '').trim();
      final village = clean(m.locality).isNotEmpty ? clean(m.locality) : clean(m.subLocality);
      final name = PlaceName(
        street: [clean(m.street), clean(m.subLocality)].where((s) => s.isNotEmpty && s != village).toSet().join(', '),
        village: village,
        taluka: clean(m.subAdministrativeArea),
        district: clean(m.subAdministrativeArea),
        state: clean(m.administrativeArea),
        pincode: clean(m.postalCode),
      );
      return name.isEmpty && name.street.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }
}

final placeNamerProvider = Provider<PlaceNamer>((ref) => const GeocodingPlaceNamer());

/// Where the farmer is right now, in words. Null when their position is unknown.
/// A place they chose by name keeps that name; a GPS fix is looked up.
final currentPlaceProvider = FutureProvider.autoDispose<PlaceName?>((ref) async {
  final location = await ref.watch(farmerLocationProvider.future);
  if (location == null) return null;
  if (location.source != LocationSource.gps && location.label != null) return PlaceName(village: location.label!);
  return ref.watch(placeNamerProvider).nameOf(location.latitude, location.longitude);
});
