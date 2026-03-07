import 'package:equatable/equatable.dart';
import 'product_model.dart';

class OrderItemModel extends Equatable {
  final String id;
  final ProductModel product;
  final int quantity;
  final int price; // Price at the time of order
  final int discount; // Discount at the time of order

  const OrderItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  int get subtotal => price * quantity;
  
  int get finalPrice {
    if (discount > 0) {
      return price - (price * discount ~/ 100);
    }
    return price;
  }
  
  int get total => finalPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'discount': discount,
    };
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      price: json['price'] as int,
      discount: json['discount'] as int? ?? 0,
    );
  }

  OrderItemModel copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    int? price,
    int? discount,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, price, discount];
}

