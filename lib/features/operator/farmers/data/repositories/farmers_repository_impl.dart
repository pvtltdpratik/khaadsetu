import '../../domain/entities/farmer.dart';
import '../../domain/repositories/farmers_repository.dart';
import '../datasources/farmers_api_data_source.dart';

class FarmersRepositoryImpl implements FarmersRepository {
  const FarmersRepositoryImpl(this._dataSource);

  final FarmersApiDataSource _dataSource;

  @override
  Future<List<Farmer>> getFarmers() => _dataSource.fetchFarmers();

  @override
  Future<Farmer> getFarmerById(String id) => _dataSource.fetchFarmerById(id);
}
