import '../../domain/entities/farmer_profile.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../datasources/farmer_fake_data_source.dart';

class FarmerRepositoryImpl implements FarmerRepository {
  const FarmerRepositoryImpl(this._dataSource);

  final FarmerFakeDataSource _dataSource;

  @override
  Future<FarmerProfile> getProfile() => _dataSource.fetchProfile();
}
