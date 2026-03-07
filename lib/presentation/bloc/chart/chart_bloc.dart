import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/transaction_service.dart';
import 'chart_event.dart';
import 'chart_state.dart';

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  final TransactionService _transactionService;

  ChartBloc({TransactionService? transactionService})
      : _transactionService = transactionService ?? TransactionService(),
        super(const ChartInitial()) {
    on<LoadChartDataEvent>(_onLoadChartData);
  }

  Future<void> _onLoadChartData(
      LoadChartDataEvent event, Emitter<ChartState> emit) async {
    emit(const ChartLoading());
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (event.period) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1, 0, 0, 0);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      }

      final income = await _transactionService.getIncomeByDateRange(startDate, endDate);
      final expense = await _transactionService.getExpenseByDateRange(startDate, endDate);
      final profit = await _transactionService.getProfitByDateRange(startDate, endDate);
      final loss = expense > income ? expense - income : 0;

      emit(ChartLoaded(
        income: income,
        expense: expense,
        profit: profit,
        loss: loss,
        period: event.period,
      ));
    } catch (e) {
      emit(ChartError(e.toString()));
    }
  }
}

