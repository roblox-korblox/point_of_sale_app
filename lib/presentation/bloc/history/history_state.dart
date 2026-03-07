import 'package:equatable/equatable.dart';
import '../../../../data/models/order_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<OrderModel> orders;

  const HistoryLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class HistoryDetailLoaded extends HistoryState {
  final OrderModel order;

  const HistoryDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}


