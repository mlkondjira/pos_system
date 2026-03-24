// lib/data/sync/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/pos_database.dart';

class SyncService {
  final PosDatabase _db;
  final SupabaseClient _supabase;

  late String _shopId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool _isOnline = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  // Mémorise le dernier statut pour l'initialisation de l'UI
  SyncStatus _lastStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _lastStatus;

  SyncService(this._db, this._supabase);

  Future<void> initialize() async {
    _shopId = await _db.getSetting('shop_id') ?? '';
    if (_shopId.isEmpty) {
      _shopId = _generateShopId();
      await _db.setSetting('shop_id', _shopId);
    }

    // CORRECTION COMPLÈTE du problème Windows :
    // L'erreur NetworkManager::StartListen vient du STREAM onConnectivityChanged
    // qui lève une PlatformException en dehors du try/catch au moment où
    // Flutter active le canal natif (asynchrone, après le try/catch).
    // Solution : forcer _isOnline = true d'abord, puis tenter le listener.
    // La vérification initiale est supprimée car elle peut retourner `none` à tort
    // au démarrage sur certaines plateformes (ex: Windows), bloquant toute synchronisation.
    // On démarre en mode optimiste (`_isOnline = true`) et on laisse le listener
    // ou les erreurs réseau corriger cet état si nécessaire.
    _isOnline = true;

    // Listener de changement réseau — dans un try/catch séparé
    // car le stream peut lancer PlatformException de façon asynchrone
    try {
      _connectivitySub = Connectivity()
          .onConnectivityChanged
          .listen(
            _onConnectivityChanged,
            onError: (e) {
              // Erreur sur le stream (Windows NetworkManager) → ignorer
              debugPrint('SyncService: connectivity stream error: $e');
            },
          );
    } catch (e) {
      debugPrint('SyncService: cannot subscribe to connectivity: $e');
      // _isOnline est déjà true — pas de problème
    }

    // Timer périodique toutes les 5 minutes — fonctionne sans connectivity
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPending(),
    );

    // Sync immédiate au démarrage
    unawaited(syncPending());
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    if (wasOffline && _isOnline) {
      _publishStatus(SyncStatus.syncing);
      unawaited(syncPending());
    } else if (!wasOffline && !_isOnline) {
      // Gère le passage en mode hors ligne pour que l'UI se mette à jour.
      _publishStatus(SyncStatus.idle);
    }
  }

  Future<void> enqueue({
    required String entityType,
    required int entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
  }) async {
    await _db.into(_db.syncQueue).insertOnConflictUpdate(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        action: Value(action),
        payload: jsonEncode(payload),
        status: const Value('pending'),
      ),
    );
    if (_isOnline && !_isSyncing) unawaited(syncPending());
  }

  Future<bool> registerShop({required String name, required String address}) async {
    if (!_isOnline) return false;

    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // On s'assure que le magasin existe sur le Cloud avec les bonnes infos
      await _supabase.from('shops').upsert({
        'id': _shopId,
        'name': name,
        'address': address,
        'owner_id': user.id,
      }, onConflict: 'id');

      debugPrint('Magasin $_shopId enregistré avec succès sur le Cloud');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du magasin: $e');
      return false;
    }
  }

  Future<void> syncPending() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;
    _publishStatus(SyncStatus.syncing);

    try {
      final pending = await (_db.select(_db.syncQueue)
            ..where((q) =>
                q.status.equals('pending') | q.status.equals('error'))
            ..where((q) => q.retryCount.isSmallerThanValue(5))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
            ..limit(50))
          .get();

      if (pending.isEmpty) {
        _publishStatus(SyncStatus.upToDate);
        return;
      }

      int errorCount = 0;
      for (final item in pending) {
        if (!await _syncItem(item)) errorCount++;
      }

      await _pullFromCloud();

      _publishStatus(
        errorCount == 0 ? SyncStatus.upToDate : SyncStatus.partialError,
      );
    } catch (e) {
      debugPrint('SyncService.syncPending error: $e');
      _publishStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }
  
  void _publishStatus(SyncStatus status) {
    _lastStatus = status;
    _statusController.add(status);
  }

  Future<bool> _syncItem(SyncQueueData item) async {
    await _updateQueueStatus(item.id, 'syncing');
    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      payload['shop_id'] = _shopId;
      payload['local_id'] = item.entityId;

      if (item.action == 'delete') {
        await _supabase
            .from(_tableFor(item.entityType))
            .delete()
            .eq('local_id', item.entityId)
            .eq('shop_id', _shopId);
      } else {
        await _supabase
            .from(_tableFor(item.entityType))
            .upsert(payload, onConflict: 'local_id,shop_id');
      }

      await _updateQueueStatus(item.id, 'done');
      return true;
    } catch (e) {
      await (_db.update(_db.syncQueue)
            ..where((q) => q.id.equals(item.id)))
          .write(SyncQueueCompanion(
        status: const Value('error'),
        retryCount: Value(item.retryCount + 1),
        errorMessage: Value(e.toString()),
        updatedAt: Value(DateTime.now()),
      ));
      return false;
    }
  }

  Future<void> _pullFromCloud() async {
    try {
      final lastPullStr = await _db.getSetting('last_pull_at');
      final lastPull = lastPullStr != null
          ? DateTime.tryParse(lastPullStr) ?? DateTime(2020)
          : DateTime(2020);

      final remoteProducts = await _supabase
          .from('products')
          .select()
          .eq('shop_id', _shopId)
          .gte('updated_at', lastPull.toIso8601String());

      for (final p in remoteProducts as List) {
        await _mergeRemoteProduct(p as Map<String, dynamic>);
      }

      final remoteSales = await _supabase
          .from('sales')
          .select()
          .eq('shop_id', _shopId)
          .gte('synced_at', lastPull.toIso8601String());

      for (final s in remoteSales as List) {
        await _mergeRemoteSale(s as Map<String, dynamic>);
      }

      // AJOUT : Pull des transferts de stock modifiés sur le cloud
      final remoteTransfers = await _supabase
          .from('stock_transfers')
          .select('*, stock_transfer_items(*)') // On récupère les lignes en même temps
          .or('source_shop_id.eq.$_shopId,target_shop_id.eq.$_shopId')
          .gte('updated_at', lastPull.toIso8601String());

      for (final t in remoteTransfers as List) {
        // On ne traite pas les transferts initiés par nous-même qui sont en attente
        if (t['source_shop_id'] == _shopId && t['status'] == 'pending') continue;
        
        await _mergeRemoteTransfer(t as Map<String, dynamic>);
      }

      // NOUVEAU : Récupérer la liste des magasins (pour le sélecteur de transfert)
      final remoteShops = await _supabase.from('shops').select();
      for (final s in remoteShops) {
        final sId = s['id'] as String;
        // On insère ou met à jour les infos des magasins
        await _db.into(_db.shops).insertOnConflictUpdate(ShopsCompanion.insert(
          id: sId,
          name: s['name'] ?? 'Magasin',
          address: Value(s['address']),
          isCurrent: Value(sId == _shopId), // Marque le nôtre comme courant
        ));
      }

      await _db.setSetting(
          'last_pull_at', DateTime.now().toIso8601String());
    } catch (e) {
      // Loguer l'erreur pour le débogage (ex: RLS, Réseau)
      debugPrint('SyncService _pullFromCloud error: $e');
    }
  }

  Future<void> _mergeRemoteTransfer(Map<String, dynamic> remote) async {
    // On utilise `local_id` pour faire le lien avec l'enregistrement local
    final localId = remote['local_id'] as int?;
    if (localId == null) return;

    await _db.transaction(() async {
      // On crée un "Companion" pour l'upsert. Drift gère la conversion des types.
      final companion = StockTransfersCompanion.insert(
        // On force l'ID local pour l'upsert
        id: Value(localId),
        ref: remote['ref'],
        sourceShopId: remote['source_shop_id'],
        targetShopId: remote['target_shop_id'],
        status: Value(remote['status']),
        notes: Value(remote['notes']),
        createdAt: Value(DateTime.parse(remote['created_at'])),
        receivedAt: remote['received_at'] == null ? const Value.absent() : Value(DateTime.parse(remote['received_at'])),
      );

      // On insère ou met à jour l'en-tête du transfert
      await _db.into(_db.stockTransfers).insertOnConflictUpdate(companion);

      // On traite les lignes associées
      final remoteItems = remote['stock_transfer_items'] as List?;
      if (remoteItems != null) {
        for (final itemMap in remoteItems) {
          final itemCompanion = StockTransferItemsCompanion.insert(
            id: Value(itemMap['local_id']),
            transferId: localId,
            productId: itemMap['product_id'],
            quantitySent: itemMap['quantity_sent'],
            quantityReceived: Value(itemMap['quantity_received']),
          );
          await _db.into(_db.stockTransferItems).insertOnConflictUpdate(itemCompanion);
        }
      }
    });
  }

  Future<void> _mergeRemoteProduct(Map<String, dynamic> remote) async {
    final localId = remote['local_id'] as int?;
    if (localId == null) return;
    final local = await (_db.select(_db.products)
          ..where((p) => p.id.equals(localId)))
        .getSingleOrNull();
    if (local == null) return;
    final remoteUpdated =
        DateTime.tryParse(remote['updated_at'] ?? '');
    if (remoteUpdated == null) return;
    if (remoteUpdated.isAfter(local.updatedAt)) {
      await (_db.update(_db.products)
            ..where((p) => p.id.equals(localId)))
          .write(ProductsCompanion(
        stockQty:
            Value(remote['stock_qty'] as int? ?? local.stockQty),
        priceHt: Value(
            (remote['price_ht'] as num?)?.toDouble() ?? local.priceHt),
        updatedAt: Value(remoteUpdated),
      ));
    }
  }

  Future<void> _mergeRemoteSale(Map<String, dynamic> remote) async {
    final localId = remote['local_id'] as int?;
    if (localId == null) return;
    await (_db.select(_db.sales)
          ..where((s) => s.id.equals(localId)))
        .getSingleOrNull();
  }

  String _tableFor(String entityType) => switch (entityType) {
        'sale' => 'sales',
        'product' => 'products',
        'sale_item' || 'sale_items' => 'sale_items',
        'stock_movement' => 'stock_movements',
        'inventory' => 'inventory_sessions',
        'stock_transfers' => 'stock_transfers',
        'stock_transfer_items' => 'stock_transfer_items',
        _ => entityType,
      };

  Future<void> _updateQueueStatus(int id, String status) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
  }

  String _generateShopId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '${now.toRadixString(16)}-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        .replaceAllMapped(RegExp(r'[xy]'), (m) {
      final r = (now * m.start) % 16;
      return (m.group(0) == 'x' ? r : (r & 0x3 | 0x8)).toRadixString(16);
    });
  }

  Future<SyncStats> getStats() async {
    final pending = await (_db.select(_db.syncQueue)
          ..where((q) => q.status.equals('pending')))
        .get();
    final errors = await (_db.select(_db.syncQueue)
          ..where((q) => q.status.equals('error')))
        .get();
    final lastPull = await _db.getSetting('last_pull_at');
    return SyncStats(
      pendingCount: pending.length,
      errorCount: errors.length,
      isOnline: _isOnline,
      lastSyncAt:
          lastPull != null ? DateTime.tryParse(lastPull) : null,
    );
  }

  Future<void> dispose() async {
    _connectivitySub?.cancel();
    _syncTimer?.cancel();
    await _statusController.close();
  }

  Future<void> cleanupOldEntries() async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: 7));
    await (_db.delete(_db.syncQueue)
          ..where((q) =>
              q.status.equals('done') &
              q.updatedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}

enum SyncStatus { idle, syncing, upToDate, partialError, error }

class SyncStats {
  final int pendingCount;
  final int errorCount;
  final bool isOnline;
  final DateTime? lastSyncAt;

  const SyncStats({
    required this.pendingCount,
    required this.errorCount,
    required this.isOnline,
    this.lastSyncAt,
  });
}