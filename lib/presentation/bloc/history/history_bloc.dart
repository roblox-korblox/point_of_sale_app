import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/order_service.dart';
import '../../../../data/models/order_model.dart';
import '../../../../core/constants/strings.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final OrderService _orderService;

  HistoryBloc({OrderService? orderService})
      : _orderService = orderService ?? OrderService(),
        super(HistoryInitial()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadHistoryByIdEvent>(_onLoadHistoryById);
  }

  Future<void> _onLoadHistory(
      LoadHistoryEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      List<OrderModel> orders;
      if (event.userId != null) {
        // Load user's orders
        orders = await _orderService.getOrdersByUserId(event.userId!);
      } else {
        // Load all completed orders (admin)
        orders = await _orderService.getCompletedOrdersSorted();
      }
      emit(HistoryLoaded(orders));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onLoadHistoryById(
      LoadHistoryByIdEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final order = await _orderService.getOrderById(event.orderId);
      if (order != null) {
        emit(HistoryDetailLoaded(order));
      } else {
        emit(const HistoryError(AppStrings.orderNotFound));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}

