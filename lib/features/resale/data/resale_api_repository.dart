import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../domain/resale_models.dart';
import '../domain/resale_repository.dart';

class ResaleApiRepository implements ResaleRepository {
  const ResaleApiRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _map(Object? json) => json as Map<String, dynamic>;
  List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) parse) => (json as List).map((e) => parse(e as Map<String, dynamic>)).toList();

  // ---- the farmer ----

  @override
  Future<List<EligibleProduct>> eligible() async => _list(await _api.get('/v1/resale/eligible'), EligibleProduct.fromJson);

  @override
  Future<PriceGuide> suggest({required String productId, required ResaleCondition condition, String? mfgDate}) async =>
      PriceGuide.fromJson(_map(await _api.post('/v1/resale/suggest', body: {'productId': productId, 'condition': condition.api, 'mfgDate': ?mfgDate})));

  @override
  Future<ResaleListing> create(NewListing listing, {required Uint8List front, required Uint8List back}) async {
    final draft = ResaleListing.fromJson(_map(await _api.post('/v1/resale', body: listing.toJson())));
    for (final (kind, bytes) in [('front', front), ('back', back)]) {
      await _api.postMultipart('/v1/resale/${draft.id}/photos/$kind', fields: const {}, files: [http.MultipartFile.fromBytes('file', bytes, filename: '$kind.jpg')]);
    }
    return ResaleListing.fromJson(_map(await _api.post('/v1/resale/${draft.id}/submit')));
  }

  @override
  Future<List<ResaleListing>> mine() async => _list(await _api.get('/v1/resale/mine'), ResaleListing.fromJson);

  @override
  Future<ResaleListing> listing(String id) async => ResaleListing.fromJson(_map(await _api.get('/v1/resale/$id')));

  @override
  Future<ResaleListing> withdraw(String id) async => ResaleListing.fromJson(_map(await _api.post('/v1/resale/$id/withdraw')));

  @override
  Future<WalletState> wallet() async => WalletState.fromJson(_map(await _api.get('/v1/wallet')));

  @override
  Future<void> raiseDispute({required String orderId, required String reason}) async {
    await _api.post('/v1/resale/disputes', body: {'orderId': orderId, 'reason': reason});
  }

  // ---- the village center ----

  @override
  Future<List<ResaleListing>> queue({List<ResaleStatus>? statuses}) async =>
      _list(await _api.get('/v1/operator/resale', query: {'status': statuses?.map((s) => s.api).join(',')}), ResaleListing.fromJson);

  @override
  Future<Uint8List> photo(String id, String kind) => _api.getBytes('/v1/operator/resale/$id/photos/$kind');

  @override
  Future<ResaleListing> preapprove(String id) async => ResaleListing.fromJson(_map(await _api.post('/v1/operator/resale/$id/preapprove')));

  @override
  Future<ResaleListing> requestInspection(String id, {String note = ''}) async =>
      ResaleListing.fromJson(_map(await _api.post('/v1/operator/resale/$id/request-inspection', body: {if (note.isNotEmpty) 'note': note})));

  @override
  Future<ResaleListing> reject(String id, String reason) async => ResaleListing.fromJson(_map(await _api.post('/v1/operator/resale/$id/reject', body: {'reason': reason})));

  @override
  Future<ResaleListing> inspect(String id, InspectionChecklist checklist) async =>
      ResaleListing.fromJson(_map(await _api.post('/v1/operator/resale/$id/inspect', body: checklist.toJson())));

  @override
  Future<PriceGuide> suggestAtCounter({required String productId, required ResaleCondition condition, String? visual, String? mfgDate}) async =>
      PriceGuide.fromJson(_map(await _api.post('/v1/operator/resale/suggest', body: {'productId': productId, 'condition': condition.api, 'visual': ?visual, 'mfgDate': ?mfgDate})));

  @override
  Future<List<SellerMatch>> findSellers(String query) async => _list(await _api.get('/v1/operator/resale/sellers', query: {'q': query}), SellerMatch.fromJson);

  @override
  Future<ResaleListing> walkIn({String? sellerId, String? sellerName, String? sellerPhone, required String productId, required PayoutMode payoutMode, required InspectionChecklist checklist}) async =>
      ResaleListing.fromJson(_map(await _api.post('/v1/operator/resale/walk-in', body: {
        'sellerId': ?sellerId,
        'sellerName': ?sellerName,
        'sellerPhone': ?sellerPhone,
        'productId': productId,
        'payoutMode': payoutMode.api,
        ...checklist.toJson(),
      })));

  @override
  Future<List<PayoutDue>> cashDue() async => _list(await _api.get('/v1/operator/resale/payouts/cash'), PayoutDue.fromJson);

  @override
  Future<void> markCashPaid(String saleId) async {
    await _api.post('/v1/operator/resale/payouts/$saleId/cash-paid');
  }

  // ---- the platform ----

  @override
  Future<List<ResaleDispute>> disputes({String? status}) async => _list(await _api.get('/v1/admin/resale/disputes', query: {'status': status}), ResaleDispute.fromJson);

  @override
  Future<void> resolveDispute(String id, {required bool uphold, int? refundPercent, String note = ''}) async {
    await _api.post('/v1/admin/resale/disputes/$id/resolve', body: {'decision': uphold ? 'uphold' : 'reject', 'refundPercent': ?refundPercent, if (note.isNotEmpty) 'note': note});
  }

  @override
  Future<List<PayoutDue>> upiPayouts() async => _list(await _api.get('/v1/admin/resale/payouts/upi'), PayoutDue.fromJson);

  @override
  Future<void> markUpiPaid(String saleId, {String reference = ''}) async {
    await _api.post('/v1/admin/resale/payouts/$saleId/paid', body: {if (reference.isNotEmpty) 'reference': reference});
  }
}
