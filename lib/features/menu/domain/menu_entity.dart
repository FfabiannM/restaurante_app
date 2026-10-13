class Dish {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final int calories;
  final bool isFavorite;
  final bool isAvailable;

  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.price = 15.0,
    this.category = 'Plato Fuerte',
    this.calories = 650,
    this.isFavorite = false,
    this.isAvailable = true,
  });

  Dish copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? category,
    int? calories,
    bool? isFavorite,
    bool? isAvailable,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? 'assets/silpancho.png',
      price: (json['price'] as num?)?.toDouble() ?? 15.0,
      category: json['category'] ?? 'Plato Fuerte',
      calories: (json['calories'] as num?)?.toInt() ?? 650,
      isFavorite: json['is_favorite'] == true || json['isFavorite'] == true,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'category': category,
      'calories': calories,
      'is_favorite': isFavorite,
      'is_available': isAvailable,
    };
  }
}
