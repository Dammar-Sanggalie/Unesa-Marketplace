import '../../models/price_result.dart';

class PriceCalculator {
  // This is a mock calculator for MVP purposes.
  // In a real scenario, this would call a backend API that uses machine learning or a larger dataset.
  static PriceResult calculatePrice({
    required String category,
    required String brand,
    required String model,
    required int year,
    required int condition,
    required Map<String, dynamic> specs,
  }) {
    // Base mock prices based on brand/model (simplified for MVP)
    double basePrice = 3000000;
    
    if (brand.toLowerCase() == 'asus' && model.toLowerCase().contains('vivobook')) {
      basePrice = 4500000;
    } else if (brand.toLowerCase() == 'apple' && model.toLowerCase().contains('iphone 13')) {
      basePrice = 6000000;
    }

    // Depreciation based on year (Assume current year is 2026)
    int age = 2026 - year;
    if (age > 0) {
      basePrice = basePrice * (1 - (age * 0.1)); // 10% depreciation per year
    }

    // Condition modifier (1 to 10)
    // 10 is like new, 5 is average.
    double conditionModifier = condition / 10.0;
    basePrice = basePrice * conditionModifier;

    // Specs modifier (example RAM/SSD for laptops)
    if (specs.containsKey('ram')) {
      int ram = specs['ram'];
      if (ram > 8) basePrice += 500000;
    }

    // Ensure price doesn't drop too low
    if (basePrice < 500000) basePrice = 500000;

    // Calculate ranges
    double fairPriceMin = basePrice * 0.9;
    double fairPriceMax = basePrice * 1.1;

    double quickSaleMin = basePrice * 0.8;
    double quickSaleMax = basePrice * 0.88;

    return PriceResult(
      fairPriceMin: fairPriceMin,
      fairPriceMax: fairPriceMax,
      quickSaleMin: quickSaleMin,
      quickSaleMax: quickSaleMax,
      basePrice: basePrice,
      imageUrl: specs['imageUrl'],
      similarItems: _getMockSimilarItems(basePrice),
    );
  }

  static List<Map<String, dynamic>> _getMockSimilarItems(double calculatedBase) {
    // Generate some mock comparison data around the base price
    return [
      {'price': calculatedBase * 0.95, 'condition': 'Mirip'},
      {'price': calculatedBase * 1.02, 'condition': 'Sama'},
      {'price': calculatedBase * 1.05, 'condition': 'Lebih bagus sedikit'},
      {'price': calculatedBase * 1.08, 'condition': 'Fullset'},
    ];
  }
}
