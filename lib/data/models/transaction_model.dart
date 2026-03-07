import 'package:equatable/equatable.dart';
import 'order_model.dart';

class TransactionModel extends Equatable {
  final String id;
  final OrderModel order;
  final int income; // Total income from this transaction
  final int expense; // Cost of goods sold (can be calculated later)
  final int profit; // income - expense
  final DateTime createdAt;
  final String? userId;

  const TransactionModel({
    required this.id,
    required this.order,
    required this.income,
    this.expense = 0,
    required this.profit,
    required this.createdAt,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order.toJson(),
      'income': income,
      'expense': expense,
      'profit': profit,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      order: OrderModel.fromJson(json['order'] as Map<String, dynamic>),
      income: json['income'] as int,
      expense: json['expense'] as int? ?? 0,
      profit: json['profit'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    OrderModel? order,
    int? income,
    int? expense,
    int? profit,
    DateTime? createdAt,
    String? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      order: order ?? this.order,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        order,
        income,
        expense,
        profit,
        createdAt,
        userId,
      ];
}

