import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/widgets/kit.dart';

/// The owner's side of vehicles: what he drives, the papers, and sending it to a village center to be checked.
class VehicleApi {
  const VehicleApi(this._api);

  final ApiClient _api;

  static String _e(String v) => Uri.encodeComponent(v);

  Future<Json> catalog() async => asJson(await _api.get('/v1/delivery/vehicles/catalog'));
  Future<List<Json>> mine() async => asJsonList(await _api.get('/v1/delivery/vehicles'));
  Future<Json> create(Json body) async => asJson(await _api.post('/v1/delivery/vehicles', body: body));
  Future<Json> update(String id, Json body) async => asJson(await _api.patch('/v1/delivery/vehicles/${_e(id)}', body: body));
  Future<void> remove(String id) async {
    await _api.delete('/v1/delivery/vehicles/${_e(id)}');
  }

  Future<Json> setActive(String id, bool active) async => asJson(await _api.post('/v1/delivery/vehicles/${_e(id)}/active', body: {'active': active}));
  Future<Json> submit(String id, {String? centerId}) async => asJson(await _api.post('/v1/delivery/vehicles/${_e(id)}/submit', body: {'reviewCenterId': ?centerId}));

  Future<void> uploadPhoto(String id, String kind, Uint8List bytes) async {
    await _api.postMultipart('/v1/delivery/vehicles/${_e(id)}/photos/$kind', fields: const {}, files: [http.MultipartFile.fromBytes('file', bytes, filename: '$kind.jpg')]);
  }

  Future<void> uploadDocument(String id, String kind, Uint8List bytes, {String? expiresOn}) async {
    await _api.postMultipart('/v1/delivery/vehicles/${_e(id)}/documents/$kind', fields: {'expiresOn': ?expiresOn}, files: [http.MultipartFile.fromBytes('file', bytes, filename: '$kind.jpg')]);
  }
}

final vehicleApiProvider = Provider<VehicleApi>((ref) => VehicleApi(ref.watch(apiClientProvider)));
final myVehiclesProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(vehicleApiProvider).mine());
final vehicleCatalogProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(vehicleApiProvider).catalog());
