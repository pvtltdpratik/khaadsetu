import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/orders_api_repository.dart';
import '../../domain/entities/farmer_order.dart';
import '../../domain/repositories/orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersApiRepository(ref.watch(apiClientProvider)));

final myOrdersProvider = FutureProvider.autoDispose<List<FarmerOrder>>((ref) => ref.watch(ordersRepositoryProvider).myOrders());

final orderProvider = FutureProvider.autoDispose.family<FarmerOrder, String>((ref, id) => ref.watch(ordersRepositoryProvider).order(id));
