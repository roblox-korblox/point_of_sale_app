enum ProductCategory {
  food, // Makanan
  drink, // Minuman
}

extension ProductCategoryExtension on ProductCategory {
  String get name {
    switch (this) {
      case ProductCategory.food:
        return 'Makanan';
      case ProductCategory.drink:
        return 'Minuman';
    }
  }
  
  String get value {
    switch (this) {
      case ProductCategory.food:
        return 'food';
      case ProductCategory.drink:
        return 'drink';
    }
  }
  
  static ProductCategory fromString(String value) {
    switch (value) {
      case 'food':
        return ProductCategory.food;
      case 'drink':
        return ProductCategory.drink;
      default:
        return ProductCategory.food;
    }
  }
}

