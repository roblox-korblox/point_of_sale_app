import 'package:equatable/equatable.dart';
import '../../../../data/models/order_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  const LoadTransactionsEvent();
}

class CreateTransactionEvent extends TransactionEvent {
  final OrderModel order;

  const CreateTransactionEvent(this.order);

  @override
  List<Object?> get props => [order];
}

class LoadTransactionsByDateRangeEvent extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadTransactionsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

