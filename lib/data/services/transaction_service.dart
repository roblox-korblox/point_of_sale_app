import '../models/transaction_model.dart';
import '../models/order_model.dart';
import '../storage/storage_service.dart';
import 'product_service.dart';

class TransactionService {
  final ProductService _productService = ProductService();

  Future<List<TransactionModel>> getTransactions() async {
    try {
      return await StorageService.getTransactions();
    } catch (e) {
      return [];
    }
  }

  /// Get transactions by user ID
  Future<List<TransactionModel>> getTransactionsByUserId(String userId) async {
    try {
      final transactions = await StorageService.getTransactions();
      return transactions
          .where((transaction) => transaction.userId == userId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      return await StorageService.getTransactionById(id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveTransaction(TransactionModel transaction) async {
    try {
      await StorageService.saveTransaction(transaction);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await StorageService.getTransactions();
      return transactions
          .where((transaction) =>
              transaction.createdAt.isAfter(startDate) &&
              transaction.createdAt.isBefore(endDate))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getIncomeByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<TransactionModel> transactions = await getTransactionsByDateRange(startDate, endDate);
      int total = 0;
      for (final transaction in transactions) {
        total = total + transaction.income;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getExpenseByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<TransactionModel> transactions = await getTransactionsByDateRange(startDate, endDate);
      int total = 0;
      for (final transaction in transactions) {
        total = total + transaction.expense;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getProfitByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<TransactionModel> transactions = await getTransactionsByDateRange(startDate, endDate);
      int total = 0;
      for (final transaction in transactions) {
        total = total + transaction.profit;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<TransactionModel> createTransactionFromOrder(
      OrderModel order) async {
    // Reduce stock for all items in the order
    for (var item in order.items) {
      await _productService.updateProductStock(
        item.product.id,
        item.quantity,
      );
    }

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      order: order,
      income: order.total,
      expense: 0, // Can be calculated later
      profit: order.total, // income - expense
      createdAt: DateTime.now(),
      userId: order.userId,
    );

    await saveTransaction(transaction);
    return transaction;
  }

  /// Get sold products for today
  Future<List<Map<String, dynamic>>> getSoldProductsToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final transactions = await getTransactionsByDateRange(startOfDay, endOfDay);
      final Map<String, Map<String, dynamic>> soldProductsMap = {};

      for (var transaction in transactions) {
        for (var item in transaction.order.items) {
          final productId = item.product.id;
          if (soldProductsMap.containsKey(productId)) {
            final currentQuantity = soldProductsMap[productId]!['quantity'] as int;
            final currentTotal = soldProductsMap[productId]!['total'] as int;
            soldProductsMap[productId] = {
              'product': item.product,
              'quantity': currentQuantity + item.quantity,
              'total': currentTotal + item.total,
            };
          } else {
            soldProductsMap[productId] = {
              'product': item.product,
              'quantity': item.quantity,
              'total': item.total,
            };
          }
        }
      }

      return soldProductsMap.values.toList();
    } catch (e) {
      return [];
    }
  }
}

