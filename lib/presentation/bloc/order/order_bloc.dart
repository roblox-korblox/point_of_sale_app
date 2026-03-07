import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../data/services/order_service.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/order_item_model.dart';
import '../../../../core/constants/strings.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;
  List<OrderItemModel> _cartItems = [];

  OrderBloc({OrderService? orderService})
      : _orderService = orderService ?? OrderService(),
        super(const OrderInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<CreateOrderEvent>(_onCreateOrder);
    on<LoadCurrentCartEvent>(_onLoadCurrentCart);
  }

  Future<void> _onLoadOrders(
      LoadOrdersEvent event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      final orders = await _orderService.getOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onAddToCart(
      AddToCartEvent event, Emitter<OrderState> emit) async {
    try {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (existingIndex >= 0) {
        final existingItem = _cartItems[existingIndex];
        _cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + event.quantity,
        );
      } else {
        final orderItem = OrderItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: event.product,
          quantity: event.quantity,
          price: event.product.price,
          discount: event.product.discount,
        );
        _cartItems.add(orderItem);
      }

      await _saveCartToStorage();
      _emitCartState(emit);
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCartEvent event, Emitter<OrderState> emit) async {
    try {
      _cartItems.removeWhere((item) => item.product.id == event.productId);
      await _saveCartToStorage();
      _emitCartState(emit);
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onUpdateCartItemQuantity(
      UpdateCartItemQuantityEvent event, Emitter<OrderState> emit) async {
    try {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        if (event.quantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index] = _cartItems[index].copyWith(
            quantity: event.quantity,
          );
        }
        await _saveCartToStorage();
        _emitCartState(emit);
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onClearCart(
      ClearCartEvent event, Emitter<OrderState> emit) async {
    try {
      _cartItems.clear();
      await _saveCartToStorage();
      _emitCartState(emit);
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCreateOrder(
      CreateOrderEvent event, Emitter<OrderState> emit) async {
    emit(const OrderLoading());
    try {
      if (_cartItems.isEmpty) {
        emit(const OrderError(AppStrings.emptyCart));
        return;
      }

      final total = _orderService.calculateTotal(_cartItems);
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: List.from(_cartItems),
        total: total,
        paymentMethod: event.paymentMethod,
        status: 'completed',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        userId: event.userId,
      );

      final success = await _orderService.saveOrder(order);
      if (success) {
        _cartItems.clear();
        await _saveCartToStorage();
        emit(OrderSuccess(
          order: order,
          message: AppStrings.orderSuccess,
        ));
      } else {
        emit(const OrderError(AppStrings.orderFailed));
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onLoadCurrentCart(
      LoadCurrentCartEvent event, Emitter<OrderState> emit) async {
    try {
      await _loadCartFromStorage();
      _emitCartState(emit);
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  void _emitCartState(Emitter<OrderState> emit) {
    final total = _orderService.calculateTotal(_cartItems);
    emit(CartLoaded(
      cartItems: List.from(_cartItems),
      total: total,
    ));
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _cartItems.map((item) => item.toJson()).toList();
      await prefs.setString('current_cart', jsonEncode(cartJson));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('current_cart');
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _cartItems = decoded
            .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _cartItems = [];
    }
  }
}

