import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/earnings_api_data_source.dart';
import '../../data/repositories/earnings_repository_impl.dart';
import '../../domain/repositories/earnings_repository.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepositoryImpl(EarningsApiDataSource(ref.watch(apiClientProvider)));
});

final commissionRateProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(earningsRepositoryProvider).getCommissionRatePercent();
});
