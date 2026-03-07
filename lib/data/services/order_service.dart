import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../storage/storage_service.dart';

class OrderService {

  Future<List<OrderModel>> getOrders() async {
    try {
      return await StorageService.getOrders();
    } catch (e) {
      return [];
    }
  }

  /// Get orders by user ID
  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    try {
      final orders = await StorageService.getOrders();
      return orders
          .where((order) => order.userId == userId && order.status == 'completed')
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get completed orders sorted by date (newest first)
  Future<List<OrderModel>> getCompletedOrdersSorted() async {
    try {
      final orders = await getCompletedOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      return [];
    }
  }

  Future<OrderModel?> getOrderById(String id) async {
    try {
      return await StorageService.getOrderById(id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveOrder(OrderModel order) async {
    try {
      await StorageService.saveOrder(order);
      // Stock reduction is handled in TransactionService.createTransactionFromOrder
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<OrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final orders = await StorageService.getOrders();
      return orders
          .where((order) =>
              order.createdAt.isAfter(startDate) &&
              order.createdAt.isBefore(endDate))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<OrderModel>> getCompletedOrders() async {
    try {
      final orders = await StorageService.getOrders();
      return orders.where((order) => order.status == 'completed').toList();
    } catch (e) {
      return [];
    }
  }

  int calculateTotal(List<OrderItemModel> items) {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}

