import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../data/review_api_repository.dart';
import '../domain/review_models.dart';
import '../domain/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => ReviewApiRepository(ref.watch(apiClientProvider)));

final cropsProvider = FutureProvider.autoDispose<List<CropRef>>((ref) => ref.watch(reviewRepositoryProvider).crops());

typedef ProductReviewsKey = ({String productId, ReviewFilter filter});

final productReviewsProvider = FutureProvider.autoDispose.family<ProductReviews, ProductReviewsKey>((ref, key) => ref.watch(reviewRepositoryProvider).forProduct(key.productId, key.filter));

final loggableProvider = FutureProvider.autoDispose<List<LoggableProduct>>((ref) => ref.watch(reviewRepositoryProvider).loggable());
final prefillProvider = FutureProvider.autoDispose.family<ReviewPrefill, String>((ref, productId) => ref.watch(reviewRepositoryProvider).prefill(productId));
final myLogsProvider = FutureProvider.autoDispose<List<MyLog>>((ref) => ref.watch(reviewRepositoryProvider).mine());
final rewardsProvider = FutureProvider.autoDispose<Rewards>((ref) => ref.watch(reviewRepositoryProvider).rewards());
