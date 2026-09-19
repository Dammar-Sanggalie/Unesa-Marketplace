class PriceResult {
  final double fairPriceMin;
  final double fairPriceMax;
  final double quickSaleMin;
  final double quickSaleMax;
  final double basePrice;
  final String? imageUrl;
  final List<Map<String, dynamic>> similarItems;

  PriceResult({
    required this.fairPriceMin,
    required this.fairPriceMax,
    required this.quickSaleMin,
    required this.quickSaleMax,
    required this.basePrice,
    this.imageUrl,
    required this.similarItems,
  });
}
