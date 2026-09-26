import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/widgets/kit.dart';

/// Farmer-made organic products: what a farmer sells (his listings), what others sell (the market) and the orders between them.
class OwnApi {
  const OwnApi(this._api);

  final ApiClient _api;

  static String _e(String v) => Uri.encodeComponent(v);

  Future<Json> catalog() async => asJson(await _api.get('/v1/own/catalog'));
  Future<List<Json>> mine() async => asJsonList(await _api.get('/v1/own/listings/mine'));
  Future<Json> summary() async => asJson(await _api.get('/v1/own/summary'));
  Future<Json> create(Json body) async => asJson(await _api.post('/v1/own/listings', body: body));
  Future<Json> update(String id, Json body) async => asJson(await _api.patch('/v1/own/listings/${_e(id)}', body: body));
  Future<void> remove(String id) async {
    await _api.delete('/v1/own/listings/${_e(id)}');
  }

  Future<void> uploadPhoto(String id, int position, Uint8List bytes) async {
    await _api.postMultipart('/v1/own/listings/${_e(id)}/photos/$position', fields: const {}, files: [http.MultipartFile.fromBytes('file', bytes, filename: 'photo$position.jpg')]);
  }

  Future<void> uploadLabReport(String id, Uint8List bytes) async {
    await _api.postMultipart('/v1/own/listings/${_e(id)}/lab-report', fields: const {}, files: [http.MultipartFile.fromBytes('file', bytes, filename: 'lab.jpg')]);
  }

  Future<Json> submit(String id) async => asJson(await _api.post('/v1/own/listings/${_e(id)}/submit'));
  Future<Json> pause(String id) async => asJson(await _api.post('/v1/own/listings/${_e(id)}/pause'));
  Future<Json> resume(String id) async => asJson(await _api.post('/v1/own/listings/${_e(id)}/resume'));
  Future<Json> renew(String id) async => asJson(await _api.post('/v1/own/listings/${_e(id)}/renew'));

  Future<List<Json>> market({String? category, String sort = 'nearest', double? latitude, double? longitude, String? q}) async => asJsonList(await _api.get('/v1/own/market', query: {
        'category': category, 'sort': sort, 'q': q,
        'latitude': latitude?.toString(), 'longitude': longitude?.toString(),
      }));
  Future<Json> detail(String id) async => asJson(await _api.get('/v1/own/listings/${_e(id)}'));
  Future<void> report(String id, String reason) async {
    await _api.post('/v1/own/listings/${_e(id)}/report', body: {'reason': reason});
  }

  Future<Json> order(String id, {required double quantity, required String fulfilment, Json? address}) async =>
      asJson(await _api.post('/v1/own/listings/${_e(id)}/order', body: {'quantity': quantity, 'fulfilment': fulfilment, 'address': ?address}));

  Future<List<Json>> sales(String role) async => asJsonList(await _api.get('/v1/own/sales', query: {'role': role}));
  Future<Json> sale(String id) async => asJson(await _api.get('/v1/own/sales/${_e(id)}'));
  Future<Json> ready(String id) async => asJson(await _api.post('/v1/own/sales/${_e(id)}/ready'));
  Future<Json> complete(String id, {required String otp, required String mode}) async => asJson(await _api.post('/v1/own/sales/${_e(id)}/complete', body: {'otp': otp, 'mode': mode}));
  Future<Json> cancel(String id, {String reason = ''}) async => asJson(await _api.post('/v1/own/sales/${_e(id)}/cancel', body: {'reason': reason}));
  Future<Json> requestDelivery(String id, {required double weightKg}) async => asJson(await _api.post('/v1/own/sales/${_e(id)}/delivery', body: {'weightKg': weightKg}));
  Future<Json> review(String id, {required int stars, String comment = ''}) async => asJson(await _api.post('/v1/own/sales/${_e(id)}/review', body: {'stars': stars, 'comment': comment}));
}

final ownApiProvider = Provider<OwnApi>((ref) => OwnApi(ref.watch(apiClientProvider)));
final myListingsProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(ownApiProvider).mine());
final ownSummaryProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(ownApiProvider).summary());
final ownCatalogProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(ownApiProvider).catalog());
final ownDetailProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) => ref.watch(ownApiProvider).detail(id));
final ownSalesProvider = FutureProvider.autoDispose.family<List<Json>, String>((ref, role) => ref.watch(ownApiProvider).sales(role));
final ownSaleProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) => ref.watch(ownApiProvider).sale(id));

/// The market for one filter, written as text so the same filter is the same key: "category|sort|search".
final ownMarketProvider = FutureProvider.autoDispose.family<List<Json>, String>((ref, key) async {
  final parts = key.split('|');
  return ref.watch(ownApiProvider).market(category: parts[0].isEmpty ? null : parts[0], sort: parts[1], q: parts[2].isEmpty ? null : parts[2]);
});
