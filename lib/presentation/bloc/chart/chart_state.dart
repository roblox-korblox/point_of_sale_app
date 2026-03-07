import 'package:equatable/equatable.dart';

abstract class ChartState extends Equatable {
  const ChartState();

  @override
  List<Object?> get props => [];
}

class ChartInitial extends ChartState {
  const ChartInitial();
}

class ChartLoading extends ChartState {
  const ChartLoading();
}

class ChartLoaded extends ChartState {
  final int income;
  final int expense;
  final int profit;
  final int loss;
  final String period;

  const ChartLoaded({
    required this.income,
    required this.expense,
    required this.profit,
    required this.loss,
    required this.period,
  });

  @override
  List<Object?> get props => [income, expense, profit, loss, period];
}

class ChartError extends ChartState {
  final String message;

  const ChartError(this.message);

  @override
  List<Object?> get props => [message];
}

