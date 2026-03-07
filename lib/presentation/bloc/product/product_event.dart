import 'package:equatable/equatable.dart';
import '../../../../data/models/product_model.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductEvent {
  const LoadProductsEvent();
}

class LoadProductsByCategoryEvent extends ProductEvent {
  final String category;

  const LoadProductsByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class AddProductEvent extends ProductEvent {
  final ProductModel product;

  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductEvent extends ProductEvent {
  final ProductModel product;

  const UpdateProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductEvent {
  final String productId;

  const DeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class SearchProductsEvent extends ProductEvent {
  final String query;

  const SearchProductsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

