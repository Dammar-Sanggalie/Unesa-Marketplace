class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String? imageUrl;
  final bool isSold;
  final String? location;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    this.imageUrl,
    this.isSold = false,
    this.location,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sellerId: json['seller_id'],
      title: json['title'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      condition: json['condition'],
      imageUrl: json['image_url'],
      isSold: json['is_sold'] ?? false,
      location: json['location'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_sold': isSold,
      if (location != null) 'location': location,
    };
  }
}
