// lib/core/services/license_service.dart
// ============================================================
//  Service de gestion des licences SaaS GPOS
//  - Vérifie le plan au démarrage (Supabase + cache local)
//  - Expose les limites et features selon le plan
//  - Gestion du mode dégradé (offline)
// ============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/database/pos_database.dart';

// ── PLANS & LIMITES ───────────────────────────────────────────

enum GposPlan { free, pro, premium }

class PlanLimits {
  final GposPlan plan;
  final int maxProducts; // -1 = illimité
  final int maxStores; // -1 = illimité
  final bool syncEnabled;
  final bool reportsEnabled;
  final bool multiStore;
  final bool aiReports;
  final bool apiAccess;
  final int priceFcfa; // Prix mensuel en FCFA

  const PlanLimits({
    required this.plan,
    required this.maxProducts,
    required this.maxStores,
    required this.syncEnabled,
    required this.reportsEnabled,
    required this.multiStore,
    required this.aiReports,
    required this.apiAccess,
    required this.priceFcfa,
  });

  bool get isUnlimitedProducts => maxProducts == -1;
  bool get isUnlimitedStores => maxStores == -1;

  String get planName {
    switch (plan) {
      case GposPlan.free:
        return 'Gratuit';
      case GposPlan.pro:
        return 'Pro';
      case GposPlan.premium:
        return 'Premium';
    }
  }

  String get priceLabel {
    if (priceFcfa == 0) return 'Gratuit';
    return '${_fmt(priceFcfa)} FCFA/mois';
  }

  static String _fmt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} 000';
    return '$v';
  }
}

// Définition des 3 plans
const kPlanFree = PlanLimits(
  plan: GposPlan.free,
  maxProducts: 50,
  maxStores: 1,
  syncEnabled: false,
  reportsEnabled: false,
  multiStore: false,
  aiReports: false,
  apiAccess: false,
  priceFcfa: 0,
);

const kPlanPro = PlanLimits(
  plan: GposPlan.pro,
  maxProducts: -1,
  maxStores: 3,
  syncEnabled: true,
  reportsEnabled: true,
  multiStore: false,
  aiReports: false,
  apiAccess: true,
  priceFcfa: 3000,
);

const kPlanPremium = PlanLimits(
  plan: GposPlan.premium,
  maxProducts: -1,
  maxStores: -1,
  syncEnabled: true,
  reportsEnabled: true,
  multiStore: true,
  aiReports: true,
  apiAccess: true,
  priceFcfa: 8000,
);

// ── ÉTAT DE LA LICENCE ────────────────────────────────────────

class LicenseState {
  final GposPlan plan;
  final String status; // 'active' | 'expired' | 'trial' | 'suspended'
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final bool isFromCache; // true = chargé depuis le cache local
  final DateTime checkedAt;

  const LicenseState({
    required this.plan,
    required this.status,
    this.trialEndsAt,
    this.currentPeriodEnd,
    required this.isFromCache,
    required this.checkedAt,
  });

  PlanLimits get limits {
    switch (plan) {
      case GposPlan.free:
        return kPlanFree;
      case GposPlan.pro:
        return kPlanPro;
      case GposPlan.premium:
        return kPlanPremium;
    }
  }

  bool get isActive => status == 'active' || status == 'trial';

  bool get isInTrial {
    if (status != 'trial') return false;
    if (trialEndsAt == null) return false;
    return DateTime.now().isBefore(trialEndsAt!);
  }

  int get daysLeftInTrial {
    if (!isInTrial || trialEndsAt == null) return 0;
    return trialEndsAt!.difference(DateTime.now()).inDays;
  }

  bool get isExpired =>
      status == 'expired' ||
      (currentPeriodEnd != null && DateTime.now().isAfter(currentPeriodEnd!));

  /// Vérifie si une feature est accessible selon le plan actuel
  bool canAccess(String feature) {
    if (!isActive) return false;
    switch (feature) {
      case 'sync':
        return limits.syncEnabled;
      case 'reports':
        return limits.reportsEnabled;
      case 'multi_store':
        return limits.multiStore;
      case 'ai_reports':
        return limits.aiReports;
      case 'api_access':
        return limits.apiAccess;
      default:
        return true;
    }
  }

  /// Vérifie si le nombre de produits est dans les limites
  bool canAddProduct(int currentCount) {
    if (limits.isUnlimitedProducts) return true;
    return currentCount < limits.maxProducts;
  }
}

// ── SERVICE PRINCIPAL ─────────────────────────────────────────

class LicenseService {
  final PosDatabase _db;
  final SupabaseClient _supabase;

  LicenseState? _cachedState;
  Timer? _refreshTimer;

  // Stream pour notifier l'UI des changements de plan
  final _stateController = StreamController<LicenseState>.broadcast();
  Stream<LicenseState> get stateStream => _stateController.stream;

  LicenseState get currentState =>
      _cachedState ??
      LicenseState(
        plan: GposPlan.free,
        status: 'active',
        isFromCache: true,
        checkedAt: DateTime.now(),
      );

  LicenseService(this._db, this._supabase);

  // ── INITIALISATION ─────────────────────────────────────────

  Future<LicenseState> initialize() async {
    // 1. Charger le cache local d'abord (démarrage rapide)
    final cached = await _loadFromCache();
    if (cached != null) {
      _cachedState = cached;
      _stateController.add(cached);
    }

    // 2. Vérifier avec Supabase en arrière-plan
    final fresh = await _fetchFromSupabase();
    if (fresh != null) {
      _cachedState = fresh;
      await _saveToCache(fresh);
      _stateController.add(fresh);
    }

    // 3. Rafraîchir toutes les 6 heures
    _refreshTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _refreshInBackground(),
    );

    return _cachedState ?? _defaultFreeState();
  }

  // ── VÉRIFICATION SUPABASE ──────────────────────────────────

  Future<LicenseState?> _fetchFromSupabase() async {
    try {
      final shopId = await _db.getSetting('shop_id') ?? '';
      if (shopId.isEmpty) return null;

      final response = await _supabase
          .from('subscriptions')
          .select('plan, status, trial_ends_at, current_period_end')
          .eq('shop_id', shopId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) {
        // Pas de subscription → créer une free automatiquement
        await _createFreeSubscription(shopId);
        return _defaultFreeState();
      }

      return LicenseState(
        plan: _parsePlan(response['plan'] as String? ?? 'free'),
        status: response['status'] as String? ?? 'active',
        trialEndsAt: response['trial_ends_at'] != null
            ? DateTime.tryParse(response['trial_ends_at'] as String)
            : null,
        currentPeriodEnd: response['current_period_end'] != null
            ? DateTime.tryParse(response['current_period_end'] as String)
            : null,
        isFromCache: false,
        checkedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('LicenseService: fetch failed ($e) — using cache');
      return null; // Mode dégradé : utiliser le cache
    }
  }

  Future<void> _createFreeSubscription(String shopId) async {
    try {
      final shopName = await _db.getSetting('shop_name') ?? 'Mon Magasin';
      // Période d'essai Pro de 14 jours au premier lancement
      final trialEnd = DateTime.now().add(const Duration(days: 14));

      await _supabase.from('subscriptions').upsert({
        'shop_id': shopId,
        'plan': 'pro', // Essai Pro gratuit 14 jours
        'status': 'trial',
        'trial_ends_at': trialEnd.toIso8601String(),
        'notes': 'Auto-created: $shopName',
      }, onConflict: 'shop_id');

      debugPrint('LicenseService: created 14-day Pro trial for $shopId');
    } catch (e) {
      debugPrint('LicenseService: could not create subscription: $e');
    }
  }

  Future<void> _refreshInBackground() async {
    final fresh = await _fetchFromSupabase();
    if (fresh != null) {
      _cachedState = fresh;
      await _saveToCache(fresh);
      _stateController.add(fresh);
    }
  }

  // ── CACHE LOCAL ────────────────────────────────────────────

  Future<LicenseState?> _loadFromCache() async {
    try {
      final plan = await _db.getSetting('license_plan');
      final status = await _db.getSetting('license_status');
      final checkedAt = await _db.getSetting('license_checked_at');
      final trialEndsAtStr = await _db.getSetting('license_trial_ends_at');
      final periodEndStr = await _db.getSetting('license_period_end');

      if (plan == null || status == null) return null;

      // Cache valide 48h (en cas d'absence de connexion prolongée)
      if (checkedAt != null) {
        final checked = DateTime.tryParse(checkedAt);
        if (checked != null &&
            DateTime.now().difference(checked).inHours > 48) {
          return null; // Cache trop vieux
        }
      }

      return LicenseState(
        plan: _parsePlan(plan),
        status: status,
        trialEndsAt: trialEndsAtStr != null
            ? DateTime.tryParse(trialEndsAtStr)
            : null,
        currentPeriodEnd: periodEndStr != null
            ? DateTime.tryParse(periodEndStr)
            : null,
        isFromCache: true,
        checkedAt: checkedAt != null
            ? DateTime.tryParse(checkedAt) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToCache(LicenseState state) async {
    await _db.setSetting('license_plan', state.plan.name);
    await _db.setSetting('license_status', state.status);
    await _db.setSetting(
      'license_checked_at',
      state.checkedAt.toIso8601String(),
    );
    if (state.trialEndsAt != null) {
      await _db.setSetting(
        'license_trial_ends_at',
        state.trialEndsAt!.toIso8601String(),
      );
    }
    if (state.currentPeriodEnd != null) {
      await _db.setSetting(
        'license_period_end',
        state.currentPeriodEnd!.toIso8601String(),
      );
    }
  }

  // ── HELPERS ────────────────────────────────────────────────

  GposPlan _parsePlan(String raw) {
    switch (raw.toLowerCase()) {
      case 'pro':
        return GposPlan.pro;
      case 'premium':
        return GposPlan.premium;
      default:
        return GposPlan.free;
    }
  }

  LicenseState _defaultFreeState() => LicenseState(
    plan: GposPlan.free,
    status: 'active',
    isFromCache: true,
    checkedAt: DateTime.now(),
  );

  // ── API PUBLIQUE ────────────────────────────────────────────

  /// Peut-on ajouter un nouveau produit ?
  Future<bool> canAddProduct() async {
    final count = await _db.getActiveProductsCount();
    return currentState.canAddProduct(count);
  }

  /// Feature accessible ?
  bool canAccess(String feature) => currentState.canAccess(feature);

  /// Plan actuel
  GposPlan get plan => currentState.plan;

  /// Forcer un refresh (après paiement par exemple)
  Future<void> forceRefresh() async {
    final fresh = await _fetchFromSupabase();
    if (fresh != null) {
      _cachedState = fresh;
      await _saveToCache(fresh);
      _stateController.add(fresh);
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _stateController.close();
  }
}
