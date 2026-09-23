import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/centers_api_repository.dart';
import '../../domain/entities/nearby_center.dart';
import '../../domain/entities/surplus_offer.dart';
import '../../domain/repositories/centers_repository.dart';

final centersRepositoryProvider = Provider<CentersRepository>((ref) => CentersApiRepository(ref.watch(apiClientProvider)));

final deviceLocationProvider = Provider<DeviceLocation>((ref) => const GeolocatorDeviceLocation());

/// Where the farmer is. Resolved once per session, in order of preference:
///   1. the phone's GPS (the browser or OS asks permission the first time)
///   2. the location saved on their profile
///   3. the village they registered with
/// and null when none of those work, which the UI answers by asking them to
/// pick their village.
class FarmerLocationNotifier extends AsyncNotifier<FarmerLocation?> {
  /// A location the farmer set by hand while the automatic lookup was still
  /// running. The lookup can take many seconds (GPS timeout), and it must not
  /// overwrite what the farmer has just told us.
  FarmerLocation? _chosen;

  @override
  Future<FarmerLocation?> build() async {
    _chosen = null;
    final repo = ref.read(centersRepositoryProvider);
    try {
      final gps = await ref.read(deviceLocationProvider).current();
      if (_chosen != null) return _chosen;
      // Remember it so the next visit (or a phone with GPS off) still has somewhere to start.
      unawaited(repo.saveLocation(gps).catchError((_) {}));
      return gps;
    } catch (_) {
      // GPS off, denied, slow or unsupported: fall back to what we know.
    }
    if (_chosen != null) return _chosen;
    try {
      final saved = await repo.savedLocation();
      return _chosen ?? saved;
    } catch (_) {
      return _chosen;
    }
  }

  /// Tries the phone's GPS again. Returns null on success, else a message for the farmer.
  Future<String?> useGps() async {
    try {
      final gps = await ref.read(deviceLocationProvider).current();
      _chosen = gps;
      state = AsyncData(gps);
      unawaited(ref.read(centersRepositoryProvider).saveLocation(gps).catchError((_) {}));
      return null;
    } on LocationUnavailable catch (err) {
      return '${err.message} Choose your village instead.';
    } catch (_) {
      return 'Could not read your location. Choose your village instead.';
    }
  }

  /// The farmer picked where they are: the fallback for a phone with no GPS.
  Future<void> chooseVillage(Village village) async {
    final location = FarmerLocation(
      latitude: village.latitude,
      longitude: village.longitude,
      source: LocationSource.village,
      label: village.name,
    );
    _chosen = location;
    state = AsyncData(location);
    try {
      await ref.read(centersRepositoryProvider).saveLocation(location);
    } catch (_) {
      // Saved only for next time; the choice already applies.
    }
  }
}

final farmerLocationProvider = AsyncNotifierProvider<FarmerLocationNotifier, FarmerLocation?>(FarmerLocationNotifier.new);

/// Centers near the farmer for [cart] (empty = just browsing). Null when we
/// don't know where the farmer is yet.
final nearbyCentersProvider = FutureProvider.autoDispose.family<NearbyResult?, Cart>((ref, cart) async {
  final location = await ref.watch(farmerLocationProvider.future);
  if (location == null) return null;
  return ref.watch(centersRepositoryProvider).nearby(location: location, cart: cart);
});

/// Discounted surplus near the farmer, nearest first; [productId] null means
/// every product. Null when we don't know where the farmer is yet.
final surplusNearbyProvider = FutureProvider.autoDispose.family<List<SurplusOffer>?, String?>((ref, productId) async {
  final location = await ref.watch(farmerLocationProvider.future);
  if (location == null) return null;
  return ref.watch(centersRepositoryProvider).surplusNearby(location: location, productId: productId);
});

/// Whether the farmer is waiting to hear that [productId] is back in stock.
final notifyMeProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, productId) => ref.watch(centersRepositoryProvider).isNotifyMeOn(productId),
);
