import '../../../soil_health/domain/entities/nutrient_reading.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_review.dart';

/// Stands in for a remote catalog/reviews API.
class MarketplaceFakeDataSource {
  static final List<Product> _products = [
    const Product(
      id: 'p-vermicompost',
      name: 'Vermicompost',
      brand: 'HaritBhoomi',
      category: ProductCategory.organic,
      priceInRupees: 450,
      unitLabel: '40 kg bag',
      rating: 4.7,
      reviewCount: 340,
      description: 'Builds organic matter and soil structure over time. A '
          'gentle, slow-release option that\'s safe to combine with any '
          'other fertilizer.',
      nutrientFocus: [NutrientType.nitrogen],
      npkPercentages: {
        NutrientType.nitrogen: 1,
        NutrientType.phosphorus: 0.5,
        NutrientType.potassium: 0.5,
      },
    ),
    const Product(
      id: 'p-neemcake',
      name: 'Neem Cake',
      brand: 'KisanShield',
      category: ProductCategory.organic,
      priceInRupees: 600,
      unitLabel: '25 kg bag',
      rating: 4.1,
      reviewCount: 58,
      description: 'Organic soil conditioner with natural pest-deterrent '
          'properties. Works well mixed into soil before sowing.',
      nutrientFocus: [NutrientType.nitrogen],
      npkPercentages: {NutrientType.nitrogen: 2},
    ),
    const Product(
      id: 'p-wheatseed',
      name: 'Hybrid Wheat Seeds HD-2967',
      brand: 'SafalKheti',
      category: ProductCategory.seed,
      priceInRupees: 85,
      unitLabel: 'per kg',
      rating: 4.4,
      reviewCount: 150,
      description: 'High-yield, disease-resistant wheat variety suited to '
          'irrigated conditions. Recommended seed rate: 100 kg/acre.',
      nutrientFocus: [],
      npkPercentages: {},
    ),
    const Product(
      id: 'p-biopesticide',
      name: 'Bio-Pesticide Spray',
      brand: 'KisanShield',
      category: ProductCategory.pesticide,
      priceInRupees: 320,
      unitLabel: '1 L bottle',
      rating: 3.9,
      reviewCount: 65,
      description: 'Neem-oil based spray for common leaf-eating pests. '
          'Safer for beneficial insects than broad-spectrum chemicals.',
      nutrientFocus: [],
      npkPercentages: {},
    ),
    const Product(
      id: 'p-sprayer',
      name: 'Hand Sprayer 5L',
      brand: 'AgroVeda',
      category: ProductCategory.equipment,
      priceInRupees: 650,
      unitLabel: 'per unit',
      rating: 4.3,
      reviewCount: 90,
      description: 'Durable manual compression sprayer for pesticide and '
          'foliar fertilizer application, with an adjustable nozzle.',
      nutrientFocus: [],
      npkPercentages: {},
    ),
  ];

  static const _reviewerNames = [
    'Sunil P.', 'Anita K.', 'Ravindra J.', 'Meera S.', 'Vikram D.', 'Lakshmi N.',
  ];

  static const _commentTemplates = [
    'Good results after one season of use. Will buy again.',
    'Reasonably priced compared to what the local shop sells.',
    'Worked well, though delivery to my village took a while.',
    'My neighbor recommended this — glad I tried it.',
    'Does the job, nothing extraordinary but reliable.',
    'Noticed a clear improvement within a couple of weeks.',
  ];

  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.unmodifiable(_products);
  }

  Future<Product> fetchProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _products.firstWhere((p) => p.id == id);
  }

  Future<List<ProductReview>> fetchReviews(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final seed = productId.hashCode.abs();
    return List.generate(3, (i) {
      final nameIndex = (seed + i) % _reviewerNames.length;
      final commentIndex = (seed + i * 2) % _commentTemplates.length;
      final rating = 3 + (seed + i) % 3;
      return ProductReview(
        id: '$productId-review-$i',
        authorName: _reviewerNames[nameIndex],
        rating: rating,
        comment: _commentTemplates[commentIndex],
        date: DateTime.now().subtract(Duration(days: 5 + i * 12)),
      );
    });
  }
}
