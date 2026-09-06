import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_fake_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._dataSource);

  final InventoryFakeDataSource _dataSource;

  @override
  Future<List<InventoryItem>> getItems() => _dataSource.fetchItems();
}
