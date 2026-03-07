import 'package:equatable/equatable.dart';
import 'category_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final int price;
  final int stock;
  final bool isAvailable;
  final bool isOutOfStock;
  final int discount; // Percentage
  final String? imagePath;
  final String? description;
  final String category; // 'food' or 'drink'
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isAvailable = true,
    this.isOutOfStock = false,
    this.discount = 0,
    this.imagePath,
    this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  int get finalPrice {
    if (discount > 0) {
      return price - (price * discount ~/ 100);
    }
    return price;
  }

  bool get hasDiscount => discount > 0;

  ProductCategory get categoryEnum => ProductCategoryExtension.fromString(category);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'isAvailable': isAvailable,
      'isOutOfStock': isOutOfStock,
      'discount': discount,
      'imagePath': imagePath,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
      discount: json['discount'] as int? ?? 0,
      imagePath: json['imagePath'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    bool? isAvailable,
    bool? isOutOfStock,
    int? discount,
    String? imagePath,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      discount: discount ?? this.discount,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        stock,
        isAvailable,
        isOutOfStock,
        discount,
        imagePath,
        description,
        category,
        createdAt,
        updatedAt,
      ];
}

