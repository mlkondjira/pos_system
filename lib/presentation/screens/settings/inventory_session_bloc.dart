import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/database/pos_database.dart';

// --- Événements ---
abstract class InventorySessionEvent extends Equatable {
  const InventorySessionEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryLines extends InventorySessionEvent {
  final int sessionId;
  const LoadInventoryLines(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class UpdateSearchQuery extends InventorySessionEvent {
  final String query;
  const UpdateSearchQuery(this.query);
  @override
  List<Object?> get props => [query];
}

class UpdateFilter extends InventorySessionEvent {
  final String filter;
  const UpdateFilter(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ToggleScanner extends InventorySessionEvent {}

class ValidateSession extends InventorySessionEvent {
  final int sessionId;
  final int userId;
  const ValidateSession(this.sessionId, this.userId);
  @override
  List<Object?> get props => [sessionId, userId];
}

class UpdateCountedQuantity extends InventorySessionEvent {
  final int lineId;
  final int quantity;
  final String notes;
  final int defectiveQty;
  final int obsoleteQty;
  final int expiredQty;

  const UpdateCountedQuantity({
    required this.lineId,
    required this.quantity,
    this.notes = '',
    this.defectiveQty = 0,
    this.obsoleteQty = 0,
    this.expiredQty = 0,
  });

  @override
  List<Object?> get props => [
    lineId,
    quantity,
    notes,
    defectiveQty,
    obsoleteQty,
    expiredQty,
  ];
}

class _LinesUpdated extends InventorySessionEvent {
  final List<InventoryLine> lines;
  const _LinesUpdated(this.lines);
  @override
  List<Object?> get props => [lines];
}

// --- État ---
class InventorySessionState extends Equatable {
  final List<InventoryLine> lines;
  final String filter;
  final String searchQuery;
  final bool showScanner;
  final bool isValidating;
  final String? errorMessage;
  final bool isSuccess;

  const InventorySessionState({
    this.lines = const [],
    this.filter = 'all',
    this.searchQuery = '',
    this.showScanner = false,
    this.isValidating = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  InventorySessionState copyWith({
    List<InventoryLine>? lines,
    String? filter,
    String? searchQuery,
    bool? showScanner,
    bool? isValidating,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return InventorySessionState(
      lines: lines ?? this.lines,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      showScanner: showScanner ?? this.showScanner,
      isValidating: isValidating ?? this.isValidating,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
    lines,
    filter,
    searchQuery,
    showScanner,
    isValidating,
    errorMessage,
    isSuccess,
  ];
}

// --- Bloc ---
class InventorySessionBloc
    extends Bloc<InventorySessionEvent, InventorySessionState> {
  final PosDatabase _db;
  StreamSubscription? _subscription;

  InventorySessionBloc(this._db) : super(const InventorySessionState()) {
    on<LoadInventoryLines>(_onLoadLines);
    on<_LinesUpdated>(
      (event, emit) => emit(state.copyWith(lines: event.lines)),
    );
    on<UpdateSearchQuery>(
      (event, emit) => emit(state.copyWith(searchQuery: event.query)),
    );
    on<UpdateFilter>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<ToggleScanner>(
      (event, emit) => emit(state.copyWith(showScanner: !state.showScanner)),
    );
    on<UpdateCountedQuantity>(_onUpdateQuantity);
    on<ValidateSession>(_onValidateSession);
  }

  Future<void> _onLoadLines(
    LoadInventoryLines event,
    Emitter<InventorySessionState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _db
        .watchInventoryLines(event.sessionId)
        .listen((lines) => add(_LinesUpdated(lines)));
  }

  Future<void> _onUpdateQuantity(
    UpdateCountedQuantity event,
    Emitter<InventorySessionState> emit,
  ) async {
    await _db.updateInventoryLine(
      lineId: event.lineId,
      countedQty: event.quantity,
      defectiveQty: event.defectiveQty,
      obsoleteQty: event.obsoleteQty,
      expiredQty: event.expiredQty,
      notes: event.notes,
    );
  }

  Future<void> _onValidateSession(
    ValidateSession event,
    Emitter<InventorySessionState> emit,
  ) async {
    emit(state.copyWith(isValidating: true));
    try {
      await _db.validateInventorySession(
        sessionId: event.sessionId,
        userId: event.userId,
      );
      emit(state.copyWith(isValidating: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isValidating: false, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
