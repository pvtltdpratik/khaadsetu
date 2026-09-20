import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_api_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this._dataSource);

  final MarketplaceApiDataSource _dataSource;

  @override
  Future<List<Product>> getProducts() => _dataSource.fetchProducts();

  @override
  Future<Product> getProductById(String id) => _dataSource.fetchProductById(id);

  @override
  Future<List<ProductReview>> getReviews(String productId) =>
      _dataSource.fetchReviews(productId);
}
