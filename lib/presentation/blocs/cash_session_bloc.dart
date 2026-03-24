import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database/pos_database.dart';

// --- Events ---
abstract class CashSessionEvent extends Equatable {
  const CashSessionEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends CashSessionEvent {}

class OpenSession extends CashSessionEvent {
  final double startingCash;
  final int userId;
  const OpenSession({required this.startingCash, required this.userId});
  @override
  List<Object?> get props => [startingCash, userId];
}

class CloseSession extends CashSessionEvent {
  final double countedCash;
  final String? notes;
  const CloseSession({required this.countedCash, this.notes});
  @override
  List<Object?> get props => [countedCash, notes];
}

// --- States ---
abstract class CashSessionState extends Equatable {
  const CashSessionState();
  @override
  List<Object?> get props => [];
}

class CashSessionInitial extends CashSessionState {}
class CashSessionLoading extends CashSessionState {}
class NoCashSession extends CashSessionState {}
class CashSessionOpen extends CashSessionState {
  final CashSession session;
  const CashSessionOpen(this.session);
  @override
  List<Object?> get props => [session];
}

// --- Bloc ---
class CashSessionBloc extends Bloc<CashSessionEvent, CashSessionState> {
  final PosDatabase _db;

  CashSessionBloc(this._db) : super(CashSessionInitial()) {
    on<AppStarted>(_onAppStarted);
    on<OpenSession>(_onOpenSession);
    on<CloseSession>(_onCloseSession);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<CashSessionState> emit) async {
    emit(CashSessionLoading());
    final session = await _db.getCurrentOpenSession();
    if (session != null) {
      emit(CashSessionOpen(session));
    } else {
      emit(NoCashSession());
    }
  }

  Future<void> _onOpenSession(OpenSession event, Emitter<CashSessionState> emit) async {
    emit(CashSessionLoading());
    final sessionId = await _db.openCashSession(userId: event.userId, startingCash: event.startingCash);
    final session = await (_db.select(_db.cashSessions)..where((c) => c.id.equals(sessionId))).getSingle();
    emit(CashSessionOpen(session));
  }

  Future<void> _onCloseSession(CloseSession event, Emitter<CashSessionState> emit) async {
    final currentState = state;
    if (currentState is! CashSessionOpen) return;

    emit(CashSessionLoading());

    final payments = await _db.salesDao.getPaymentsForSession(currentState.session.id);
    final cashSales = payments
        .where((p) => p.method == 'cash')
        .fold<double>(0.0, (sum, p) => sum + p.amount - p.changeGiven);
    final expectedCash = currentState.session.startingCash + cashSales;

    await _db.closeCashSession(
      sessionId: currentState.session.id,
      endingCash: event.countedCash,
      expectedCash: expectedCash,
      notes: event.notes,
    );
    emit(NoCashSession());
  }
}