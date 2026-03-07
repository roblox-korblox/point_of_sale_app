import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/transaction_model.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // Users
  static Future<Box> get usersBox async {
    if (!Hive.isBoxOpen('users')) {
      await Hive.openBox('users');
    }
    return Hive.box('users');
  }
  
  static Future<void> saveUsers(List<UserModel> users) async {
    final box = await usersBox;
    await box.clear();
    for (var user in users) {
      await box.put(user.id, user.toJson());
    }
  }
  
  static Future<List<UserModel>> getUsers() async {
    try {
      final box = await usersBox;
      return box.values.map((json) => UserModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<UserModel?> getUserById(String id) async {
    try {
      final box = await usersBox;
      final json = box.get(id);
      if (json != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<UserModel?> getUserByUsername(String username) async {
    try {
      final users = await getUsers();
      return users.firstWhere(
        (user) => user.username == username,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Products
  static Future<Box> get productsBox async {
    if (!Hive.isBoxOpen('products')) {
      await Hive.openBox('products');
    }
    return Hive.box('products');
  }
  
  static Future<void> saveProducts(List<ProductModel> products) async {
    final box = await productsBox;
    await box.clear();
    for (var product in products) {
      await box.put(product.id, product.toJson());
    }
  }
  
  static Future<List<ProductModel>> getProducts() async {
    try {
      final box = await productsBox;
      return box.values.map((json) => ProductModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<ProductModel?> getProductById(String id) async {
    try {
      final box = await productsBox;
      final json = box.get(id);
      if (json != null) {
        return ProductModel.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> saveProduct(ProductModel product) async {
    final box = await productsBox;
    await box.put(product.id, product.toJson());
  }
  
  static Future<void> deleteProduct(String id) async {
    final box = await productsBox;
    await box.delete(id);
  }

  // Orders
  static Future<Box> get ordersBox async {
    if (!Hive.isBoxOpen('orders')) {
      await Hive.openBox('orders');
    }
    return Hive.box('orders');
  }
  
  static Future<void> saveOrders(List<OrderModel> orders) async {
    final box = await ordersBox;
    await box.clear();
    for (var order in orders) {
      await box.put(order.id, order.toJson());
    }
  }
  
  static Future<List<OrderModel>> getOrders() async {
    try {
      final box = await ordersBox;
      return box.values.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<OrderModel?> getOrderById(String id) async {
    try {
      final box = await ordersBox;
      final json = box.get(id);
      if (json != null) {
        return OrderModel.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> saveOrder(OrderModel order) async {
    final box = await ordersBox;
    await box.put(order.id, order.toJson());
  }

  // Transactions
  static Future<Box> get transactionsBox async {
    if (!Hive.isBoxOpen('transactions')) {
      await Hive.openBox('transactions');
    }
    return Hive.box('transactions');
  }
  
  static Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final box = await transactionsBox;
    await box.clear();
    for (var transaction in transactions) {
      await box.put(transaction.id, transaction.toJson());
    }
  }
  
  static Future<List<TransactionModel>> getTransactions() async {
    try {
      final box = await transactionsBox;
      return box.values.map((json) => TransactionModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final box = await transactionsBox;
      final json = box.get(id);
      if (json != null) {
        return TransactionModel.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> saveTransaction(TransactionModel transaction) async {
    final box = await transactionsBox;
    await box.put(transaction.id, transaction.toJson());
  }
}

