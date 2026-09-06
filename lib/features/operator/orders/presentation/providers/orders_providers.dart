import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/orders_fake_data_source.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

/// Plain (non-`autoDispose`) `Provider` so the fake data source's in-memory
/// orders persist across navigation.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(OrdersFakeDataSource());
});

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).getOrders();
});

final orderProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getOrderById(id);
});
