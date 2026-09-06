import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/earnings_fake_data_source.dart';
import '../../data/repositories/earnings_repository_impl.dart';
import '../../domain/repositories/earnings_repository.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepositoryImpl(EarningsFakeDataSource());
});

final commissionRateProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(earningsRepositoryProvider).getCommissionRatePercent();
});
