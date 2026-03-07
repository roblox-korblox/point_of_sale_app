import 'package:equatable/equatable.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/order_item_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderLoaded extends OrderState {
  final List<OrderModel> orders;

  const OrderLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class CartLoaded extends OrderState {
  final List<OrderItemModel> cartItems;
  final int total;

  const CartLoaded({
    required this.cartItems,
    required this.total,
  });

  @override
  List<Object?> get props => [cartItems, total];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderSuccess extends OrderState {
  final OrderModel order;
  final String message;

  const OrderSuccess({
    required this.order,
    required this.message,
  });

  @override
  List<Object?> get props => [order, message];
}

