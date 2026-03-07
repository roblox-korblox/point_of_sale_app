import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransactionSuccess extends TransactionState {
  final TransactionModel transaction;
  final String message;

  const TransactionSuccess({
    required this.transaction,
    required this.message,
  });

  @override
  List<Object?> get props => [transaction, message];
}

