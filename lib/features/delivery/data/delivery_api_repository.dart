import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../farmer/centers/domain/entities/nearby_center.dart';
import '../domain/entities/delivery_models.dart';
import '../domain/repositories/delivery_repository.dart';

String _id(String id) => Uri.encodeComponent(id);

class DeliveryApiRepository implements DeliveryRepository {
  const DeliveryApiRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _map(dynamic json) => json as Map<String, dynamic>;
  List<dynamic> _list(dynamic json) => json as List<dynamic>;

  // ---- buying ----

  @override
  Future<DeliveryQuote> quote({required List<CartLine> items, required FarmerLocation location, String? centerId}) async =>
      DeliveryQuote.fromJson(_map(await _api.post('/v1/delivery/quote', body: {
        'items': [for (final l in items) {'productId': l.productId, 'quantity': l.quantity}],
        'latitude': location.latitude,
        'longitude': location.longitude,
        'centerId': ?centerId,
      })));

  @override
  Future<DeliveryTracking> tracking(String orderId) async => DeliveryTracking.fromJson(_map(await _api.get('/v1/orders/${_id(orderId)}/delivery')));

  @override
  Future<void> switchToPickup(String orderId) async {
    await _api.post('/v1/orders/${_id(orderId)}/delivery/cancel');
  }

  @override
  Future<void> rateDelivery({required String orderId, required int stars, String comment = ''}) async {
    await _api.post('/v1/orders/${_id(orderId)}/delivery/rate', body: {'stars': stars, if (comment.isNotEmpty) 'comment': comment});
  }

  // ---- being a partner ----

  @override
  Future<PartnerProfile> partner() async => PartnerProfile.fromJson(_map(await _api.get('/v1/delivery/partner')));

  @override
  Future<PartnerProfile> savePartner(Map<String, dynamic> changes) async => PartnerProfile.fromJson(_map(await _api.put('/v1/delivery/partner', body: changes)));

  @override
  Future<PartnerProfile> uploadDocument({required String kind, required Uint8List bytes, required String filename}) async {
    await _api.postMultipart(
      '/v1/delivery/partner/documents/$kind',
      fields: const {},
      files: [http.MultipartFile.fromBytes('file', bytes, filename: filename)],
    );
    return partner();
  }

  @override
  Future<PartnerProfile> submitApplication() async => PartnerProfile.fromJson(_map(await _api.post('/v1/delivery/partner/submit')));

  @override
  Future<PartnerProfile> setOnline(bool online) async => PartnerProfile.fromJson(_map(await _api.put('/v1/delivery/partner/online', body: {'online': online})));

  @override
  Future<void> withdraw() async {
    await _api.delete('/v1/delivery/partner');
  }

  @override
  Future<void> shareLocation({required double latitude, required double longitude}) async {
    await _api.put('/v1/delivery/partner/location', body: {'latitude': latitude, 'longitude': longitude});
  }

  PartnerJob _job(dynamic j) => PartnerJob.fromJson(_map(j));

  @override
  Future<List<PartnerJob>> offers() async => [for (final j in _list(await _api.get('/v1/delivery/jobs/offers'))) _job(j)];

  @override
  Future<List<PartnerJob>> activeJobs() async => [for (final j in _list(await _api.get('/v1/delivery/jobs/active'))) _job(j)];

  @override
  Future<PartnerJob> accept(String jobId) async => _job(await _api.post('/v1/delivery/jobs/${_id(jobId)}/accept'));

  @override
  Future<void> decline(String jobId) async {
    await _api.post('/v1/delivery/jobs/${_id(jobId)}/decline');
  }

  @override
  Future<PartnerJob> deliver({required String jobId, required String otp}) async => _job(await _api.post('/v1/delivery/jobs/${_id(jobId)}/deliver', body: {'otp': otp}));

  @override
  Future<void> rateBuyer({required String jobId, required int stars, String comment = ''}) async {
    await _api.post('/v1/delivery/jobs/${_id(jobId)}/rate-buyer', body: {'stars': stars, if (comment.isNotEmpty) 'comment': comment});
  }

  @override
  Future<Wallet> wallet() async => Wallet.fromJson(_map(await _api.get('/v1/delivery/wallet')));

  // ---- trips ----

  @override
  Future<List<Trip>> myTrips() async => [for (final t in _list(await _api.get('/v1/delivery/trips'))) Trip.fromJson(_map(t))];

  @override
  Future<Trip> postTrip({required GeoPoint from, required GeoPoint to, required DateTime date, required int spareKg, String note = ''}) async {
    String day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    Map<String, dynamic> place(GeoPoint p) => {'latitude': p.latitude, 'longitude': p.longitude, 'label': p.label};
    return Trip.fromJson(_map(await _api.post('/v1/delivery/trips', body: {
      'from': place(from),
      'to': place(to),
      'date': day(date),
      'spareKg': spareKg,
      if (note.isNotEmpty) 'note': note,
    })));
  }

  @override
  Future<void> cancelTrip(String id) async {
    await _api.delete('/v1/delivery/trips/${_id(id)}');
  }

  @override
  Future<List<Trip>> tripBoard({required FarmerLocation location, double weightKg = 0}) async => [
        for (final t in _list(await _api.get('/v1/delivery/trips/board', query: {
          'latitude': '${location.latitude}',
          'longitude': '${location.longitude}',
          if (weightKg > 0) 'weightKg': '$weightKg',
        })))
          Trip.fromJson(_map(t)),
      ];

  // ---- loads ----

  @override
  Future<LoadQuote> loadQuote(LoadRequest request) async => LoadQuote.fromJson(_map(await _api.post('/v1/delivery/p2p/quote', body: request.quoteJson())));

  @override
  Future<DeliveryTracking> sendLoad(LoadRequest request) async => DeliveryTracking.fromJson(_map(await _api.post('/v1/delivery/p2p', body: request.toJson())));

  @override
  Future<List<DeliveryTracking>> myLoads() async => [for (final j in _list(await _api.get('/v1/delivery/p2p'))) DeliveryTracking.fromJson(_map(j))];

  @override
  Future<DeliveryTracking> load(String jobId) async => DeliveryTracking.fromJson(_map(await _api.get('/v1/delivery/p2p/${_id(jobId)}')));

  @override
  Future<DeliveryTracking> cancelLoad(String jobId) async => DeliveryTracking.fromJson(_map(await _api.post('/v1/delivery/p2p/${_id(jobId)}/cancel')));

  @override
  Future<DeliveryTracking> handOverLoad({required String jobId, required String otp}) async =>
      DeliveryTracking.fromJson(_map(await _api.post('/v1/delivery/p2p/${_id(jobId)}/handover', body: {'otp': otp})));

  @override
  Future<void> rateLoad({required String jobId, required int stars, String comment = ''}) async {
    await _api.post('/v1/delivery/p2p/${_id(jobId)}/rate', body: {'stars': stars, if (comment.isNotEmpty) 'comment': comment});
  }
}
