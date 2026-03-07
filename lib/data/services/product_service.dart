import '../models/product_model.dart';
import '../storage/storage_service.dart';

class ProductService {
  Future<List<ProductModel>> getProducts() async {
    try {
      return await StorageService.getProducts();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final products = await StorageService.getProducts();
      return products.where((p) => p.category == category).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      return await StorageService.getProductById(id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProduct(ProductModel product) async {
    try {
      await StorageService.saveProduct(product);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await StorageService.deleteProduct(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final products = await StorageService.getProducts();
      return products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update product stock (reduce stock when order is completed)
  Future<bool> updateProductStock(String productId, int quantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        return false;
      }

      final newStock = product.stock - quantity;
      final updatedProduct = product.copyWith(
        stock: newStock < 0 ? 0 : newStock,
        isOutOfStock: newStock <= 0,
        updatedAt: DateTime.now(),
      );

      return await saveProduct(updatedProduct);
    } catch (e) {
      return false;
    }
  }

  /// Reduce stock for multiple products (used when order is completed)
  Future<bool> reduceStockForOrder(List<Map<String, dynamic>> items) async {
    try {
      for (var item in items) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;
        await updateProductStock(productId, quantity);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

