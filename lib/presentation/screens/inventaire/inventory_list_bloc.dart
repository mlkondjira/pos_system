// lib/presentation/screens/inventaire/inventory_list_bloc.dart
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/pos_database.dart';

// ── EVENTS ───────────────────────────────────────────────────

abstract class InventoryListEvent extends Equatable {
  const InventoryListEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventoryList extends InventoryListEvent {}

class CreateInventory extends InventoryListEvent {
  final String notes;
  final int userId;
  const CreateInventory({required this.notes, required this.userId});
  @override
  List<Object?> get props => [notes, userId];
}

class SearchQueryChanged extends InventoryListEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterStatusChanged extends InventoryListEvent {
  // 'all' | 'in_progress' | 'completed' | 'cancelled'
  final String status;
  const FilterStatusChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class ResetFilters extends InventoryListEvent {}

// ── STATE ─────────────────────────────────────────────────────

class InventoryListState extends Equatable {
  final List<InventorySession> sessions;
  final String searchQuery;
  final String statusFilter;
  final bool isLoading;
  final String? errorMessage;

  const InventoryListState({
    this.sessions = const [],
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.isLoading = false,
    this.errorMessage,
  });

  List<InventorySession> get filteredSessions {
    var result = sessions;

    if (statusFilter != 'all') {
      result = result.where((s) => s.status == statusFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((s) =>
              s.ref.toLowerCase().contains(q) ||
              s.notes.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  InventoryListState copyWith({
    List<InventorySession>? sessions,
    String? searchQuery,
    String? statusFilter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      InventoryListState(
        sessions: sessions ?? this.sessions,
        searchQuery: searchQuery ?? this.searchQuery,
        statusFilter: statusFilter ?? this.statusFilter,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [sessions, searchQuery, statusFilter, isLoading, errorMessage];
}

// ── BLOC ──────────────────────────────────────────────────────

class InventoryListBloc
    extends Bloc<InventoryListEvent, InventoryListState> {
  final PosDatabase _db;

  InventoryListBloc(this._db) : super(const InventoryListState()) {
    on<LoadInventoryList>(_onLoad);
    on<CreateInventory>(_onCreate);
    on<SearchQueryChanged>(_onSearch);
    on<FilterStatusChanged>(_onFilter);
    on<ResetFilters>(_onReset);
  }

  // ── Chargement réactif via stream ─────────────────────────
  Future<void> _onLoad(
      LoadInventoryList event, Emitter<InventoryListState> emit) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach(
      _db.watchInventorySessions(),
      onData: (sessions) => state.copyWith(
        sessions: sessions,
        isLoading: false,
      ),
      onError: (err, _) => state.copyWith(
        isLoading: false,
        errorMessage: err.toString(),
      ),
    );
  }

  // ── Création d'une nouvelle session d'inventaire ──────────
  Future<void> _onCreate(
      CreateInventory event, Emitter<InventoryListState> emit) async {
    try {
      final now = DateTime.now();
      final ref =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

      // Récupère tous les produits actifs pour créer les lignes
      final products = await _db.watchActiveProducts().first;
      final terminalId = await _db.getSetting('terminal_id') ?? '';

      await _db.transaction(() async {
        // Insertion de la session — sans 'label' (absent de la table)
        final sessionId = await _db.into(_db.inventorySessions).insert(
              InventorySessionsCompanion.insert(
                ref: ref,
                userId: event.userId,
                terminalId: Value(terminalId),
                totalProducts: Value(products.length),
                status: const Value('in_progress'), // <-- CORRECTION: Démarrer en 'in_progress'
                notes: Value(event.notes),
              ),
            );

        // Ligne d'inventaire pour chaque produit avec son stock actuel
        for (final p in products) {
          await _db.into(_db.inventoryLines).insert(
                InventoryLinesCompanion.insert(
                  sessionId: sessionId,
                  productId: p.id,
                  productName: p.name,
                  terminalId: Value(terminalId), // Nettoyage de la syntaxe
                  barcode: Value(p.barcode),
                  expectedQty: p.stockQty,
                ),
              );
        }
      });
      // watchInventorySessions() se met à jour automatiquement via stream
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Erreur création inventaire : $e'));
    }
  }

  void _onSearch(
      SearchQueryChanged event, Emitter<InventoryListState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilter(
      FilterStatusChanged event, Emitter<InventoryListState> emit) {
    emit(state.copyWith(statusFilter: event.status));
  }

  void _onReset(ResetFilters event, Emitter<InventoryListState> emit) {
    emit(state.copyWith(searchQuery: '', statusFilter: 'all'));
  }
}