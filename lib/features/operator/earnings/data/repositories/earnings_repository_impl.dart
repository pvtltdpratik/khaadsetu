import '../../domain/repositories/earnings_repository.dart';
import '../datasources/earnings_fake_data_source.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  const EarningsRepositoryImpl(this._dataSource);

  final EarningsFakeDataSource _dataSource;

  @override
  Future<double> getCommissionRatePercent() => _dataSource.fetchCommissionRatePercent();
}
