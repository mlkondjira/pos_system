import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/database/pos_database.dart';

// --- Events ---
abstract class AuditLogEvent extends Equatable {
  const AuditLogEvent();
  @override
  List<Object> get props => [];
}

class LoadAuditLogs extends AuditLogEvent {}

// --- State ---
class AuditLogState extends Equatable {
  final List<AuditLogWithActor> logs;
  final bool isLoading;

  const AuditLogState({this.logs = const [], this.isLoading = false});

  AuditLogState copyWith({List<AuditLogWithActor>? logs, bool? isLoading}) {
    return AuditLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [logs, isLoading];
}

// --- Bloc ---
class AuditLogBloc extends Bloc<AuditLogEvent, AuditLogState> {
  final PosDatabase _db;

  AuditLogBloc(this._db) : super(const AuditLogState()) {
    on<LoadAuditLogs>(_onLoadAuditLogs);
  }

  Future<void> _onLoadAuditLogs(
    LoadAuditLogs event,
    Emitter<AuditLogState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      _db.watchAuditLogs(),
      onData: (logs) => state.copyWith(logs: logs, isLoading: false),
      onError: (_, _) => state.copyWith(isLoading: false),
    );
  }
}
