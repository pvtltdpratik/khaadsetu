import '../../../../../core/network/api_client.dart';
import '../../../soil_health/domain/entities/nutrient_reading.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';

class MarketplaceApiDataSource {
  const MarketplaceApiDataSource(this._api);

  final ApiClient _api;

  Future<List<Product>> fetchProducts() async {
    final list = await _api.get('/v1/products') as List;
    return list.map((e) => _parseProduct(e as Map<String, dynamic>)).toList();
  }

  Future<Product> fetchProductById(String id) async {
    return _parseProduct(await _api.get('/v1/products/$id') as Map<String, dynamic>);
  }

  Future<List<ProductReview>> fetchReviews(String productId) async {
    final list = await _api.get('/v1/products/$productId/reviews') as List;
    return list.map((e) => _parseReview(e as Map<String, dynamic>)).toList();
  }

  Product _parseProduct(Map<String, dynamic> json) {
    final npk = json['npkPercentages'] as Map<String, dynamic>;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: ProductCategory.values.byName(json['category'] as String),
      priceInRupees: (json['priceInRupees'] as num).toDouble(),
      unitLabel: json['unitLabel'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      description: json['description'] as String,
      nutrientFocus: (json['nutrientFocus'] as List)
          .map((n) => NutrientType.values.byName(n as String))
          .toList(),
      npkPercentages: {
        for (final e in npk.entries) NutrientType.values.byName(e.key): (e.value as num).toDouble(),
      },
    );
  }

  ProductReview _parseReview(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
    );
  }
}
