import 'package:equatable/equatable.dart';

abstract class ChartEvent extends Equatable {
  const ChartEvent();

  @override
  List<Object?> get props => [];
}

class LoadChartDataEvent extends ChartEvent {
  final String period; // 'today', 'week', 'month', 'year'

  const LoadChartDataEvent(this.period);

  @override
  List<Object?> get props => [period];
}

