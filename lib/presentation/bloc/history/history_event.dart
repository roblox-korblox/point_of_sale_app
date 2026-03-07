import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {
  final String? userId; // If null, load all orders (admin), if not null, load user's orders

  const LoadHistoryEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadHistoryByIdEvent extends HistoryEvent {
  final String orderId;

  const LoadHistoryByIdEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}


