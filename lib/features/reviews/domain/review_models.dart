import 'package:equatable/equatable.dart';

/// A choice the farmer taps: the value the server stores, and the words shown.
class Choice {
  const Choice(this.api, this.label);

  final String api;
  final String label;
}

const soilChoices = [Choice('black', 'Black cotton'), Choice('red', 'Red'), Choice('alluvial', 'Alluvial'), Choice('laterite', 'Laterite'), Choice('sandy', 'Sandy'), Choice('other', 'Other')];
const stageChoices = [Choice('sowing', 'Sowing'), Choice('vegetative', 'Vegetative'), Choice('flowering', 'Flowering'), Choice('pod_filling', 'Pod filling')];
const methodChoices = [Choice('broadcasting', 'Broadcasting'), Choice('banding', 'Banding'), Choice('foliar_spray', 'Foliar spray'), Choice('drip', 'Drip')];
const reasonChoices = [Choice('app_recommendation', 'App recommendation'), Choice('operator_suggested', 'Center suggested'), Choice('seen_in_community', 'Seen in community'), Choice('used_before', 'Used before')];
const irrigationChoices = [Choice('rainfed', 'Rain-fed'), Choice('well', 'Well'), Choice('borewell', 'Borewell'), Choice('canal', 'Canal'), Choice('drip', 'Drip'), Choice('sprinkler', 'Sprinkler')];

String labelOf(List<Choice> choices, String? api) => choices.firstWhere((c) => c.api == api, orElse: () => Choice(api ?? '', api ?? '')).label;

/// A crop with its reference numbers, for the forms and the calculator.
class CropRef extends Equatable {
  const CropRef({required this.name, required this.msp, required this.districtAvgQpa});

  factory CropRef.fromJson(Map<String, dynamic> json) => CropRef(name: json['name'] as String, msp: (json['msp'] as num).toDouble(), districtAvgQpa: (json['districtAvgQpa'] as num).toDouble());

  final String name;

  /// Rupees per quintal (the Minimum Support Price, or a typical market price where there is none). Indicative.
  final double msp;

  /// A typical district average yield, quintals per acre. Indicative.
  final double districtAvgQpa;

  @override
  List<Object?> get props => [name, msp, districtAvgQpa];
}

/// The nutrient levels and score from the latest soil scan.
class ScanSnapshot extends Equatable {
  const ScanSnapshot({required this.score, required this.n, required this.p, required this.k});

  factory ScanSnapshot.fromJson(Map<String, dynamic> json) {
    final npk = json['npk'] as Map<String, dynamic>;
    return ScanSnapshot(score: (json['score'] as num).toInt(), n: npk['n'] as String, p: npk['p'] as String, k: npk['k'] as String);
  }

  final int score;
  final String n;
  final String p;
  final String k;

  @override
  List<Object?> get props => [score, n, p, k];
}

/// What the app already knows, so the farmer only fills in what is new.
class ReviewPrefill extends Equatable {
  const ReviewPrefill({required this.eligible, required this.acres, required this.soilType, required this.irrigation, required this.district, required this.crops, required this.scan, required this.cropNames});

  factory ReviewPrefill.fromJson(Map<String, dynamic> json) => ReviewPrefill(
        eligible: json['eligible'] as bool? ?? false,
        acres: (json['acres'] as num?)?.toDouble(),
        soilType: json['soilType'] as String?,
        irrigation: json['irrigation'] as String?,
        district: (json['district'] as String?) ?? '',
        crops: ((json['crops'] as List?) ?? const []).cast<String>(),
        scan: json['scan'] == null ? null : ScanSnapshot.fromJson(json['scan'] as Map<String, dynamic>),
        cropNames: ((json['cropNames'] as List?) ?? const []).cast<String>(),
      );

  final bool eligible;
  final double? acres;
  final String? soilType;
  final String? irrigation;
  final String district;
  final List<String> crops;
  final ScanSnapshot? scan;
  final List<String> cropNames;

  @override
  List<Object?> get props => [eligible, acres, soilType, irrigation, district, crops, scan, cropNames];
}

/// A fertilizer the farmer collected and can log, with what they have logged already.
class LoggableProduct extends Equatable {
  const LoggableProduct({required this.productId, required this.name, required this.unit, required this.logs});

  factory LoggableProduct.fromJson(Map<String, dynamic> json) => LoggableProduct(
        productId: json['productId'] as String,
        name: json['name'] as String,
        unit: (json['unit'] as String?) ?? '',
        logs: ((json['logs'] as List?) ?? const []).map((e) => (e as Map<String, dynamic>)['crop'] as String).toList(),
      );

  final String productId;
  final String name;
  final String unit;

  /// Crops already logged this season for this product.
  final List<String> logs;

  @override
  List<Object?> get props => [productId, name, unit, logs];
}

class NewBaseline extends Equatable {
  const NewBaseline({required this.productId, required this.acres, required this.crop, required this.growthStage, required this.qtyPerAcre, required this.method, required this.reason, this.variety = '', this.irrigation});

  final String productId;
  final double acres;
  final String crop;
  final String variety;
  final String growthStage;
  final String? irrigation;
  final double qtyPerAcre;
  final String method;
  final String reason;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'acres': acres,
        'crop': crop,
        if (variety.isNotEmpty) 'variety': variety,
        'growthStage': growthStage,
        if (irrigation != null) 'irrigation': irrigation,
        'qtyPerAcre': qtyPerAcre,
        'method': method,
        'reason': reason,
      };

  @override
  List<Object?> get props => [productId, acres, crop, variety, growthStage, irrigation, qtyPerAcre, method, reason];
}

class MidNotes extends Equatable {
  const MidNotes({required this.colorChange, required this.leafHealth, required this.pestDisease, required this.soilFeel, this.pestNote = '', this.unexpected = ''});

  final String colorChange;
  final String leafHealth;
  final bool pestDisease;
  final String soilFeel;
  final String pestNote;
  final String unexpected;

  Map<String, dynamic> toJson() => {
        'colorChange': colorChange,
        'leafHealth': leafHealth,
        'pestDisease': pestDisease,
        'soilFeel': soilFeel,
        if (pestNote.isNotEmpty) 'pestNote': pestNote,
        if (unexpected.isNotEmpty) 'unexpected': unexpected,
      };

  @override
  List<Object?> get props => [colorChange, leafHealth, pestDisease, soilFeel, pestNote, unexpected];
}

class HarvestInput extends Equatable {
  const HarvestInput({required this.yieldQpa, required this.starsOverall, required this.starsValue, required this.starsEase, required this.useAgain, required this.recommend, this.lastSeasonQpa, this.comment = ''});

  final double yieldQpa;
  final double? lastSeasonQpa;
  final int starsOverall;
  final int starsValue;
  final int starsEase;
  final String useAgain;
  final bool recommend;
  final String comment;

  Map<String, dynamic> toJson() => {
        'yieldQpa': yieldQpa,
        if (lastSeasonQpa != null) 'lastSeasonQpa': lastSeasonQpa,
        'starsOverall': starsOverall,
        'starsValue': starsValue,
        'starsEase': starsEase,
        'useAgain': useAgain,
        'recommend': recommend,
        if (comment.isNotEmpty) 'comment': comment,
      };

  @override
  List<Object?> get props => [yieldQpa, lastSeasonQpa, starsOverall, starsValue, starsEase, useAgain, recommend, comment];
}

/// One of my own logs, and what it is waiting for.
class MyLog extends Equatable {
  const MyLog({
    required this.reviewId,
    required this.productName,
    required this.crop,
    required this.season,
    required this.status,
    required this.phase,
    required this.midOpensInDays,
    required this.harvestOpensInDays,
    this.yieldQpa,
    this.improvementPct,
    this.flagReason = '',
    this.featured = false,
  });

  factory MyLog.fromJson(Map<String, dynamic> json) => MyLog(
        reviewId: json['reviewId'] as String,
        productName: (json['productName'] as String?) ?? '',
        crop: json['crop'] as String,
        season: json['season'] as String,
        status: json['status'] as String,
        phase: (json['phase'] as num).toInt(),
        midOpensInDays: (json['midOpensInDays'] as num).toInt(),
        harvestOpensInDays: (json['harvestOpensInDays'] as num).toInt(),
        yieldQpa: (json['yieldQpa'] as num?)?.toDouble(),
        improvementPct: (json['improvementPct'] as num?)?.toDouble(),
        flagReason: (json['flagReason'] as String?) ?? '',
        featured: json['featured'] as bool? ?? false,
      );

  final String reviewId;
  final String productName;
  final String crop;
  final String season;

  /// 'phase1', 'phase2', 'flagged', 'published' or 'hidden'.
  final String status;

  /// How far along: 1 baseline, 2 mid-season notes, 3 harvest.
  final int phase;
  final int midOpensInDays;
  final int harvestOpensInDays;
  final double? yieldQpa;
  final double? improvementPct;
  final String flagReason;
  final bool featured;

  bool get harvestLogged => phase == 3;

  @override
  List<Object?> get props => [reviewId, productName, crop, season, status, phase, midOpensInDays, harvestOpensInDays, yieldQpa, improvementPct, flagReason, featured];
}

class Coupon extends Equatable {
  const Coupon({required this.code, required this.percent, required this.source, required this.used, required this.expired, required this.expiresAt});

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'] as String,
        percent: (json['percent'] as num).toDouble(),
        source: (json['source'] as String?) ?? '',
        used: json['used'] as bool? ?? false,
        expired: json['expired'] as bool? ?? false,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
      );

  final String code;
  final double percent;
  final String source;
  final bool used;
  final bool expired;
  final DateTime expiresAt;

  bool get usable => !used && !expired;

  @override
  List<Object?> get props => [code, percent, source, used, expired, expiresAt];
}

class Rewards extends Equatable {
  const Rewards({required this.coins, required this.coinBatch, required this.coinBatchRupees, required this.badges, required this.coupons, required this.streak, this.priorityUntil});

  factory Rewards.fromJson(Map<String, dynamic> json) => Rewards(
        coins: (json['coins'] as num).toInt(),
        coinBatch: (json['coinBatch'] as num).toInt(),
        coinBatchRupees: (json['coinBatchRupees'] as num).toInt(),
        badges: ((json['badges'] as List?) ?? const []).map((e) => (e as Map<String, dynamic>)['badge'] as String).toList(),
        coupons: ((json['coupons'] as List?) ?? const []).map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList(),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        priorityUntil: json['priorityUntil'] == null ? null : DateTime.parse(json['priorityUntil'] as String).toLocal(),
      );

  final int coins;
  final int coinBatch;
  final int coinBatchRupees;
  final List<String> badges;
  final List<Coupon> coupons;
  final int streak;
  final DateTime? priorityUntil;

  List<Coupon> get usableCoupons => coupons.where((c) => c.usable).toList();
  bool get verifiedFarmer => badges.contains('verified_farmer');
  bool get champion => badges.contains('champion_farmer');

  @override
  List<Object?> get props => [coins, coinBatch, coinBatchRupees, badges, coupons, streak, priorityUntil];
}

/// What a finished harvest log earned.
class HarvestResult extends Equatable {
  const HarvestResult({required this.earned, required this.streak, required this.status, this.improvementPct, this.districtAvgQpa});

  factory HarvestResult.fromJson(Map<String, dynamic> json) => HarvestResult(
        earned: ((json['earned'] as List?) ?? const []).cast<String>(),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        status: ((json['review'] as Map<String, dynamic>?)?['status'] as String?) ?? 'published',
        improvementPct: (json['improvementPct'] as num?)?.toDouble(),
        districtAvgQpa: (json['districtAvgQpa'] as num?)?.toDouble(),
      );

  final List<String> earned;
  final int streak;
  final String status;
  final double? improvementPct;
  final double? districtAvgQpa;

  bool get heldForCheck => status == 'flagged';

  @override
  List<Object?> get props => [earned, streak, status, improvementPct, districtAvgQpa];
}

class ReviewSummary extends Equatable {
  const ReviewSummary({required this.count, this.overall, this.improvementAvg, this.bestLine, this.topRatedFor = const [], this.watchOutFor = const []});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final best = json['best'] as Map<String, dynamic>?;
    return ReviewSummary(
      count: (json['count'] as num).toInt(),
      overall: (json['overall'] as num?)?.toDouble(),
      improvementAvg: (json['improvementAvg'] as num?)?.toDouble(),
      bestLine: best == null ? null : '${labelOf(soilChoices, best['soil'] as String)} soil + ${best['crop']} + ${_cap(best['season'] as String)} season',
      topRatedFor: ((json['topRatedFor'] as List?) ?? const []).cast<String>(),
      watchOutFor: ((json['watchOutFor'] as List?) ?? const []).cast<String>(),
    );
  }

  final int count;
  final double? overall;
  final double? improvementAvg;
  final String? bestLine;
  final List<String> topRatedFor;
  final List<String> watchOutFor;

  @override
  List<Object?> get props => [count, overall, improvementAvg, bestLine, topRatedFor, watchOutFor];
}

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// One farmer's outcome, as another farmer reads it.
class ReviewCard extends Equatable {
  const ReviewCard({
    required this.reviewId,
    required this.farmer,
    required this.crop,
    required this.soilType,
    required this.acres,
    required this.irrigation,
    required this.season,
    required this.qtyPerAcre,
    required this.unit,
    required this.growthStage,
    required this.method,
    required this.starsOverall,
    required this.useAgain,
    required this.agronomistReviewed,
    required this.featured,
    this.variety = '',
    this.npkBefore,
    this.scoreBefore,
    this.yieldQpa,
    this.lastSeasonQpa,
    this.districtAvgQpa,
    this.improvementPct,
    this.scoreAfter,
    this.starsValue,
    this.starsEase,
    this.comment = '',
    this.hasMidPhoto = false,
    this.hasHarvestPhoto = false,
  });

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    final npk = json['npkBefore'] as Map<String, dynamic>?;
    return ReviewCard(
      reviewId: json['reviewId'] as String,
      farmer: json['farmer'] as String,
      crop: json['crop'] as String,
      variety: (json['variety'] as String?) ?? '',
      soilType: json['soilType'] as String,
      acres: (json['acres'] as num).toDouble(),
      irrigation: json['irrigation'] as String,
      season: json['season'] as String,
      qtyPerAcre: (json['qtyPerAcre'] as num).toDouble(),
      unit: (json['unit'] as String?) ?? '',
      growthStage: json['growthStage'] as String,
      method: json['method'] as String,
      npkBefore: npk == null ? null : '${_lvl('N', npk['n'])} / ${_lvl('P', npk['p'])} / ${_lvl('K', npk['k'])}',
      scoreBefore: (json['scoreBefore'] as num?)?.toInt(),
      yieldQpa: (json['yieldQpa'] as num?)?.toDouble(),
      lastSeasonQpa: (json['lastSeasonQpa'] as num?)?.toDouble(),
      districtAvgQpa: (json['districtAvgQpa'] as num?)?.toDouble(),
      improvementPct: (json['improvementPct'] as num?)?.toDouble(),
      scoreAfter: (json['scoreAfter'] as num?)?.toInt(),
      starsOverall: (json['starsOverall'] as num?)?.toInt() ?? 0,
      starsValue: (json['starsValue'] as num?)?.toInt(),
      starsEase: (json['starsEase'] as num?)?.toInt(),
      useAgain: (json['useAgain'] as String?) ?? '',
      comment: (json['comment'] as String?) ?? '',
      hasMidPhoto: json['hasMidPhoto'] as bool? ?? false,
      hasHarvestPhoto: json['hasHarvestPhoto'] as bool? ?? false,
      agronomistReviewed: json['agronomistReviewed'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
    );
  }

  static String _lvl(String nutrient, Object? level) => '$nutrient ${(level as String?) ?? '?'}';

  final String reviewId;
  final String farmer;
  final String crop;
  final String variety;
  final String soilType;
  final double acres;
  final String irrigation;
  final String season;
  final double qtyPerAcre;
  final String unit;
  final String growthStage;
  final String method;
  final String? npkBefore;
  final int? scoreBefore;
  final double? yieldQpa;
  final double? lastSeasonQpa;
  final double? districtAvgQpa;
  final double? improvementPct;
  final int? scoreAfter;
  final int starsOverall;
  final int? starsValue;
  final int? starsEase;
  final String useAgain;
  final String comment;
  final bool hasMidPhoto;
  final bool hasHarvestPhoto;
  final bool agronomistReviewed;
  final bool featured;

  @override
  List<Object?> get props => [reviewId, farmer, crop, soilType, acres, season, yieldQpa, improvementPct, starsOverall, comment, agronomistReviewed, featured];
}

class ProductReviews extends Equatable {
  const ProductReviews({required this.summary, required this.reviews, required this.matching});

  factory ProductReviews.fromJson(Map<String, dynamic> json) => ProductReviews(
        summary: ReviewSummary.fromJson(json['summary'] as Map<String, dynamic>),
        reviews: ((json['reviews'] as List?) ?? const []).map((e) => ReviewCard.fromJson(e as Map<String, dynamic>)).toList(),
        matching: (json['matching'] as num).toInt(),
      );

  final ReviewSummary summary;
  final List<ReviewCard> reviews;
  final int matching;

  @override
  List<Object?> get props => [summary, reviews, matching];
}

/// The filters on a product's reviews.
class ReviewFilter extends Equatable {
  const ReviewFilter({this.soil, this.crop, this.season, this.size, this.improved = false});

  final String? soil;
  final String? crop;
  final String? season;
  final String? size;
  final bool improved;

  ReviewFilter copyWith({Object? soil = _keep, Object? crop = _keep, Object? season = _keep, Object? size = _keep, bool? improved}) => ReviewFilter(
        soil: identical(soil, _keep) ? this.soil : soil as String?,
        crop: identical(crop, _keep) ? this.crop : crop as String?,
        season: identical(season, _keep) ? this.season : season as String?,
        size: identical(size, _keep) ? this.size : size as String?,
        improved: improved ?? this.improved,
      );

  static const _keep = Object();

  bool get isEmpty => soil == null && crop == null && season == null && size == null && !improved;

  @override
  List<Object?> get props => [soil, crop, season, size, improved];
}

/// "On your 2-acre soybean farm we expect 15% to 22% more yield."
class YieldPrediction extends Equatable {
  const YieldPrediction({required this.lowPct, required this.highPct, required this.message, required this.disclaimer, required this.basis, required this.sampleSize, required this.baselineQpa, required this.extraLow, required this.extraHigh});

  factory YieldPrediction.fromJson(Map<String, dynamic> json) {
    final extra = json['expectedExtraQuintals'] as Map<String, dynamic>;
    return YieldPrediction(
      lowPct: (json['lowPct'] as num).toInt(),
      highPct: (json['highPct'] as num).toInt(),
      message: json['message'] as String,
      disclaimer: json['disclaimer'] as String,
      basis: json['basis'] as String,
      sampleSize: (json['sampleSize'] as num).toInt(),
      baselineQpa: (json['baselineQpa'] as num).toDouble(),
      extraLow: (extra['low'] as num).toDouble(),
      extraHigh: (extra['high'] as num).toDouble(),
    );
  }

  final int lowPct;
  final int highPct;
  final String message;
  final String disclaimer;

  /// 'reviews' (other farmers' results) or 'agronomy' (an early estimate from how the product works).
  final String basis;
  final int sampleSize;
  final double baselineQpa;
  final double extraLow;
  final double extraHigh;

  bool get fromFarmers => basis == 'reviews';

  @override
  List<Object?> get props => [lowPct, highPct, message, disclaimer, basis, sampleSize, baselineQpa, extraLow, extraHigh];
}
