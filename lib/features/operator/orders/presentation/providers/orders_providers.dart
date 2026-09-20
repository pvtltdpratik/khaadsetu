import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/orders_api_data_source.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

/// Plain (non-`autoDispose`) `Provider` — the underlying data source is
/// backed by the on-device database now, but stays a single instance for
/// the app's lifetime so its one-time seed check doesn't repeat needlessly.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(OrdersApiDataSource(ref.watch(apiClientProvider)));
});

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

final orderProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getOrderById(id);
});
