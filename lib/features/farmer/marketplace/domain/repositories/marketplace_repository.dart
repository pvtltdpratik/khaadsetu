import '../entities/product.dart';
import '../entities/product_review.dart';

abstract class MarketplaceRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<List<ProductReview>> getReviews(String productId);
}
