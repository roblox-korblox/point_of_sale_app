import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/transaction_service.dart';
import '../../../../core/constants/strings.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionService _transactionService;

  TransactionBloc({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService(),
        super(const TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<CreateTransactionEvent>(_onCreateTransaction);
    on<LoadTransactionsByDateRangeEvent>(_onLoadTransactionsByDateRange);
  }

  Future<void> _onLoadTransactions(
      LoadTransactionsEvent event, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());
    try {
      final transactions = await _transactionService.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onCreateTransaction(
      CreateTransactionEvent event, Emitter<TransactionState> emit) async {
    try {
      final transaction =
          await _transactionService.createTransactionFromOrder(event.order);
      emit(TransactionSuccess(
        transaction: transaction,
        message: AppStrings.success,
      ));
      add(const LoadTransactionsEvent());
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadTransactionsByDateRange(
      LoadTransactionsByDateRangeEvent event,
      Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());
    try {
      final transactions = await _transactionService.getTransactionsByDateRange(
        event.startDate,
        event.endDate,
      );
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}

