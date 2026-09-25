import 'dart:typed_data';

import 'package:khaadsetu_version1/features/reviews/domain/review_models.dart';
import 'package:khaadsetu_version1/features/reviews/domain/review_repository.dart';

const soybean = CropRef(name: 'Soybean', msp: 5328, districtAvgQpa: 9.2);
const cotton = CropRef(name: 'Cotton', msp: 7710, districtAvgQpa: 4.5);

ReviewCard aCard(String id, {String farmer = 'Ramesh from Yavatmal', double gain = 33.3, String comment = 'पिकाचा रंग बदलला.', bool agronomist = false, bool featured = false, String soil = 'black'}) => ReviewCard(
      reviewId: id,
      farmer: farmer,
      crop: 'Soybean',
      variety: 'JS 335',
      soilType: soil,
      acres: 3,
      irrigation: 'rainfed',
      season: 'kharif-2026',
      qtyPerAcre: 25,
      unit: '40 kg bag',
      growthStage: 'vegetative',
      method: 'broadcasting',
      npkBefore: 'N low / P medium / K medium',
      scoreBefore: 48,
      yieldQpa: 11.2,
      lastSeasonQpa: 8.4,
      districtAvgQpa: 9.2,
      improvementPct: gain,
      scoreAfter: 61,
      starsOverall: 5,
      starsValue: 4,
      starsEase: 5,
      useAgain: 'yes',
      comment: comment,
      hasMidPhoto: true,
      agronomistReviewed: agronomist,
      featured: featured,
    );

const goodSummary = ReviewSummary(
  count: 4,
  overall: 4.2,
  improvementAvg: 18.4,
  bestLine: 'Black cotton soil + Soybean + Kharif season',
  topRatedFor: ['Value for money', 'Easy to apply'],
  watchOutFor: ['Less effective on sandy soil'],
);

MyLog aLog(String id, {int phase = 1, int mid = 0, int harvest = 0, String status = 'phase1', double? yieldQpa, double? gain, bool featured = false}) => MyLog(
      reviewId: id,
      productName: 'Vermicompost',
      crop: 'Soybean',
      season: 'kharif-2026',
      status: status,
      phase: phase,
      midOpensInDays: mid,
      harvestOpensInDays: harvest,
      yieldQpa: yieldQpa,
      improvementPct: gain,
      featured: featured,
    );

final usableCoupon = Coupon(code: 'SAMRUDHI-A1B2C3', percent: 5, source: 'Baseline logged', used: false, expired: false, expiresAt: DateTime(2030, 1, 1));

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({
    this.reviews = const ProductReviews(summary: ReviewSummary(count: 0), reviews: [], matching: 0),
    this.prefillData = const ReviewPrefill(eligible: true, acres: 3, soilType: 'black', irrigation: 'rainfed', district: 'Yavatmal', crops: ['Soybean'], scan: ScanSnapshot(score: 48, n: 'low', p: 'medium', k: 'medium'), cropNames: ['Soybean', 'Cotton', 'Wheat']),
    this.logs = const [],
    this.loggableProducts = const [LoggableProduct(productId: 'p-vermicompost', name: 'Vermicompost', unit: '40 kg bag', logs: [])],
    this.rewardsData = const Rewards(coins: 0, coinBatch: 100, coinBatchRupees: 25, badges: [], coupons: [], streak: 0),
    this.cropList = const [soybean, cotton],
    this.prediction = const YieldPrediction(lowPct: 15, highPct: 22, message: 'On your 2-acre black-soil soybean farm we expect 15% to 22% more yield with Vermicompost.', disclaimer: 'Based on 6 farmers with your crop and soil type.', basis: 'reviews', sampleSize: 6, baselineQpa: 9.2, extraLow: 2.8, extraHigh: 4.0),
  });

  ProductReviews reviews;
  ReviewPrefill prefillData;
  List<MyLog> logs;
  List<LoggableProduct> loggableProducts;
  Rewards rewardsData;
  List<CropRef> cropList;
  YieldPrediction prediction;
  Object? startError;
  Object? harvestError;
  HarvestResult harvestResult = const HarvestResult(earned: ['50 coins', 'the Verified Farmer badge'], streak: 1, status: 'published', improvementPct: 33.3);

  final filters = <ReviewFilter>[];
  final started = <NewBaseline>[];
  final mids = <({String id, MidNotes notes, Uint8List? photo})>[];
  final harvests = <({String id, HarvestInput input, Uint8List? photo})>[];
  final predictCalls = <({String productId, double acres, String crop})>[];
  final redeemed = <int>[];

  @override
  Future<List<CropRef>> crops() async => cropList;

  @override
  Future<ProductReviews> forProduct(String productId, ReviewFilter filter) async {
    filters.add(filter);
    return reviews;
  }

  @override
  Future<YieldPrediction> predict({required String productId, required double acres, required String crop}) async {
    predictCalls.add((productId: productId, acres: acres, crop: crop));
    return prediction;
  }

  @override
  Future<List<LoggableProduct>> loggable() async => loggableProducts;

  @override
  Future<ReviewPrefill> prefill(String productId) async => prefillData;

  @override
  Future<List<MyLog>> mine() async => logs;

  @override
  Future<String> start(NewBaseline baseline) async {
    if (startError != null) throw startError!;
    started.add(baseline);
    return 'SAMRUDHI-A1B2C3';
  }

  @override
  Future<int> submitMid(String reviewId, MidNotes notes, {Uint8List? photo}) async {
    mids.add((id: reviewId, notes: notes, photo: photo));
    return 10;
  }

  @override
  Future<HarvestResult> submitHarvest(String reviewId, HarvestInput input, {Uint8List? photo}) async {
    if (harvestError != null) throw harvestError!;
    harvests.add((id: reviewId, input: input, photo: photo));
    return harvestResult;
  }

  @override
  Future<Rewards> rewards() async => rewardsData;

  @override
  Future<int> redeem(int coins) async {
    redeemed.add(coins);
    return coins ~/ 100 * 25;
  }
}
