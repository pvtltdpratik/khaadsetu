import 'dart:typed_data';

import 'review_models.dart';

abstract class ReviewRepository {
  Future<List<CropRef>> crops();

  // ---- what other farmers see ----
  Future<ProductReviews> forProduct(String productId, ReviewFilter filter);
  Future<YieldPrediction> predict({required String productId, required double acres, required String crop});

  // ---- my log ----
  Future<List<LoggableProduct>> loggable();
  Future<ReviewPrefill> prefill(String productId);
  Future<List<MyLog>> mine();

  /// Phase 1. Returns the coupon code the farmer earned.
  Future<String> start(NewBaseline baseline);
  Future<int> submitMid(String reviewId, MidNotes notes, {Uint8List? photo});
  Future<HarvestResult> submitHarvest(String reviewId, HarvestInput input, {Uint8List? photo});

  // ---- rewards ----
  Future<Rewards> rewards();
  Future<int> redeem(int coins);
}
