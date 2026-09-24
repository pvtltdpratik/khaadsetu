import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../farmer/centers/domain/entities/nearby_center.dart';
import '../../data/delivery_api_repository.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) => DeliveryApiRepository(ref.watch(apiClientProvider)));

/// What a delivery would cost, asked again when the cart or place changes.
class QuoteArgs extends Equatable {
  const QuoteArgs({required this.items, required this.location, this.centerId});

  final List<CartLine> items;
  final FarmerLocation location;
  final String? centerId;

  @override
  List<Object?> get props => [items, location, centerId];
}

final deliveryQuoteProvider = FutureProvider.autoDispose.family<DeliveryQuote, QuoteArgs>(
  (ref, args) => ref.watch(deliveryRepositoryProvider).quote(items: args.items, location: args.location, centerId: args.centerId),
);

/// Following one order's delivery.
final deliveryTrackingProvider = FutureProvider.autoDispose.family<DeliveryTracking, String>(
  (ref, orderId) => ref.watch(deliveryRepositoryProvider).tracking(orderId),
);

// ---- being a partner ----

final partnerProfileProvider = FutureProvider.autoDispose<PartnerProfile>((ref) => ref.watch(deliveryRepositoryProvider).partner());
final partnerOffersProvider = FutureProvider.autoDispose<List<PartnerJob>>((ref) => ref.watch(deliveryRepositoryProvider).offers());
final partnerActiveProvider = FutureProvider.autoDispose<List<PartnerJob>>((ref) => ref.watch(deliveryRepositoryProvider).activeJobs());
final walletProvider = FutureProvider.autoDispose<Wallet>((ref) => ref.watch(deliveryRepositoryProvider).wallet());
final myTripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) => ref.watch(deliveryRepositoryProvider).myTrips());

// ---- loads ----

final myLoadsProvider = FutureProvider.autoDispose<List<DeliveryTracking>>((ref) => ref.watch(deliveryRepositoryProvider).myLoads());
final loadProvider = FutureProvider.autoDispose.family<DeliveryTracking, String>((ref, id) => ref.watch(deliveryRepositoryProvider).load(id));

class BoardArgs extends Equatable {
  const BoardArgs({required this.location, this.weightKg = 0});

  final FarmerLocation location;
  final double weightKg;

  @override
  List<Object?> get props => [location, weightKg];
}

final tripBoardProvider = FutureProvider.autoDispose.family<List<Trip>, BoardArgs>(
  (ref, args) => ref.watch(deliveryRepositoryProvider).tripBoard(location: args.location, weightKg: args.weightKg),
);
