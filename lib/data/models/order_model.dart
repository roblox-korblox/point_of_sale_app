import 'package:equatable/equatable.dart';
import 'order_item_model.dart';

class OrderModel extends Equatable {
  final String id;
  final List<OrderItemModel> items;
  final int total;
  final String paymentMethod; // 'cash' or 'qrcode'
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? userId;

  const OrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
    this.userId,
  });

  int get subtotal {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalDiscount {
    return items.fold(0, (sum, item) => sum + (item.subtotal - item.total));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      userId: json['userId'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    List<OrderItemModel>? items,
    int? total,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? userId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        total,
        paymentMethod,
        status,
        createdAt,
        completedAt,
        userId,
      ];
}

