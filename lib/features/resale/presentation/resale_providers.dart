import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../data/resale_api_repository.dart';
import '../domain/resale_models.dart';
import '../domain/resale_repository.dart';

final resaleRepositoryProvider = Provider<ResaleRepository>((ref) => ResaleApiRepository(ref.watch(apiClientProvider)));

// ---- the farmer ----
final eligibleProductsProvider = FutureProvider.autoDispose<List<EligibleProduct>>((ref) => ref.watch(resaleRepositoryProvider).eligible());
final myListingsProvider = FutureProvider.autoDispose<List<ResaleListing>>((ref) => ref.watch(resaleRepositoryProvider).mine());
final myListingProvider = FutureProvider.autoDispose.family<ResaleListing, String>((ref, id) => ref.watch(resaleRepositoryProvider).listing(id));
final farmerWalletProvider = FutureProvider.autoDispose<WalletState>((ref) => ref.watch(resaleRepositoryProvider).wallet());

// ---- the village center ----
final resaleQueueProvider = FutureProvider.autoDispose.family<List<ResaleListing>, List<ResaleStatus>>((ref, statuses) => ref.watch(resaleRepositoryProvider).queue(statuses: statuses));
final cashDueProvider = FutureProvider.autoDispose<List<PayoutDue>>((ref) => ref.watch(resaleRepositoryProvider).cashDue());

// ---- the platform ----
final resaleDisputesProvider = FutureProvider.autoDispose<List<ResaleDispute>>((ref) => ref.watch(resaleRepositoryProvider).disputes(status: 'open'));
final upiPayoutsProvider = FutureProvider.autoDispose<List<PayoutDue>>((ref) => ref.watch(resaleRepositoryProvider).upiPayouts());

/// The three groups the village center works through.
const resaleToReview = [ResaleStatus.pendingVerification, ResaleStatus.inspectionRequired];
const resaleOnSale = [ResaleStatus.live, ResaleStatus.awaitingHandover];
const resaleAtCenter = [ResaleStatus.listed];

/// Every status but drafts: for looking one listing up. A const list, so it is the same provider key every time
/// (a fresh list on each build would be a new provider each time, and the screen would load forever).
const resaleEveryStatus = [
  ResaleStatus.pendingVerification,
  ResaleStatus.inspectionRequired,
  ResaleStatus.live,
  ResaleStatus.awaitingHandover,
  ResaleStatus.listed,
  ResaleStatus.soldOut,
  ResaleStatus.rejected,
  ResaleStatus.withdrawn,
];
