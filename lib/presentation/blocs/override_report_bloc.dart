import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/database/pos_database.dart';

class OverrideReportState extends Equatable {
  final DateTimeRange dateRange;
  final List<AuditLogWithActor> logs;
  final bool isLoading;

  const OverrideReportState({
    required this.dateRange,
    this.logs = const [],
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [dateRange, logs, isLoading];

  OverrideReportState copyWith({
    DateTimeRange? dateRange,
    List<AuditLogWithActor>? logs,
    bool? isLoading,
  }) {
    return OverrideReportState(
      dateRange: dateRange ?? this.dateRange,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

abstract class OverrideReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangeDateRange extends OverrideReportEvent {
  final DateTimeRange range;
  ChangeDateRange(this.range);
  @override
  List<Object?> get props => [range];
}

class OverrideReportBloc
    extends Bloc<OverrideReportEvent, OverrideReportState> {
  final PosDatabase _db;
  StreamSubscription? _sub;

  OverrideReportBloc(this._db)
    : super(
        OverrideReportState(
          dateRange: DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
        ),
      ) {
    on<ChangeDateRange>((event, emit) {
      emit(state.copyWith(dateRange: event.range, isLoading: true));
      _sub?.cancel();
      _sub = _db
          .watchOverrideLogs(start: event.range.start, end: event.range.end)
          .listen((logs) {
            add(_InternalUpdateLogs(logs));
          });
    });
    on<_InternalUpdateLogs>(
      (event, emit) => emit(state.copyWith(logs: event.logs, isLoading: false)),
    );

    add(ChangeDateRange(state.dateRange));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

class _InternalUpdateLogs extends OverrideReportEvent {
  final List<AuditLogWithActor> logs;
  _InternalUpdateLogs(this.logs);
}
