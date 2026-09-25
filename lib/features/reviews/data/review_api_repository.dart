import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../domain/review_models.dart';
import '../domain/review_repository.dart';

class ReviewApiRepository implements ReviewRepository {
  const ReviewApiRepository(this._api);

  final ApiClient _api;

  Map<String, dynamic> _map(Object? json) => json as Map<String, dynamic>;

  @override
  Future<List<CropRef>> crops() async => (await _api.get('/v1/reviews/reference/crops') as List).map((e) => CropRef.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<ProductReviews> forProduct(String productId, ReviewFilter f) async => ProductReviews.fromJson(_map(await _api.get('/v1/reviews/product/$productId', query: {
        'soil': f.soil,
        'crop': f.crop,
        'season': f.season,
        'size': f.size,
        'improved': f.improved ? '1' : null,
      })));

  @override
  Future<YieldPrediction> predict({required String productId, required double acres, required String crop}) async =>
      YieldPrediction.fromJson(_map(await _api.get('/v1/reviews/product/$productId/prediction', query: {'acres': '$acres', 'crop': crop})));

  @override
  Future<List<LoggableProduct>> loggable() async => (await _api.get('/v1/reviews/eligible') as List).map((e) => LoggableProduct.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<ReviewPrefill> prefill(String productId) async => ReviewPrefill.fromJson(_map(await _api.get('/v1/reviews/prefill/$productId')));

  @override
  Future<List<MyLog>> mine() async => (await _api.get('/v1/reviews/mine') as List).map((e) => MyLog.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<String> start(NewBaseline baseline) async {
    final json = _map(await _api.post('/v1/reviews', body: baseline.toJson()));
    return (json['coupon'] as Map<String, dynamic>)['code'] as String;
  }

  Future<void> _photo(String reviewId, String kind, Uint8List bytes) =>
      _api.postMultipart('/v1/reviews/$reviewId/photos/$kind', fields: const {}, files: [http.MultipartFile.fromBytes('file', bytes, filename: '$kind.jpg')]);

  @override
  Future<int> submitMid(String reviewId, MidNotes notes, {Uint8List? photo}) async {
    final json = _map(await _api.post('/v1/reviews/$reviewId/mid', body: notes.toJson()));
    if (photo != null) await _photo(reviewId, 'mid', photo);
    return (json['coins'] as num).toInt();
  }

  @override
  Future<HarvestResult> submitHarvest(String reviewId, HarvestInput input, {Uint8List? photo}) async {
    final json = _map(await _api.post('/v1/reviews/$reviewId/post', body: input.toJson()));
    if (photo != null) {
      // The harvest is already saved; a photo that fails to upload must not lose it.
      try {
        await _photo(reviewId, 'harvest', photo);
      } catch (_) {}
    }
    return HarvestResult.fromJson(json);
  }

  @override
  Future<Rewards> rewards() async => Rewards.fromJson(_map(await _api.get('/v1/reviews/rewards')));

  @override
  Future<int> redeem(int coins) async => ((_map(await _api.post('/v1/reviews/rewards/redeem', body: {'coins': coins})))['rupees'] as num).toInt();
}
