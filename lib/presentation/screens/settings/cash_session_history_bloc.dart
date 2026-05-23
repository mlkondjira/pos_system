import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../data/database/pos_database.dart';

// --- Events ---
abstract class CashHistoryEvent extends Equatable {
  const CashHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadCashHistory extends CashHistoryEvent {}

class DateRangeChanged extends CashHistoryEvent {
  final DateTimeRange? range;
  const DateRangeChanged(this.range);
  @override
  List<Object?> get props => [range];
}

// --- State ---
class CashHistoryState extends Equatable {
  final List<CashSessionWithUser> sessions;
  final bool isLoading;
  final String? error;
  final DateTimeRange? dateRange;

  const CashHistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.dateRange,
  });

  CashHistoryState copyWith({
    List<CashSessionWithUser>? sessions,
    bool? isLoading,
    String? error,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
  }) {
    return CashHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dateRange: clearDateRange ? null : dateRange ?? this.dateRange,
    );
  }

  @override
  List<Object?> get props => [sessions, isLoading, error, dateRange];
}

// --- Bloc ---
class CashHistoryBloc extends Bloc<CashHistoryEvent, CashHistoryState> {
  final PosDatabase _db;

  CashHistoryBloc(this._db) : super(const CashHistoryState()) {
    on<LoadCashHistory>(_onLoadHistory);
    on<DateRangeChanged>(_onDateRangeChanged);
  }

  Future<void> _onLoadHistory(
    LoadCashHistory event,
    Emitter<CashHistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      _db.watchAllCashSessions(range: state.dateRange),
      onData: (sessions) =>
          state.copyWith(sessions: sessions, isLoading: false),
      onError: (e, _) => state.copyWith(isLoading: false, error: e.toString()),
    );
  }

  void _onDateRangeChanged(
    DateRangeChanged event,
    Emitter<CashHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        dateRange: event.range,
        clearDateRange: event.range == null,
      ),
    );
    add(LoadCashHistory());
  }
}
