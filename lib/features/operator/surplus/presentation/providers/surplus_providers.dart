import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../data/surplus_api_repository.dart';
import '../../domain/entities/surplus_lot.dart';
import '../../domain/repositories/surplus_repository.dart';

final surplusRepositoryProvider = Provider<SurplusRepository>((ref) => SurplusApiRepository(ref.watch(apiClientProvider)));

final surplusLotsProvider = FutureProvider.autoDispose<List<SurplusLot>>((ref) => ref.watch(surplusRepositoryProvider).lots());

/// Marking units down (or withdrawing a lot) moves stock between the shelf and
/// the lot, so both lists can be stale afterwards.
void refreshSurplus(WidgetRef ref) {
  ref
    ..invalidate(surplusLotsProvider)
    ..invalidate(inventoryItemsProvider);
}
