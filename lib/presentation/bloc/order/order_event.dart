import 'package:equatable/equatable.dart';
import '../../../../data/models/product_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrderEvent {
  const LoadOrdersEvent();
}

class AddToCartEvent extends OrderEvent {
  final ProductModel product;
  final int quantity;

  const AddToCartEvent({
    required this.product,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCartEvent extends OrderEvent {
  final String productId;

  const RemoveFromCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateCartItemQuantityEvent extends OrderEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCartEvent extends OrderEvent {
  const ClearCartEvent();
}

class CreateOrderEvent extends OrderEvent {
  final String paymentMethod;
  final String? userId;

  const CreateOrderEvent({
    required this.paymentMethod,
    this.userId,
  });

  @override
  List<Object?> get props => [paymentMethod, userId];
}

class LoadCurrentCartEvent extends OrderEvent {
  const LoadCurrentCartEvent();
}

