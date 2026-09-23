import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_client.dart';
import '../domain/entities/nearby_center.dart';
import '../domain/repositories/centers_repository.dart';

/// Center discovery against the API (`/v1/centers/...`, `/v1/farmer/profile`).
class CentersApiRepository implements CentersRepository {
  const CentersApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<NearbyResult> nearby({required FarmerLocation location, Cart cart = Cart.empty, int limit = 5}) async {
    final json = await _api.post('/v1/centers/nearby', body: {
      'latitude': location.latitude,
      'longitude': location.longitude,
      // The server only distinguishes a device fix from a chosen point; a
      // village is a chosen point.
      'locationSource': location.source == LocationSource.gps ? 'gps' : 'pin',
      if (cart.lines.isNotEmpty) 'items': [for (final l in cart.lines) {'productId': l.productId, 'quantity': l.quantity}],
      'limit': limit,
    }) as Map<String, dynamic>;
    return NearbyResult(
      location: location,
      radiusKm: (json['radiusKm'] as num).toInt(),
      centers: (json['centers'] as List).map((e) => NearbyCenter.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<List<Village>> villages(String query) async {
    final list = await _api.get('/v1/centers/villages', query: {'q': query}) as List;
    return list.map((e) => Village.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FarmerLocation?> savedLocation() async {
    final profile = await _api.get('/v1/farmer/profile') as Map<String, dynamic>;
    final lat = profile['latitude'] as num?;
    final lng = profile['longitude'] as num?;
    if (lat != null && lng != null) {
      return FarmerLocation(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        source: LocationSource.parse(profile['locationSource']),
      );
    }
    // No saved fix: fall back to the village they registered with.
    final registered = ((profile['village'] as String?) ?? '').split(',').first.trim();
    if (registered.isEmpty) return null;
    final matches = await villages(registered);
    final match = matches.where((v) => v.name.toLowerCase() == registered.toLowerCase());
    if (match.isEmpty) return null;
    final v = match.first;
    return FarmerLocation(latitude: v.latitude, longitude: v.longitude, source: LocationSource.village, label: v.name);
  }

  @override
  Future<void> saveLocation(FarmerLocation location) async {
    await _api.put('/v1/farmer/profile', body: {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'locationSource': location.source.name,
    });
  }
}

/// The device's GPS, with the reason worded for the farmer when it is unavailable.
class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  @override
  Future<FarmerLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Location is turned off on this device.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Location permission was not given.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low))
          .timeout(const Duration(seconds: 15));
      return FarmerLocation(latitude: p.latitude, longitude: p.longitude, source: LocationSource.gps);
    } on TimeoutException {
      throw const LocationUnavailable('Could not get your location in time.');
    }
  }
}
