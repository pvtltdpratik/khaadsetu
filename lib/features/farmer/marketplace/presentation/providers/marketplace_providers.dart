import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../soil_health/domain/entities/nutrient_reading.dart';
import '../../../soil_health/presentation/providers/soil_health_providers.dart';
import '../../data/datasources/marketplace_fake_data_source.dart';
import '../../data/repositories/marketplace_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';
import '../../domain/repositories/marketplace_repository.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl(MarketplaceFakeDataSource());
});

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(marketplaceRepositoryProvider).getProducts();
});

final productProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) {
  return ref.watch(marketplaceRepositoryProvider).getProductById(id);
});

final productReviewsProvider =
    FutureProvider.autoDispose.family<List<ProductReview>, String>((ref, productId) {
  return ref.watch(marketplaceRepositoryProvider).getReviews(productId);
});

/// Nutrients the farmer's latest soil scan flagged as low — used to badge
/// matching products as "Matches your soil". Reads `soil_health`'s public
/// providers only, never its data source directly, so this stays correct if
/// soil_health's implementation changes.
final deficientNutrientsProvider = FutureProvider.autoDispose<Set<NutrientType>>((ref) async {
  final summary = await ref.watch(soilHealthSummaryProvider.future);
  final scanId = summary.scanId;
  if (scanId == null) return {};
  final scan = await ref.watch(soilScanResultProvider(scanId).future);
  return scan.nutrients
      .where((n) => n.level == NutrientLevel.low)
      .map((n) => n.type)
      .toSet();
});
