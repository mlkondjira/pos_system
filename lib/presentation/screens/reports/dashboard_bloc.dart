// lib/presentation/screens/reports/dashboard_bloc.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── MODÈLES ─────────────────────────────────────────────────

class DailyStat extends Equatable {
  final DateTime date;
  final int saleCount;
  final double revenue;
  const DailyStat({
    required this.date,
    required this.saleCount,
    required this.revenue,
  });
  @override
  List<Object?> get props => [date, revenue];
}

class StoreSummary extends Equatable {
  final String shopId;
  final String shopName;
  final String? address;
  final int saleCount;
  final double revenue;
  final double avgBasket;
  final int lowStockCount;
  final List<DailyStat> weeklyStats;

  const StoreSummary({
    required this.shopId,
    required this.shopName,
    this.address,
    required this.saleCount,
    required this.revenue,
    required this.avgBasket,
    required this.lowStockCount,
    required this.weeklyStats,
  });

  // Variation CA vs jour précédent (calculée depuis weeklyStats)
  double get revenueVariation {
    if (weeklyStats.length < 2) return 0;
    final today = weeklyStats.last.revenue;
    final yesterday = weeklyStats[weeklyStats.length - 2].revenue;
    if (yesterday == 0) return 0;
    return ((today - yesterday) / yesterday) * 100;
  }

  @override
  List<Object?> get props => [shopId, saleCount, revenue, lowStockCount, address];
}

class GlobalStats extends Equatable {
  final double totalRevenue;
  final int totalSales;
  final int totalStores;
  final int totalAlerts;
  final String bestShopId;
  final String bestShopName;
  final double bestShopRevenue;
  final List<DailyStat> globalWeeklyStats;

  const GlobalStats({
    required this.totalRevenue,
    required this.totalSales,
    required this.totalStores,
    required this.totalAlerts,
    required this.bestShopId,
    required this.bestShopName,
    required this.bestShopRevenue,
    this.globalWeeklyStats = const [],
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        totalSales,
        totalStores,
        totalAlerts,
        bestShopId,
        bestShopName,
        bestShopRevenue,
        globalWeeklyStats,
      ];
}

// ─── EVENTS ──────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}
class RefreshDashboard extends DashboardEvent {}

class SelectPeriod extends DashboardEvent {
  final String period; // 'today' | 'week' | 'month'
  const SelectPeriod(this.period);
  @override
  List<Object?> get props => [period];
}

class SelectShopFilter extends DashboardEvent {
  final String? shopId; // null = tous les magasins
  const SelectShopFilter(this.shopId);
  @override
  List<Object?> get props => [shopId];
}

// ─── STATE ───────────────────────────────────────────────────

class DashboardState extends Equatable {
  final List<StoreSummary> stores;
  final GlobalStats? globalStats;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String selectedPeriod;
  final DateTime? lastRefreshed;
  final String? selectedShopId;

  const DashboardState({
    this.stores = const [],
    this.globalStats,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedPeriod = 'today',
    this.lastRefreshed,
    this.selectedShopId,
  });

  bool get hasData => stores.isNotEmpty;

  List<StoreSummary> get storesSortedByRevenue =>
      [...stores]..sort((a, b) => b.revenue.compareTo(a.revenue));

  List<StoreSummary> get visibleStores => selectedShopId == null
      ? storesSortedByRevenue
      : storesSortedByRevenue.where((s) => s.shopId == selectedShopId).toList();

  DashboardState copyWith({
    List<StoreSummary>? stores,
    GlobalStats? globalStats,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    String? selectedPeriod,
    DateTime? lastRefreshed,
    String? selectedShopId,
    bool clearSelectedShop = false,
  }) =>
      DashboardState(
        stores: stores ?? this.stores,
        globalStats: globalStats ?? this.globalStats,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        error: clearError ? null : (error ?? this.error),
        selectedPeriod: selectedPeriod ?? this.selectedPeriod,
        lastRefreshed: lastRefreshed ?? this.lastRefreshed,
        selectedShopId: clearSelectedShop ? null : (selectedShopId ?? this.selectedShopId),
      );

  @override
  List<Object?> get props => [
        stores, globalStats, isLoading, isRefreshing,
        error, selectedPeriod, lastRefreshed, selectedShopId,
      ];
}

// ─── BLOC PRINCIPAL ──────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SupabaseClient _supabase;
  RealtimeChannel? _realtimeSub;
  Timer? _autoRefreshTimer;

  DashboardBloc(this._supabase) : super(const DashboardState()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
    on<SelectPeriod>(_onSelectPeriod);
    on<SelectShopFilter>(_onSelectShopFilter);
  }

  Future<void> _onLoad(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetchAll(emit);

    // Auto-refresh toutes les 2 minutes
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => add(RefreshDashboard()),
    );

    // Supabase Realtime : refresh à chaque nouvelle vente
    _realtimeSub?.unsubscribe();
    _realtimeSub = _supabase
        .channel('owner_dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sales',
          callback: (_) => add(RefreshDashboard()),
        )
        .subscribe();
  }

  Future<void> _onRefresh(
      RefreshDashboard event, Emitter<DashboardState> emit) async {
    if (state.isLoading || state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true));
    await _fetchAll(emit, silent: true);
  }

  Future<void> _onSelectShopFilter(
      SelectShopFilter event, Emitter<DashboardState> emit) async {
    if (state.selectedShopId == event.shopId) return;

    final filteredSummaries = event.shopId == null
        ? state.stores
        : state.stores.where((s) => s.shopId == event.shopId).toList();

    emit(state.copyWith(
      selectedShopId: event.shopId,
      clearSelectedShop: event.shopId == null,
      globalStats: _computeGlobalStats(filteredSummaries),
    ));
  }

  Future<void> _onSelectPeriod(
      SelectPeriod event, Emitter<DashboardState> emit) async {
    if (event.period == state.selectedPeriod) return;
    emit(state.copyWith(
      selectedPeriod: event.period,
      isLoading: true,
      clearError: true,
    ));
    await _fetchAll(emit);
  }

  Future<void> _fetchAll(
    Emitter<DashboardState> emit, {
    bool silent = false,
  }) async {
    try {
      // 1. Magasins du propriétaire
      // Note: 'city' n'est pas standard dans la table shops, on utilise address
      final shopsRes = await _supabase
          .from('shops')
          .select('id, name, address') 
          .order('name');

      final shops = List<Map<String, dynamic>>.from(shopsRes);

      if (shops.isEmpty) {
        emit(state.copyWith(
          stores: [],
          globalStats: const GlobalStats(
            totalRevenue: 0, totalSales: 0, totalStores: 0,
            totalAlerts: 0, bestShopId: '', bestShopName: '',
            bestShopRevenue: 0,
            globalWeeklyStats: [],
          ),
          isLoading: false,
          isRefreshing: false,
          lastRefreshed: DateTime.now(),
        ));
        return;
      }

      final shopIds =
          shops.map((s) => s['id'] as String).toList();

      // 2. Résumé journalier (Vue Postgres recommandée: store_summary)
      final summaryRes = await _supabase
          .from('store_summary')
          .select()
          .filter('shop_id', 'in', shopIds);

      final summaryMap = <String, Map<String, dynamic>>{};
      for (final row in List<Map<String, dynamic>>.from(summaryRes)) {
        summaryMap[row['shop_id'] as String] = row;
      }

      // 3. Stats 7 jours (Vue Postgres: store_weekly)
      final weeklyRes = await _supabase
          .from('store_weekly')
          .select()
          .filter('shop_id', 'in', shopIds);

      final weeklyMap = <String, List<DailyStat>>{};
      for (final row in List<Map<String, dynamic>>.from(weeklyRes)) {
        final sid = row['shop_id'] as String;
        weeklyMap.putIfAbsent(sid, () => []);
        weeklyMap[sid]!.add(DailyStat(
          date: DateTime.parse(row['sale_date'] as String),
          saleCount: (row['sale_count'] as num).toInt(),
          revenue: (row['revenue'] as num).toDouble(),
        ));
      }

      // 4. Alertes stock (Vue Postgres: store_low_stock)
      final alertsRes = await _supabase
          .from('store_low_stock')
          .select()
          .filter('shop_id', 'in', shopIds);

      final alertsMap = <String, int>{};
      for (final row in List<Map<String, dynamic>>.from(alertsRes)) {
        alertsMap[row['shop_id'] as String] =
            (row['low_stock_count'] as num).toInt();
      }

      // 5. Assembler StoreSummary
      final summaries = shops.map((shop) {
        final sid = shop['id'] as String;
        final s = summaryMap[sid];
        final address = (shop['address'] as String?) ?? '';

        return StoreSummary(
          shopId: sid,
          shopName: shop['name'] as String,
          address: address,
          saleCount: (s?['sale_count'] as num?)?.toInt() ?? 0,
          revenue: (s?['revenue'] as num?)?.toDouble() ?? 0.0,
          avgBasket: (s?['avg_basket'] as num?)?.toDouble() ?? 0.0,
          lowStockCount: alertsMap[sid] ?? 0,
          weeklyStats: weeklyMap[sid] ?? [],
        );
      }).toList();

      // Filtrer pour le calcul initial si un filtre est déjà actif
      final visibleForStats = state.selectedShopId == null
          ? summaries
          : summaries.where((s) => s.shopId == state.selectedShopId).toList();

      emit(state.copyWith(
        stores: summaries,
        globalStats: _computeGlobalStats(visibleForStats),
        isLoading: false,
        isRefreshing: false,
        lastRefreshed: DateTime.now(),
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _friendlyError(e),
      ));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Pas de connexion internet';
    }
    if (msg.contains('JWT') || msg.contains('auth')) {
      return 'Session expirée — reconnectez-vous';
    }
    return 'Erreur : $msg';
  }

  GlobalStats _computeGlobalStats(List<StoreSummary> summaries) {
    final totalRevenue = summaries.fold(0.0, (sum, s) => sum + s.revenue);
    final totalSales = summaries.fold(0, (sum, s) => sum + s.saleCount);
    final totalAlerts = summaries.fold(0, (sum, s) => sum + s.lowStockCount);
    final best = summaries.isEmpty
        ? null
        : summaries.reduce((a, b) => a.revenue > b.revenue ? a : b);

    // Agréger les stats hebdomadaires
    final dailyAggregates = <DateTime, DailyStat>{};
    for (final store in summaries) {
      for (final stat in store.weeklyStats) {
        // Normaliser la date pour ignorer l'heure
        final day = DateTime(stat.date.year, stat.date.month, stat.date.day);
        if (dailyAggregates.containsKey(day)) {
          final existing = dailyAggregates[day]!;
          dailyAggregates[day] = DailyStat(
            date: day,
            saleCount: existing.saleCount + stat.saleCount,
            revenue: existing.revenue + stat.revenue,
          );
        } else {
          dailyAggregates[day] = DailyStat(
              date: day, saleCount: stat.saleCount, revenue: stat.revenue);
        }
      }
    }
    final globalWeeklyStats = dailyAggregates.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return GlobalStats(
      totalRevenue: totalRevenue,
      totalSales: totalSales,
      totalStores: summaries.length,
      totalAlerts: totalAlerts,
      bestShopId: best?.shopId ?? '',
      bestShopName: best?.shopName ?? '',
      bestShopRevenue: best?.revenue ?? 0,
      globalWeeklyStats: globalWeeklyStats,
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.unsubscribe();
    _autoRefreshTimer?.cancel();
    return super.close();
  }
}

// ─── BLOC DÉTAIL MAGASIN ──────────────────────────────────────

abstract class StoreDetailEvent extends Equatable {
  const StoreDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadStoreDetail extends StoreDetailEvent {
  final String shopId;
  const LoadStoreDetail(this.shopId);
  @override
  List<Object?> get props => [shopId];
}

class StoreDetailState extends Equatable {
  final String shopId;
  final List<DailyStat> dailyStats;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> recentSales;
  final bool isLoading;
  final String? error;

  const StoreDetailState({
    this.shopId = '',
    this.dailyStats = const [],
    this.topProducts = const [],
    this.recentSales = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalRevenue30d =>
      dailyStats.fold(0.0, (sum, s) => sum + s.revenue);

  int get totalSales30d =>
      dailyStats.fold(0, (sum, s) => sum + s.saleCount);

  StoreDetailState copyWith({
    String? shopId,
    List<DailyStat>? dailyStats,
    List<Map<String, dynamic>>? topProducts,
    List<Map<String, dynamic>>? recentSales,
    bool? isLoading,
    String? error,
  }) =>
      StoreDetailState(
        shopId: shopId ?? this.shopId,
        dailyStats: dailyStats ?? this.dailyStats,
        topProducts: topProducts ?? this.topProducts,
        recentSales: recentSales ?? this.recentSales,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [shopId, dailyStats, topProducts, recentSales, isLoading, error];
}

class StoreDetailBloc
    extends Bloc<StoreDetailEvent, StoreDetailState> {
  final SupabaseClient _supabase;

  StoreDetailBloc(this._supabase) : super(const StoreDetailState()) {
    on<LoadStoreDetail>(_onLoad);
  }

  Future<void> _onLoad(
      LoadStoreDetail event, Emitter<StoreDetailState> emit) async {
    emit(state.copyWith(shopId: event.shopId, isLoading: true));

    try {
      // CA des 30 derniers jours
      final salesRes = await _supabase
          .from('sales')
          .select('created_at, total_ttc')
          .eq('shop_id', event.shopId)
          .eq('status', 'completed')
          .gte('created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String())
          .order('created_at');

      // Grouper par jour côté client
      final dayMap = <String, _DayAccum>{};
      for (final row in (salesRes as List<dynamic>)) {
        final r = row as Map<String, dynamic>;
        final dt = DateTime.parse(r['created_at'] as String);
        final key =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final acc = dayMap[key] ?? _DayAccum();
        acc.count++;
        acc.revenue += (r['total_ttc'] as num).toDouble();
        dayMap[key] = acc;
      }

      final dailyStats = dayMap.entries
          .map((e) => DailyStat(
                date: DateTime.parse(e.key),
                saleCount: e.value.count,
                revenue: e.value.revenue,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Top 5 produits
      final topRes = await _supabase
          .from('global_top_products')
          .select()
          .eq('shop_id', event.shopId)
          .limit(5);

      // 10 dernières ventes
      final recentRes = await _supabase
          .from('sales')
          .select('ref, total_ttc, created_at, status')
          .eq('shop_id', event.shopId)
          .order('created_at', ascending: false)
          .limit(10);

      emit(state.copyWith(
        dailyStats: dailyStats,
        topProducts: List<Map<String, dynamic>>.from(topRes),
        recentSales: List<Map<String, dynamic>>.from(recentRes),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

// Petit accumulateur interne
class _DayAccum {
  int count = 0;
  double revenue = 0;
}