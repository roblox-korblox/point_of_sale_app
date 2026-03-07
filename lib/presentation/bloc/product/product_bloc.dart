import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/product_service.dart';
import '../../../../core/constants/strings.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _productService;

  ProductBloc({ProductService? productService})
      : _productService = productService ?? ProductService(),
        super(const ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadProductsByCategoryEvent>(_onLoadProductsByCategory);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<SearchProductsEvent>(_onSearchProducts);
  }

  Future<void> _onLoadProducts(
      LoadProductsEvent event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());
    try {
      final products = await _productService.getProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadProductsByCategory(
      LoadProductsByCategoryEvent event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());
    try {
      final products = await _productService.getProductsByCategory(event.category);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onAddProduct(
      AddProductEvent event, Emitter<ProductState> emit) async {
    try {
      final success = await _productService.saveProduct(event.product);
      if (success) {
        emit(const ProductSuccess(AppStrings.productAdded));
        add(const LoadProductsEvent());
      } else {
        emit(const ProductError(AppStrings.failed));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProductEvent event, Emitter<ProductState> emit) async {
    try {
      final success = await _productService.saveProduct(event.product);
      if (success) {
        emit(const ProductSuccess(AppStrings.productUpdated));
        add(const LoadProductsEvent());
      } else {
        emit(const ProductError(AppStrings.failed));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProductEvent event, Emitter<ProductState> emit) async {
    try {
      final success = await _productService.deleteProduct(event.productId);
      if (success) {
        emit(const ProductSuccess(AppStrings.productDeleted));
        add(const LoadProductsEvent());
      } else {
        emit(const ProductError(AppStrings.failed));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onSearchProducts(
      SearchProductsEvent event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());
    try {
      final products = await _productService.searchProducts(event.query);
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}

