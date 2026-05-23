// lib/data/sync/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../core/di/injection.dart';
import '../../core/utils/notification_service.dart';
import '../database/pos_database.dart';
import '../../core/utils/error_formatter.dart';

class SyncService {
  final PosDatabase _db;
  final SupabaseClient _supabase;

  late String _shopId;
  late String _terminalId;
  late String _terminalName;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _syncTimer;
  RealtimeChannel? _productChannel;
  RealtimeChannel? _transferChannel;

  bool _isSyncing = false;
  bool _isOnline = false;

  final _statusController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get statusStream => _statusController.stream;

  // Notifiant pour le badge de transfert
  final ValueNotifier<int> pendingTransferCount = ValueNotifier<int>(0);

  // Mémorise le dernier statut pour l'initialisation de l'UI
  SyncStatus _lastStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _lastStatus;
  SyncProgress _lastProgress = const SyncProgress(status: SyncStatus.idle);
  SyncProgress get currentProgress => _lastProgress;

  SyncService(this._db, this._supabase);

  Future<void> initialize() async {
    _shopId = await _db.getSetting('shop_id') ?? '';
    // On ne génère plus de shop_id automatiquement ici.
    // L'interface affichera l'écran d'onboarding si _shopId est vide.

    _terminalId = await _db.getSetting('terminal_id') ?? '';
    if (_terminalId.isEmpty) {
      // Génère un UUID complet pour correspondre au type 'uuid' de Supabase
      _terminalId = const Uuid().v4();
      await _db.setSetting('terminal_id', _terminalId);
      debugPrint('SyncService: Nouveau terminal_id généré : $_terminalId');
    } else {
      debugPrint('SyncService: TerminalId chargé : $_terminalId');
    }

    _terminalName = await _db.getSetting('terminal_name') ?? 'Caisse 1';

    // Enregistre le nom de cette caisse sur le Cloud pour les rapports
    unawaited(_registerTerminal());

    // CORRECTION COMPLÈTE du problème Windows :
    // L'erreur NetworkManager::StartListen vient du STREAM onConnectivityChanged
    // qui lève une PlatformException en dehors du try/catch au moment où
    // Flutter active le canal natif (asynchrone, après le try/catch).
    // Solution : forcer _isOnline = true d'abord, puis tenter le listener.
    // La vérification initiale est supprimée car elle peut retourner `none` à tort
    // au démarrage sur certaines plateformes (ex: Windows), bloquant toute synchronisation.
    // On démarre en mode optimiste (`_isOnline = true`) et on laisse le listener
    // ou les erreurs réseau corriger cet état si nécessaire.
    _isOnline = !Platform
        .isWindows; // Sur mobile, on peut se fier un peu plus au statut initial

    // Le listener crash souvent sur Windows (NetworkManager::StartListen)
    // On ne l'active que sur Mobile.
    if (!Platform.isWindows) {
      try {
        _connectivitySub = Connectivity().onConnectivityChanged.listen(
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
    }

    // Timer périodique toutes les 5 minutes — fonctionne sans connectivity
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPending(),
    );

    // Sync immédiate au démarrage avec un léger délai pour laisser l'UI respirer
    Future.delayed(const Duration(seconds: 2), () {
      if (_shopId.isNotEmpty) syncPending();
    });

    // Initialiser l'écoute temps réel
    _setupRealtimeListeners();
  }

  /// Uploade une image vers Supabase Storage et retourne l'URL publique
  Future<String?> uploadProductImage(File imageFile, String fileName) async {
    // Pour économiser de l'espace sur Supabase Storage (quota de fichiers),
    // nous sauvegardons l'image uniquement dans le dossier local de l'application.
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(directory.path, 'product_images'));
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      await imageFile.copy(p.join(imagesDir.path, fileName));
      // SÉCURITÉ : On ne retourne que le nom du fichier pour éviter les problèmes
      // de chemins absolus qui changent lors des mises à jour iOS.
      return fileName;
    } catch (e) {
      debugPrint('Erreur sauvegarde image locale: $e');
      return null;
    }
  }

  /// Met à jour le nom du terminal sur le Cloud (appelé depuis les paramètres)
  Future<void> updateTerminalName(String newName) async {
    _terminalName = newName;
    if (_shopId.isNotEmpty && _terminalId.isNotEmpty && _isOnline) {
      await _supabase.from('terminals').upsert({
        'id': _terminalId,
        'shop_id': _shopId,
        'name': _terminalName,
      });
    }
  }

  Future<void> _registerTerminal() async {
    if (_shopId.isEmpty || _terminalId.isEmpty || !_isOnline) return;
    try {
      await _supabase.from('terminals').upsert({
        'id': _terminalId,
        'shop_id': _shopId,
        'name': _terminalName,
      });
    } catch (e) {
      debugPrint('SyncService: Échec de l\'enregistrement du terminal: $e');
    }
  }

  void _setupRealtimeListeners() {
    if (_shopId.isEmpty) return;

    // On s'abonne aux changements de la table products pour ce magasin précis
    _productChannel = _supabase
        .channel('products_repo')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: _shopId,
          ),
          callback: (payload) async {
            if (payload.eventType == PostgresChangeEvent.delete) {
              // Gestion de la suppression distante
              final oldId = payload.oldRecord['local_id'] as int?;
              if (oldId != null) {
                await (_db.update(_db.products)
                      ..where((p) => p.id.equals(oldId)))
                    .write(const ProductsCompanion(isActive: Value(false)));
                debugPrint(
                  'Realtime: Produit $oldId marqué comme inactif (supprimé sur le cloud)',
                );
              }
            } else {
              // Gestion de l'insertion ou mise à jour (ex: stock)
              final record = payload.newRecord;
              if (record.isEmpty) return;

              final localId = (record['local_id'] as num).toInt();
              final remoteUpdatedAt = DateTime.parse(
                record['updated_at'] as String,
              );

              // OPTIMISATION : Vérifier si la mise à jour est réellement nécessaire
              final localProduct = await (_db.select(
                _db.products,
              )..where((p) => p.id.equals(localId))).getSingleOrNull();

              if (localProduct != null) {
                // Si la donnée locale est plus récente ou identique, on ignore le message cloud
                // Cela évite de traiter nos propres messages renvoyés par Supabase
                if (localProduct.updatedAt.isAfter(remoteUpdatedAt) ||
                    localProduct.updatedAt.isAtSameMomentAs(remoteUpdatedAt)) {
                  return;
                }
              }

              await (_db.update(
                _db.products,
              )..where((p) => p.id.equals(localId))).write(
                ProductsCompanion(
                  name: Value(record['name'] as String),
                  // On ne met à jour le prix que s'il est présent (évite d'écraser par null lors d'un update de stock seul)
                  priceHt: record['price_ht'] != null
                      ? Value((record['price_ht'] as num).toDouble())
                      : const Value.absent(),
                  stockQty: Value((record['stock_qty'] as num).toInt()),
                  updatedAt: Value(remoteUpdatedAt),
                  isActive: Value(record['is_active'] as bool? ?? true),
                ),
              );
              debugPrint('Realtime: Produit ${record['name']} synchronisé');
            }
          },
        )
        .subscribe();

    // On s'abonne aux transferts de stock
    _transferChannel = _supabase
        .channel('public:stock_transfers:shop_id=eq.$_shopId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stock_transfers',
          callback: (payload) {
            // Si le transfert concerne notre magasin (envoi ou réception)
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;

            // OPTIMISATION : Ignorer si nous sommes l'émetteur du changement
            if (record['terminal_id'] == _terminalId) return;

            if (record['source_shop_id'] == _shopId ||
                record['target_shop_id'] == _shopId) {
              debugPrint(
                'Realtime: Changement de transfert détecté, lancement du pull.',
              );

              // Si c'est un nouveau transfert pour nous, on notifie
              if (payload.eventType == PostgresChangeEvent.insert &&
                  record['target_shop_id'] == _shopId) {
                getIt<NotificationService>().showIncomingTransferNotification(
                  transferId: record['local_id'] as int,
                  ref: record['ref'] as String,
                  sourceShop:
                      'un autre magasin', // Idéalement, faire un look-up du nom
                );
              }
              unawaited(syncPending());
            }
          },
        )
        .subscribe();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      _publishProgress(
        SyncStatus.syncing,
        value: 0.1,
        message: 'Connexion rétablie...',
      );

      // Réinitialise automatiquement les erreurs réseau pour leur donner une nouvelle chance
      await _db.resetTransientErrors();

      unawaited(syncPending());
    } else if (!wasOffline && !_isOnline) {
      // Gère le passage en mode hors ligne
      _publishProgress(SyncStatus.idle);
    }
  }

  /// Met à jour l'état de synchronisation et notifie l'interface utilisateur.
  void _publishProgress(
    SyncStatus status, {
    double value = 0.0,
    String message = '',
    String? error,
  }) {
    _lastStatus = status;
    _lastProgress = SyncProgress(
      status: status,
      value: value,
      message: message,
      errorMessage: error,
    );
    if (!_statusController.isClosed) {
      _statusController.add(_lastProgress);
    }
  }

  /// Utilise maintenant la méthode centralisée de la base de données
  Future<void> enqueue({
    required String entityType,
    required int entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
  }) async {
    await _db.enqueue(
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      action: action,
      shopId: _shopId,
      terminalId: _terminalId,
    );

    // Si le service est en ligne et n'est pas déjà en train de synchroniser, déclencher une synchro.
    if (_isOnline && !_isSyncing && entityType != 'stock_delta') {
      unawaited(syncPending());
    }
  }

  /// Réinitialise toutes les erreurs et force une synchronisation immédiate.
  Future<void> forceSync() async {
    // 1. Remise à zéro de TOUTES les erreurs dans la file locale
    await (_db.update(
      _db.syncQueue,
    )..where((q) => q.status.equals('error'))).write(
      SyncQueueCompanion(
        status: const Value('pending'),
        retryCount: const Value(0),
        errorMessage: const Value(null),
        nextAttemptAt: const Value(null), // Réinitialiser le délai
        updatedAt: Value(DateTime.now()),
      ),
    );

    // 2. Déclenchement de la synchro en ignorant les délais habituels
    return syncPending(ignoreTimeouts: true);
  }

  /// Parcourt tous les produits locaux et les ajoute à la file de synchro
  /// Utile si le catalogue a été créé hors-ligne ou avant la connexion Cloud.
  Future<void> forceUploadCatalog({
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final allProducts = await _db.select(_db.products).get();
    final total = allProducts.length;
    debugPrint('SyncService: Préparation de l\'envoi de $total produits...');

    for (int i = 0; i < total; i++) {
      if (shouldCancel != null && shouldCancel()) {
        return;
      }

      final product = allProducts[i];
      await enqueue(
        entityType: 'product',
        entityId: product.id,
        payload: product.toJson(),
      );
      if (onProgress != null) {
        onProgress((i + 1) / total);
      }
    }
  }

  /// Enregistre un nouveau magasin sur Supabase. L'utilisateur doit déjà être connecté et confirmé.
  Future<bool> registerShop({
    required String name,
    required String address,
    String? customId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint(
        'SyncService: registerShop échoué car aucun utilisateur Cloud connecté',
      );
      return false;
    }

    final idToUse = customId ?? _shopId;
    if (idToUse.isEmpty) {
      debugPrint('SyncService: registerShop échoué car ID est vide');
      return false;
    }

    try {
      // On s'assure que le magasin existe sur le Cloud avec les bonnes infos
      await _supabase.from('shops').upsert({
        'id': idToUse, // Doit correspondre à la PK dans Supabase (id)
        'name': name,
        'address': address,
        'owner_id': user.id,
      }, onConflict: 'id');

      debugPrint('Magasin $idToUse enregistré avec succès sur le Cloud');
      return true;
    } catch (e) {
      debugPrint('DÉTAIL ERREUR SUPABASE: $e');
      // On relance l'erreur pour que l'UI puisse l'afficher précisément
      rethrow;
    }
  }

  /// Envoie un code OTP à l'email de l'utilisateur pour vérification.
  Future<void> sendEmailVerificationOtp(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  /// Vérifie le code OTP reçu par email.
  Future<void> verifyEmailOtp(String email, String otp) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.signup,
    );
  }

  /// Récupère la liste de tous les magasins appartenant au propriétaire actuel.
  Future<List<Map<String, dynamic>>> getAvailableShops() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await _supabase
          .from('shops')
          .select('id, name, address')
          .eq('owner_id', user.id);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint(
        'SyncService: Erreur lors de la récupération des magasins: $e',
      );
      return [];
    }
  }

  /// Récupère les prédictions d'approvisionnement (Expertise Conseil)
  Future<List<Map<String, dynamic>>> getStockPredictions({
    String? shopId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_stock_predictions',
        params: {'p_owner_id': user.id, 'p_shop_id': shopId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SyncService: Erreur prédictions stock: $e');
      return [];
    }
  }

  /// Bascule l'application sur un autre magasin.
  Future<void> switchShop(String newShopId) async {
    if (newShopId == _shopId) return;

    _shopId = newShopId;
    await _db.setSetting('shop_id', newShopId);

    // Réinitialiser les écouteurs temps réel pour le nouveau magasin
    await _productChannel?.unsubscribe();
    await _transferChannel?.unsubscribe();
    _setupRealtimeListeners();

    // Forcer un pull immédiat des données du nouveau magasin
    await syncPending(ignoreTimeouts: true);
  }

  /// Récupère les statistiques complètes du tableau de bord pour le propriétaire.
  /// Appelle la fonction RPC `get_dashboard_stats` de Supabase.
  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
    String? terminalId,
    bool sortByRevenue = true, // NEW parameter
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated for dashboard stats.');
    }

    try {
      final response = await _supabase.rpc(
        'get_dashboard_stats',
        params: {
          'p_owner_id': user.id,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
          'p_terminal_id': terminalId, // Peut être null
          'p_sort_by_revenue': sortByRevenue, // Pass the new parameter
        },
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  Future<void> syncPending({bool ignoreTimeouts = false}) async {
    if (_isSyncing) return;

    // Sécurité : Ne pas synchroniser si aucun magasin n'est configuré
    if (_shopId.isEmpty) {
      return;
    }

    // Sécurité Windows/Desktop : si le stream de connectivité est capricieux,
    // on fait une vérification manuelle avant d'abandonner.
    if (!_isOnline) {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    }

    if (!_isOnline) return;

    _isSyncing = true;
    _publishProgress(
      SyncStatus.syncing,
      value: 0.0,
      message: 'Démarrage de la synchro...',
    );

    try {
      // Nettoyer les anciennes entrées au début de chaque cycle de synchro
      await cleanupOldEntries();

      bool hasMore = true;
      int totalProcessed = 0;
      int totalErrorCount = 0;
      String? firstError;
      bool criticalErrorOccurred = false;
      final startTime = DateTime.now();
      const maxDuration = Duration(
        minutes: 2,
      ); // Limite de 2 minutes pour l'envoi (Upload)
      bool uploadTimedOut = false;

      while (hasMore) {
        if (!ignoreTimeouts &&
            DateTime.now().difference(startTime) > maxDuration) {
          // Statements in a for should be enclosed in a block.
          debugPrint(
            'SyncService: Temps limite atteint pour l\'envoi des données.',
          );
          uploadTimedOut = true;
          break;
        }

        // Pour les retries exponentiels, on ne tente que si le temps est écoulé
        final now = DateTime.now();

        final pending =
            await (_db.select(_db.syncQueue)
                  ..where(
                    (q) =>
                        (q.status.equals(
                          'pending',
                        )) | // Les éléments en attente sont toujours prioritaires
                        (q.status.equals('error') &
                            q.retryCount.isSmallerThanValue(5) &
                            (q.nextAttemptAt.isNull() |
                                q.nextAttemptAt.isSmallerOrEqualValue(
                                  now,
                                ))), // Les erreurs sont retentées si le délai est passé
                  )
                  ..where((q) => q.retryCount.isSmallerThanValue(5))
                  ..orderBy([
                    (q) => OrderingTerm(
                      expression: q.entityType.caseMatch<int>(
                        when: {
                          // Prioriser les deltas de stock pour un traitement rapide des retries
                          const Constant('stock_delta'): const Constant(-1),
                          const Constant('category'): const Constant(
                            0,
                          ), // Ordre par défaut
                          const Constant('product'): const Constant(0),
                          const Constant('customer'): const Constant(0),
                          const Constant('sale'): const Constant(0),
                          const Constant('sale_item'): const Constant(0),
                          const Constant('payment'): const Constant(0),
                          const Constant('cash_session'): const Constant(0),
                          const Constant('stock_transfer'): const Constant(0),
                          const Constant('stock_transfer_item'): const Constant(
                            0,
                          ),
                        },
                        orElse: const Constant(1),
                      ),
                    ),
                    (q) => OrderingTerm.asc(q.createdAt),
                  ])
                  ..limit(50))
                .get();

        if (pending.isEmpty) {
          hasMore = false;
          continue;
        }

        // Map pour les tentatives de ce lot
        final Map<int, int> retryCounts = {
          for (var item in pending) item.id: item.retryCount,
        };

        _publishProgress(
          SyncStatus.syncing,
          value: 0.1,
          message: 'Envoi des données ($totalProcessed)...',
        );

        // 1. Préparation des payloads dans un Isolate
        final preparedData = await compute(_prepareSyncPayloads, {
          'pending': pending
              .map(
                (e) => {
                  'id': e.id,
                  'entityType': e.entityType,
                  'entityId': e.entityId,
                  'action': e.action,
                  'payload': e.payload,
                  'shopId': e.shopId,
                },
              )
              .toList(),
          'currentShopId': _shopId,
          'terminalId': _terminalId,
        });

        final uploads = (preparedData['uploads'] as Map)
            .cast<String, List<Map<String, dynamic>>>();
        final deletes = (preparedData['deletes'] as Map)
            .cast<String, List<int>>();
        final queueIdsMap = (preparedData['queueIdsByGroup'] as Map)
            .cast<String, List<int>>();

        final List<int> successfullySyncedIds = [];
        final Map<int, String> failedToSync = {};

        // 2. Envoi des SUPPRESSIONS en masse
        for (final entry in deletes.entries) {
          try {
            final table = _tableFor(entry.key);
            // On utilise _shopId du service comme sécurité, mais l'isolate a maintenant accès au shopId par item
            await _supabase
                .from(table)
                .delete()
                .inFilter('local_id', entry.value)
                .eq('shop_id', _shopId);
            successfullySyncedIds.addAll(
              queueIdsMap['${entry.key}_delete'] ?? [],
            );
          } catch (e) {
            final msg = ErrorFormatter.format(e);
            if (entry.key == 'stock_transfers' ||
                entry.key == 'stock_transfer_items') {
              criticalErrorOccurred = true;
            }
            for (final id in queueIdsMap['${entry.key}_delete'] ?? []) {
              failedToSync[id] = msg;
            }
          }
        }

        // 3. Envoi des UPSERTS en masse
        for (final entry in uploads.entries) {
          try {
            final table = _tableFor(entry.key);
            final payloads = entry.value;
            final queueIds =
                queueIdsMap['${entry.key}_upsert'] ??
                queueIdsMap['${entry.key}_delta'] ??
                [];

            if (entry.key == 'stock_delta') {
              try {
                final List<dynamic> results = await _supabase.rpc(
                  'batch_update_product_stock_delta',
                  params: {'p_deltas': payloads},
                );

                bool hasCriticalStockError = false;
                String? firstStockErrorMessage;

                for (var i = 0; i < results.length; i++) {
                  final res = results[i];
                  final qId = queueIds[i];
                  if (res['success'] == true) {
                    successfullySyncedIds.add(qId);
                  } else {
                    final msg = res['message'] ?? 'Erreur stock';
                    failedToSync[qId] = msg;

                    // Détection des erreurs critiques (ex: levées par le trigger SQL 'Stock insuffisant')
                    if (msg.toLowerCase().contains('insuffisant')) {
                      hasCriticalStockError = true;
                      firstStockErrorMessage ??= msg;
                    }
                  }
                }

                if (hasCriticalStockError) {
                  unawaited(
                    getIt<NotificationService>().showCriticalErrorNotification(
                      title: '🚨 Alerte Stock Critique',
                      body:
                          firstStockErrorMessage ??
                          'Un conflit de stock majeur a été détecté lors de la synchronisation.',
                    ),
                  );
                }
              } catch (e) {
                final msg = ErrorFormatter.format(e);
                for (final id in queueIds) {
                  failedToSync[id] = msg;
                }
              }
            } else if (entry.key == 'refund') {
              try {
                final List<dynamic> results = await _supabase.rpc(
                  'batch_process_sale_refund',
                  params: {'p_refunds': payloads},
                );

                // On mappe les résultats par rapport à local_id pour valider la queue
                for (var i = 0; i < results.length; i++) {
                  final res = results[i];
                  final qId = queueIds[i];
                  if (res['success'] == true) {
                    successfullySyncedIds.add(qId);
                  } else {
                    failedToSync[qId] = res['message'] ?? 'Erreur cloud';
                  }
                }
              } catch (e) {
                final msg = ErrorFormatter.format(e);
                for (final id in queueIds) {
                  failedToSync[id] = msg;
                }
              }
            } else if (entry.key == 'product') {
              // NOUVEAU : Utiliser la fonction RPC avec détection de conflit pour les produits
              try {
                final List<dynamic> results = await _supabase.rpc(
                  'upsert_product_attributes_with_conflict_check',
                  params: {'p_product_data': payloads.first},
                );

                final res = results.first;
                final qId = queueIds.first;
                if (res['success'] == true) {
                  successfullySyncedIds.add(qId);
                } else {
                  failedToSync[qId] =
                      res['message'] ?? 'Erreur de conflit produit';
                  // Optionnel : Déclencher une notification ou un log d'erreur spécifique
                  unawaited(
                    getIt<NotificationService>().showCriticalErrorNotification(
                      title: '⚠️ Conflit de Produit',
                      body:
                          'Une modification du produit a été rejetée: ${res['message']}',
                    ),
                  );
                }
              } catch (e) {
                final msg = ErrorFormatter.format(e);
                for (final id in queueIds) {
                  failedToSync[id] = msg;
                }
              }
            } else {
              // Définition dynamique des colonnes de conflit selon la table
              final String onConflictColumns = (entry.key == 'shops')
                  ? 'id'
                  : ([
                      'products',
                      'categories',
                      'customers',
                      'suppliers',
                      'users',
                    ].contains(entry.key))
                  ? 'shop_id,local_id'
                  : 'shop_id,terminal_id,local_id';

              await _supabase
                  .from(table)
                  .upsert(payloads, onConflict: onConflictColumns);
              successfullySyncedIds.addAll(
                queueIdsMap['${entry.key}_upsert'] ?? [],
              );
            }
          } catch (e) {
            final msg = ErrorFormatter.format(e);
            if (entry.key == 'stock_transfers' ||
                entry.key == 'stock_transfer_items') {
              criticalErrorOccurred = true;
            }
            for (final id in queueIdsMap['${entry.key}_upsert'] ?? []) {
              failedToSync.putIfAbsent(id, () => msg);
            }
          }
        }

        // Capturer le premier message d'erreur s'il y en a un dans ce lot
        if (failedToSync.isNotEmpty) {
          firstError ??= failedToSync.values.first;
        }

        // Mise à jour des statuts dans SQLite pour ce lot
        await _db.batch((batch) async {
          // Utilisation de async pour le batch
          final now =
              DateTime.now(); // Récupérer l'heure actuelle une seule fois
          for (final id in successfullySyncedIds) {
            batch.update(
              _db.syncQueue,
              SyncQueueCompanion(
                status: const Value('done'),
                updatedAt: Value(now),
                nextAttemptAt: const Value(null),
              ),
              where: (q) => q.id.equals(id),
            );
          }
          failedToSync.forEach((id, msg) {
            final currentRetryCount = (retryCounts[id] ?? 0) + 1;
            DateTime? nextAttempt;
            if (currentRetryCount < 5) {
              // Max 5 tentatives avant abandon
              final int delayMinutes = pow(
                2,
                currentRetryCount - 1,
              ).toInt(); // 1, 2, 4, 8 minutes
              nextAttempt = DateTime.now().add(Duration(minutes: delayMinutes));
            }

            batch.update(
              _db.syncQueue,
              SyncQueueCompanion(
                status: const Value('error'),
                retryCount: Value(currentRetryCount),
                errorMessage: Value(msg),
                updatedAt: Value(now),
                nextAttemptAt: Value(nextAttempt),
              ),
              where: (q) => q.id.equals(id),
            );
          });
        });

        // --- MONITORING : Envoi des erreurs vers le cloud pour suivi à distance ---
        if (failedToSync.isNotEmpty) {
          final List<Map<String, dynamic>> errorLogs = [];
          failedToSync.forEach((qId, msg) {
            // Retrouver l'élément d'origine dans le lot 'pending' pour avoir le payload
            final original = pending.firstWhere((p) => p.id == qId);
            errorLogs.add({
              'shop_id': _shopId,
              'terminal_id': _terminalId,
              'entity_type': original.entityType,
              'entity_id': original.entityId,
              'error_message': msg,
              'payload': jsonDecode(original.payload),
            });
          });
          unawaited(_supabase.from('sync_error_logs').insert(errorLogs));
        }

        // ARRÊT CRITIQUE : Si un transfert a échoué, on ne continue pas le reste de la synchro
        if (criticalErrorOccurred) {
          debugPrint(
            'SyncService: Arrêt critique sur transfert de stock. Erreur: $firstError',
          );
          // On déclenche la notification push locale
          Future.microtask(() {
            getIt<NotificationService>().showCriticalErrorNotification(
              title: '⚠️ Échec de Transfert',
              body:
                  'Échec du transfert : ${firstError ?? "Erreur de contrainte base de données"}.',
            );
          });
          _publishProgress(
            SyncStatus.error,
            message:
                'ERREUR LOGISTIQUE : Échec de synchro d\'un transfert. Opération stoppée.',
            error: firstError,
          );
          return; // Sortie immédiate de la fonction
        }

        totalErrorCount += failedToSync.length;
        if (firstError == null && failedToSync.isNotEmpty) {
          firstError = failedToSync.values.first;
        }
        totalProcessed += pending.length;

        if (pending.length < 50) {
          hasMore = false;
        }
      }

      final pullFinished = await _pullFromCloud(ignoreTimeouts: ignoreTimeouts);

      // --- NOUVEAU : Archivage automatique des promos expirées ---
      await _db.archiveExpiredDiscounts();

      // --- NOUVEAU : Vérification des expirations de promos ---
      final expiringDiscounts = await _db.getDiscountsExpiringSoon();
      final String today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // Format YYYY-MM-DD

      for (final d in expiringDiscounts) {
        if (d.endDate != null) {
          final String lastNotifKey = 'last_notif_discount_${d.id}';
          final String? lastNotifDate = await _db.getSetting(lastNotifKey);

          if (lastNotifDate != today) {
            getIt<NotificationService>().showDiscountExpiryNotification(
              discountId: d.id,
              name: d.name,
              endDate: d.endDate!,
            );
            await _db.setSetting(lastNotifKey, today);
          }
        }
      }

      // --- NOUVEAU : Vérification des coupons à forte perte ---
      final highLossDiscounts = await _db.getHighLossDiscounts();

      for (final d in highLossDiscounts) {
        final couponCode = d['couponCode'] as String;
        final lossPercentage = d['lossPercentage'] as double;
        final String lastNotifKey = 'last_notif_high_loss_discount_$couponCode';
        final String? lastNotifDate = await _db.getSetting(lastNotifKey);

        if (lastNotifDate != today) {
          getIt<NotificationService>().showHighLossDiscountNotification(
            couponCode: couponCode,
            lossPercentage: lossPercentage,
          );
          await _db.setSetting(lastNotifKey, today);
        }
      }

      unawaited(_checkQuotas());

      // --- NOUVEAU : Surveillance de l'engorgement de la file d'attente ---
      final stats = await getStats();
      final backlogEnabled =
          await _db.getSetting('sync_backlog_notifications_enabled') ?? '1';
      final thresholdStr =
          await _db.getSetting('sync_backlog_threshold') ?? '100';
      final threshold = int.tryParse(thresholdStr) ?? 100;

      if (backlogEnabled == '1' && stats.pendingCount > threshold) {
        getIt<NotificationService>().showSyncBacklogNotification(
          stats.pendingCount,
        );
      } else {
        getIt<NotificationService>().cancelNotification(999);
      }

      String statusMsg = totalErrorCount > 0
          ? '$totalErrorCount erreurs détectées'
          : 'Synchronisé';
      if (uploadTimedOut || !pullFinished) {
        statusMsg += ' (Partiel - Temps limite atteint)';
      }

      _publishProgress(
        (totalErrorCount == 0 && !uploadTimedOut && pullFinished)
            ? SyncStatus.upToDate
            : SyncStatus.partialError,
        message: statusMsg,
        error: firstError,
      );
    } catch (e) {
      debugPrint('SyncService.syncPending error: $e');
      _publishProgress(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Vérifie les quotas Supabase et alerte si on dépasse 90%
  Future<void> _checkQuotas() async {
    if (!_isOnline) return;
    try {
      // Ajout de params: {} pour forcer la reconnaissance de la fonction sans paramètres
      final usage = await _supabase.rpc('get_project_usage', params: {});
      if (usage == null) return;

      final double dbPercent =
          (usage['db_size_bytes'] as int) / (usage['db_limit_bytes'] as int);
      final double storagePercent =
          (usage['storage_size_bytes'] as int) /
          (usage['storage_limit_bytes'] as int);

      if (dbPercent > 0.9 || storagePercent > 0.9) {
        final String resource = dbPercent > 0.9
            ? 'Base de données'
            : 'Stockage (Images)';
        final int currentPercent =
            ((dbPercent > 0.9 ? dbPercent : storagePercent) * 100).toInt();

        getIt<NotificationService>().showQuotaWarningNotification(
          title: '⚠️ Quota Cloud critique ($currentPercent%)',
          body:
              'Votre $resource approche de la limite. Pensez à faire du ménage dans les réglages.',
        );
      }
    } catch (e) {
      // On échoue silencieusement pour ne pas perturber la synchro
      debugPrint('SyncService: Échec check quota: $e');
    }
  }

  /// Isolate pour décoder et préparer les données de la queue
  static Map<String, dynamic> _prepareSyncPayloads(Map<String, dynamic> input) {
    final List<dynamic> pending = input['pending'];
    final String currentShopId = input['currentShopId'];
    final String terminalId = input['terminalId'];

    final Map<String, List<Map<String, dynamic>>> uploads = {};
    final Map<String, List<int>> deletes = {};
    final Map<String, List<int>> queueIdsByGroup = {};

    for (final item in pending) {
      final String entityType = item['entityType'];
      final String action = item['action'];
      final int entityId = item['entityId'];
      final int queueId = item['id'];
      final String? itemShopId = item['shopId'];
      final String shopIdToUse = itemShopId ?? currentShopId;
      final String groupKey = '${entityType}_$action';

      queueIdsByGroup.putIfAbsent(groupKey, () => []).add(queueId);

      if (action == 'delete') {
        deletes.putIfAbsent(entityType, () => []).add(entityId);
      } else {
        final Map<String, dynamic> rawPayload = jsonDecode(item['payload']);

        // TRANSFORMATION ROBUSTE : camelCase -> snake_case
        final Map<String, dynamic> supabasePayload = {};
        rawPayload.forEach((key, value) {
          // Correction des dates : conversion des timestamps int vers ISO string
          dynamic finalValue = value;
          if ((key.toLowerCase().endsWith('at') ||
                  key.toLowerCase().contains('date') ||
                  key == 'createdAt' ||
                  key == 'updatedAt') &&
              value is int) {
            finalValue = DateTime.fromMillisecondsSinceEpoch(
              value,
            ).toIso8601String();
          }

          final snakeKey = key.replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (Match m) => '${m[1]}_${m[2]!.toLowerCase()}',
          );

          // MAPPING SPÉCIFIQUE : line_total (Drift) -> total_ttc (Supabase)
          if (snakeKey == 'line_total' &&
              (entityType == 'sale_item' || entityType == 'sale_items')) {
            supabasePayload['total_ttc'] = finalValue;
          } else {
            supabasePayload[snakeKey] = finalValue;
          }
        });

        // SÉCURITÉ : On retire les IDs locaux et les références distantes
        // pour laisser Supabase gérer ses propres UUIDs.
        supabasePayload.remove('id');
        supabasePayload.remove('remote_id');

        supabasePayload['shop_id'] = shopIdToUse;
        supabasePayload['terminal_id'] = terminalId;
        supabasePayload['local_id'] = entityId;
        // Les produits sont partagés : on ne lie pas la ligne à un terminal spécifique sur Supabase
        if (entityType == 'product' ||
            entityType == 'products' ||
            // NOUVEAU : Pour les produits, le stock_qty est géré par des deltas séparés.
            // Ne pas l'envoyer avec les mises à jour d'attributs pour éviter les conflits.
            // La colonne stock_qty est retirée du payload avant l'appel à upsert_product_attributes_with_conflict_check.
            // Cela garantit que stock_qty n'est mis à jour que via batch_update_product_stock_delta.
            entityType == 'product' ||
            entityType == 'stock_delta' ||
            entityType == 'supplier' ||
            entityType == 'suppliers') {
          supabasePayload.remove('terminal_id');
        }

        uploads.putIfAbsent(entityType, () => []).add(supabasePayload);
      }
    }

    return {
      'uploads': uploads,
      'deletes': deletes,
      'queueIdsByGroup': queueIdsByGroup,
    };
  }

  Future<bool> _pullFromCloud({bool ignoreTimeouts = false}) async {
    if (_shopId.isEmpty) return true;

    try {
      final lastPullStr = await _db.getSetting('last_pull_at');
      final lastPull = lastPullStr != null
          ? DateTime.tryParse(lastPullStr) ?? DateTime(2020)
          : DateTime(2020);
      final currentUserId = _supabase.auth.currentUser?.id ?? '';
      final now = DateTime.now();

      _publishProgress(
        SyncStatus.syncing,
        value: 0.1,
        message: 'Initialisation du téléchargement...',
      );

      // 0. Récupérer le nombre total de produits pour la progression précise
      final response = await _supabase
          .from('products')
          .select('id')
          .eq('shop_id', _shopId)
          .gte('updated_at', lastPull.toIso8601String())
          .count(CountOption.exact);

      final int totalProducts = response.count;

      // 1. Données statiques et légères (Shops, Customers, Sales récentes)
      // On garde Future.wait pour ces tables car leur volume est généralement maîtrisé.
      final results = await Future.wait([
        _supabase.from('shops').select(),
        _supabase.from('customers').select().eq('shop_id', _shopId).limit(1000),
        _supabase
            .from('sales')
            .select()
            .eq('shop_id', _shopId)
            .gte('synced_at', lastPull.toIso8601String())
            .limit(500),
        _supabase
            .from('inventory_sessions')
            .select()
            .eq('shop_id', _shopId)
            .gte('updated_at', lastPull.toIso8601String())
            .limit(200),
        _supabase
            .from('inventory_lines')
            .select()
            .eq('shop_id', _shopId)
            .gte('updated_at', lastPull.toIso8601String())
            .limit(1000),
        _supabase.from('users').select().order('id'),
        _supabase
            .from('categories')
            .select()
            .eq('shop_id', _shopId)
            .order('sort_order'),
        _supabase
            .from('suppliers')
            .select()
            .eq('shop_id', _shopId)
            .gte('updated_at', lastPull.toIso8601String()),
        _supabase
            .from('purchase_orders')
            .select()
            .eq('shop_id', _shopId)
            .limit(500),
        _supabase
            .from('product_variants')
            .select()
            .eq('shop_id', _shopId)
            .gte('updated_at', lastPull.toIso8601String())
            .limit(500),
        _supabase.from('expenses').select().eq('shop_id', _shopId).limit(500),
        _supabase
            .from('sale_items')
            .select()
            .eq('shop_id', _shopId)
            .gte('created_at', lastPull.toIso8601String())
            .limit(1000),
        _supabase.from('discounts').select().eq('shop_id', _shopId),
        _supabase
            .from('payments')
            .select()
            .eq('shop_id', _shopId)
            .gte('paid_at', lastPull.toIso8601String())
            .limit(1000),
        _supabase.from('audit_logs').select().eq('shop_id', _shopId).limit(500),
      ]);

      final mappedInitial = await compute(_handleHeavyMapping, {
        'products': [],
        'transfers': [],
        'shops': results[0],
        'customers': results[1],
        'sales': results[2],
        'inventory_sessions': results[3],
        'inventory_lines': results[4],
        'users': results[5],
        'categories': results[6],
        'suppliers': results[7],
        'purchase_orders': results[8],
        'product_variants': results[9],
        'expenses': results[10], // Correction de l'index
        'sale_items': results[11], // Correction de l'index
        'discounts': results[12], // Correction de l'index
        'payments': results[13], // Correction de l'index
        'audit_logs': results[14], // Correction de l'index
        'currentUserId': currentUserId,
        'currentShopId': _shopId,
      });

      _publishProgress(
        SyncStatus.syncing,
        value: 0.2,
        message: 'Mise à jour des bases de référence...',
      );
      await _db.batch((batch) {
        batch.insertAll(
          _db.shops,
          mappedInitial['shops'] as List<ShopsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.customers,
          mappedInitial['customers'] as List<CustomersCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.sales,
          mappedInitial['sales'] as List<SalesCompanion>,
          mode: InsertMode.insertOrIgnore,
        );
        batch.insertAll(
          _db.inventorySessions,
          mappedInitial['inventory_sessions']
              as List<InventorySessionsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.inventoryLines,
          mappedInitial['inventory_lines'] as List<InventoryLinesCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.users,
          mappedInitial['users'] as List<UsersCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.categories,
          mappedInitial['categories'] as List<CategoriesCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.suppliers,
          mappedInitial['suppliers'] as List<SuppliersCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.purchaseOrders,
          mappedInitial['purchase_orders'] as List<PurchaseOrdersCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.productVariants,
          mappedInitial['product_variants'] as List<ProductVariantsCompanion>,
          mode: InsertMode.insertOrReplace,
        ); // NEW
        batch.insertAll(
          _db.expenses,
          mappedInitial['expenses'] as List<ExpensesCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.saleItems,
          mappedInitial['sale_items'] as List<SaleItemsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.discounts,
          mappedInitial['discounts'] as List<DiscountsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.payments,
          mappedInitial['payments'] as List<PaymentsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
        batch.insertAll(
          _db.auditLogs,
          mappedInitial['audit_logs'] as List<AuditLogsCompanion>,
          mode: InsertMode.insertOrReplace,
        );
      });

      // Laisser l'UI respirer un instant après ce premier gros lot d'insertions
      await Future.delayed(const Duration(milliseconds: 150));

      // --- NOUVEAU : Récupération automatique via la vue pending_transfers_details ---
      try {
        final pendingDetails = await _supabase
            .from('pending_transfers_details')
            .select()
            .eq('target_shop_id', _shopId);

        pendingTransferCount.value = pendingDetails.length;

        for (final row in pendingDetails) {
          debugPrint(
            'SyncService [Vue]: Transfert ${row['reference']} en attente de "${row['source_shop_name']}" '
            '(${row['total_items']} articles, créé le ${row['created_at']})',
          );
        }
      } catch (e) {
        debugPrint(
          'SyncService: Erreur lors de la lecture de la vue des transferts: $e',
        );
      }

      // 2. BOUCLE DE PAGINATION POUR LES PRODUITS
      int productOffset = 0;
      const productBatchSize = 500;
      bool hasMoreProducts = true;
      final pullStartTime = DateTime.now();
      const maxPullDuration = Duration(minutes: 3);
      bool pullTimedOut = false;

      // Le count est déjà un entier non-nul
      final int actualTotalProducts = totalProducts;

      while (hasMoreProducts) {
        if (!ignoreTimeouts &&
            DateTime.now().difference(pullStartTime) > maxPullDuration) {
          debugPrint(
            'SyncService: Temps limite atteint pour le téléchargement des produits.',
          );
          pullTimedOut = true;
          break;
        }

        // Calcul de progression : on part de 0.2 (20%) et on monte jusqu'à 0.8 (80%)
        final progressRatio = actualTotalProducts > 0
            ? (productOffset / actualTotalProducts)
            : 1.0;
        final currentProgressValue = 0.2 + (progressRatio * 0.6);
        _publishProgress(
          SyncStatus.syncing,
          value: currentProgressValue,
          message: 'Produits : $productOffset / $totalProducts',
        );

        final remoteBatch = await _supabase
            .from('products')
            .select()
            .eq('shop_id', _shopId)
            .gte('updated_at', lastPull.toIso8601String())
            .order(
              'updated_at',
              ascending: true,
            ) // Important pour la cohérence du range
            .range(productOffset, productOffset + productBatchSize - 1);

        if (remoteBatch.isEmpty) {
          break;
        }

        final mappedBatch = await compute(_handleHeavyMapping, {
          'products': remoteBatch,
          'sales': [],
          'transfers': [],
          'shops': [],
          'customers': [],
          'currentUserId': currentUserId,
          'currentShopId': _shopId,
        });

        await _db.batch((batch) {
          batch.insertAll(
            _db.products,
            mappedBatch['products'] as List<ProductsCompanion>,
            mode: InsertMode.insertOrReplace,
          );
        });

        // Délai anti-gel : petit repos entre chaque lot de 500 produits
        await Future.delayed(const Duration(milliseconds: 50));

        if (remoteBatch.length < productBatchSize) {
          hasMoreProducts = false;
        } else {
          productOffset += productBatchSize;
        }
      }

      // 3. Transferts de stock (Pagination simplifiée si nécessaire)
      final remoteTransfers = await _supabase
          .from('stock_transfers')
          .select('*, stock_transfer_items(*)')
          .or('source_shop_id.eq.$_shopId,target_shop_id.eq.$_shopId')
          .gte('updated_at', lastPull.toIso8601String())
          .limit(200);

      if (remoteTransfers.isNotEmpty) {
        final mappedTransfers = await compute(_handleHeavyMapping, {
          'products': [],
          'sales': [],
          'shops': [],
          'customers': [],
          'transfers': remoteTransfers,
          'currentUserId': currentUserId,
          'currentShopId': _shopId,
        });
        await _db.batch((batch) {
          batch.insertAll(
            _db.stockTransfers,
            mappedTransfers['transfers'] as List<StockTransfersCompanion>,
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            _db.stockTransferItems,
            mappedTransfers['transferItems']
                as List<StockTransferItemsCompanion>,
            mode: InsertMode.insertOrReplace,
          );
        });
      }

      await _db.setSetting('last_pull_at', now.toIso8601String());
      return !pullTimedOut;
    } catch (e) {
      // Loguer l'erreur pour le débogage (ex: RLS, Réseau)
      debugPrint('SyncService _pullFromCloud error: $e');
      return false;
    }
  }

  /// CETTE MÉTHODE S'EXÉCUTE DANS UN ISOLATE (THREAD SÉPARÉ)
  /// Elle ne peut pas accéder aux variables de la classe, uniquement aux arguments passés.
  static Map<String, List<dynamic>> _handleHeavyMapping(
    Map<String, dynamic> input,
  ) {
    final remoteProducts = input['products'] as List? ?? [];
    final remoteSales = input['sales'] as List? ?? [];
    final remoteTransfers = input['transfers'] as List? ?? [];
    final remoteShops = input['shops'] as List? ?? [];
    final remoteCustomers = input['customers'] as List? ?? [];
    final remoteInventorySessions = input['inventory_sessions'] as List? ?? [];
    final remoteInventoryLines = input['inventory_lines'] as List? ?? [];
    final remoteUsers = input['users'] as List? ?? [];
    final remoteCategories = input['categories'] as List? ?? [];
    final remoteSuppliers = input['suppliers'] as List? ?? [];
    final remotePurchaseOrders = input['purchase_orders'] as List? ?? [];
    final remoteProductVariants =
        input['product_variants'] as List? ??
        []; // Déclaration et initialisation
    final remoteExpenses = input['expenses'] as List? ?? [];
    final remoteSaleItems = input['sale_items'] as List? ?? [];
    final remoteDiscounts = input['discounts'] as List? ?? [];
    final remotePayments = input['payments'] as List? ?? [];
    final remoteAuditLogs = input['audit_logs'] as List? ?? [];
    final currentUserId = input['currentUserId'] as String;
    final currentShopId = input['currentShopId'] as String;

    // 1. Mapping Magasins
    final shops = remoteShops
        .where((s) => s['owner_id'] == currentUserId)
        .map<ShopsCompanion>((s) {
          final sId = s['id'] as String;
          return ShopsCompanion.insert(
            id: sId,
            name: s['name'] ?? 'Magasin',
            address: Value(s['address']),
            isCurrent: Value(sId == currentShopId),
          );
        })
        .toList();

    // 2. Mapping Produits
    final products = remoteProducts.map<ProductsCompanion>((p) {
      return ProductsCompanion.insert(
        id: Value(p['local_id'] as int),
        name: p['name'] ?? '',
        shopId: Value(p['shop_id'] as String?),
        description: Value(p['description'] as String? ?? ''),
        priceHt: (p['price_ht'] as num?)?.toDouble() ?? 0.0,
        taxRate: Value((p['tax_rate'] as num?)?.toDouble() ?? 0.0),
        costPrice: Value((p['cost_price'] as num?)?.toDouble() ?? 0.0),
        stockQty: Value((p['stock_qty'] as num?)?.toInt() ?? 0),
        updatedAt: Value(DateTime.parse(p['updated_at'])),
        categoryId: Value((p['category_id'] as num?)?.toInt()),
        preferredSupplierId: Value(
          (p['preferred_supplier_id'] as num?)?.toInt(),
        ), // NOUVEAU
        isActive: Value(p['is_active'] as bool? ?? true),
        imagePath: Value(
          p['image_path'] as String?,
        ), // Synchronise le chemin texte
      ); // MODIFIED: Removed terminalId from ProductsCompanion
    }).toList();

    // 3. Mapping Ventes
    final sales = remoteSales.map<SalesCompanion>((s) {
      return SalesCompanion.insert(
        id: Value(s['local_id'] as int),
        ref: (s['ref'] as String?) ?? '',
        totalHt: (s['total_ht'] as num?)?.toDouble() ?? 0.0,
        totalTax: (s['total_tax'] as num?)?.toDouble() ?? 0.0,
        totalTtc: (s['total_ttc'] as num?)?.toDouble() ?? 0.0,
        discountType: Value(s['discount_type'] as String? ?? 'fixed'),
        couponCode: Value(s['coupon_code'] as String?),
        amountDue: Value((s['amount_due'] as num?)?.toDouble() ?? 0.0),
        paymentStatus: Value(s['payment_status'] as String? ?? 'paid'),
        status: Value(s['status'] ?? 'completed'),
        createdAt: Value(DateTime.parse(s['created_at'])),
        shopId: Value(s['shop_id'] as String),
        customerId: Value(
          s['customer_id'] as String?,
        ), // Récupère l'ID du client (UUID)
        terminalId: Value(
          s['terminal_id'] as String?,
        ), // Récupère l'ID de l'appareil
        userId: 0,
      );
    }).toList();

    // 4. Mapping Transferts (Logique complexe mise à plat pour insertAll)
    final transfers = <StockTransfersCompanion>[];

    // 5. Mapping Clients
    final customers = remoteCustomers.map<CustomersCompanion>((c) {
      return CustomersCompanion.insert(
        id: Value(c['local_id'] as int), // ID local Drift
        remoteId: Value(c['id'] as String), // UUID Supabase
        shopId: Value(c['shop_id'] as String),
        name: c['name'] ?? '',
        phone: Value(c['phone'] as String?),
        email: Value(c['email'] as String?),
        createdAt: Value(DateTime.parse(c['created_at'])),
      );
    }).toList();

    // 6. Mapping InventorySessions
    final inventorySessions = remoteInventorySessions
        .map<InventorySessionsCompanion>((s) {
          return InventorySessionsCompanion.insert(
            id: Value((s['local_id'] as num).toInt()),
            ref: (s['ref'] as String?) ?? '', // Correction : type String requis
            userId: (s['user_id'] as num?)?.toInt() ?? 0,
            status: Value(s['status'] ?? 'draft'),
            shopId: Value(s['shop_id'] as String?),
            notes: Value(s['notes'] as String? ?? ''),
            totalProducts: Value((s['total_products'] as num?)?.toInt() ?? 0),
            discrepancies: Value((s['discrepancies'] as num?)?.toInt() ?? 0),
            startedAt: Value(DateTime.parse(s['created_at'])),
            completedAt: Value(
              s['completed_at'] != null
                  ? DateTime.parse(s['completed_at'])
                  : null,
            ),
            terminalId: Value(
              s['terminal_id'] as String?,
            ), // Récupère l'origine de la session
          );
        })
        .toList();

    // 7. Mapping InventoryLines
    final inventoryLines = remoteInventoryLines.map<InventoryLinesCompanion>((
      l,
    ) {
      return InventoryLinesCompanion.insert(
        id: Value((l['local_id'] as num).toInt()),
        sessionId: (l['session_id'] as num).toInt(),
        productId: (l['product_id'] as num).toInt(),
        productName:
            (l['product_name'] as String?) ?? '', // Correction : type String
        barcode: Value(l['barcode'] as String?),
        expectedQty: (l['expected_qty'] as num?)?.toInt() ?? 0,
        countedQty: Value((l['counted_qty'] as num?)?.toInt()),
        difference: Value((l['difference'] as num?)?.toInt()),
        defectiveQty: Value((l['defective_qty'] as num?)?.toInt() ?? 0),
        obsoleteQty: Value((l['obsolete_qty'] as num?)?.toInt() ?? 0),
        expiredQty: Value((l['expired_qty'] as num?)?.toInt() ?? 0),
        shopId: Value(l['shop_id'] as String?),
        isValidated: Value(l['is_validated'] ?? false),
        terminalId: Value(l['terminal_id'] as String?),
        notes: Value(l['notes'] as String? ?? ''),
      );
    }).toList();

    // 8. Mapping Utilisateurs
    final users = remoteUsers.map<UsersCompanion>((u) {
      return UsersCompanion.insert(
        id: Value(u['local_id'] as int),
        name: u['name'] ?? '',
        role: Value(u['role'] ?? 'cashier'),
        email: Value(u['email'] as String?),
        supabaseId: Value(u['supabase_id'] as String?),
        shopId: Value(u['shop_id'] as String?),
        isActive: Value(u['is_active'] as bool? ?? true),
        pinHash: u['pin_hash'] ?? 'CLOUD_SYNC',
        pinSalt: Value(u['pin_salt'] ?? ''),
        failedAttempts: Value(u['failed_attempts'] as int? ?? 0),
        lockedUntil: Value(
          u['locked_until'] != null ? DateTime.parse(u['locked_until']) : null,
        ),
      );
    }).toList();

    // 9. Mapping Catégories
    final categories = remoteCategories.map<CategoriesCompanion>((c) {
      return CategoriesCompanion.insert(
        id: Value(c['local_id'] as int),
        name: c['name'] ?? '',
        icon: Value(c['icon'] as String?),
        color: Value(c['color'] ?? '#2196F3'),
        sortOrder: Value((c['sort_order'] as num?)?.toInt() ?? 0),
        shopId: Value(c['shop_id'] as String?),
      );
    }).toList();

    // 10. Mapping Fournisseurs
    final suppliers = remoteSuppliers.map<SuppliersCompanion>((s) {
      return SuppliersCompanion.insert(
        id: Value(s['local_id'] as int),
        name: s['name'] ?? '',
        contactName: Value(s['contact_name']),
        phone: Value(s['phone']),
        email: Value(s['email']),
        address: Value(s['address']),
        notes: Value(s['notes']),
        shopId: Value(s['shop_id'] as String?),
        updatedAt: Value(DateTime.parse(s['updated_at'])),
      );
    }).toList();

    // 11. Mapping Bons de Commande
    final purchaseOrders = remotePurchaseOrders.map<PurchaseOrdersCompanion>((
      p,
    ) {
      return PurchaseOrdersCompanion.insert(
        id: Value(p['local_id'] as int),
        ref: p['ref'] ?? '',
        supplierId: (p['supplier_id'] as num).toInt(),
        status: Value(p['status'] ?? 'pending'),
        totalAmount: Value((p['total_amount'] as num?)?.toDouble() ?? 0.0),
        shopId: Value(p['shop_id'] as String?),
      );
    }).toList();

    // 12. Mapping Dépenses
    final expenses = remoteExpenses.map<ExpensesCompanion>((e) {
      return ExpensesCompanion.insert(
        id: Value(e['local_id'] as int),
        description: e['description'] ?? '',
        amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
        category: e['category'] ?? 'Autre',
        userId: (e['user_id'] as num?)?.toInt() ?? 0,
        date: Value(DateTime.parse(e['date'])),
        imagePath: Value(e['image_path'] as String?), // NOUVEAU
        shopId: Value(e['shop_id'] as String?),
        terminalId: Value(e['terminal_id'] as String?),
      );
    }).toList();

    // 13. Mapping Sale Items (Détails des ventes)
    final saleItems = remoteSaleItems.map<SaleItemsCompanion>((si) {
      return SaleItemsCompanion.insert(
        id: Value(si['local_id'] as int),
        saleId: si['sale_local_id'] as int,
        shopId: Value(si['shop_id'] as String?),
        productId: si['product_id'] as int,
        productName: si['product_name'] ?? '',
        unitPriceHt: (si['unit_price_ht'] as num?)?.toDouble() ?? 0.0,
        taxRate: (si['tax_rate'] as num?)?.toDouble() ?? 0.0,
        quantity: (si['quantity'] as num?)?.toInt() ?? 0,
        discountPct: Value((si['discount_pct'] as num?)?.toDouble() ?? 0.0),
        discountAmount: Value(
          (si['discount_amount'] as num?)?.toDouble() ?? 0.0,
        ),
        lineTotal: (si['total_ttc'] as num?)?.toDouble() ?? 0.0,
        terminalId: Value(si['terminal_id'] as String?),
      );
    }).toList();

    // 14. Mapping Remises
    final discounts = remoteDiscounts.map<DiscountsCompanion>((d) {
      return DiscountsCompanion.insert(
        id: Value(d['local_id'] as int),
        name: d['name'] ?? '',
        type: Value(d['type'] ?? 'percentage'),
        value: (d['value'] as num?)?.toDouble() ?? 0.0,
        minAmount: Value((d['min_amount'] as num?)?.toDouble() ?? 0.0),
        startDate: Value(
          d['start_date'] != null ? DateTime.parse(d['start_date']) : null,
        ),
        endDate: Value(
          d['end_date'] != null ? DateTime.parse(d['end_date']) : null,
        ),
        isActive: Value(d['is_active'] ?? true),
        isArchived: Value(d['is_archived'] ?? false),
        shopId: Value(d['shop_id'] as String?),
      );
    }).toList();

    // 15. Mapping Paiements
    final payments = remotePayments.map<PaymentsCompanion>((p) {
      return PaymentsCompanion.insert(
        id: Value(p['local_id'] as int),
        saleId: p['sale_local_id'] as int,
        shopId: Value(p['shop_id'] as String?),
        method: p['method'] ?? 'cash',
        amount: (p['amount'] as num?)?.toDouble() ?? 0.0,
        changeGiven: Value((p['change_given'] as num?)?.toDouble() ?? 0.0),
        paidAt: Value(DateTime.parse(p['paid_at'])),
        terminalId: Value(p['terminal_id'] as String?),
      );
    }).toList();

    // 16. Mapping Logs d'Audit
    final auditLogs = remoteAuditLogs.map<AuditLogsCompanion>((a) {
      return AuditLogsCompanion.insert(
        id: Value(a['local_id'] as int),
        actorId: (a['actor_id'] as num).toInt(),
        action: a['action'] ?? '',
        targetEntityType: a['target_entity_type'] ?? '',
        shopId: Value(a['shop_id'] as String?),
        targetEntityId: (a['target_entity_id'] as num).toInt(),
        details: Value(a['details'] as String?),
        timestamp: Value(DateTime.parse(a['created_at'])),
      );
    }).toList();

    // 17. Mapping Product Variants (NEW)
    final productVariants = remoteProductVariants.map<ProductVariantsCompanion>(
      (pv) {
        return ProductVariantsCompanion.insert(
          id: Value(pv['local_id'] as int),
          productId: pv['product_local_id'] as int,
          name: pv['name'] ?? '',
          barcode: Value(pv['barcode'] as String?),
          priceModifier: Value(
            (pv['price_modifier'] as num?)?.toDouble() ?? 0.0,
          ),
          stockQty: Value((pv['stock_qty'] as num?)?.toInt() ?? 0),
          isActive: Value(pv['is_active'] as bool? ?? true),
        );
      },
    ).toList();
    final transferItems = <StockTransferItemsCompanion>[];

    for (final t in remoteTransfers) {
      // On ignore les transferts en attente dont nous sommes la source (déjà en local)
      if (t['source_shop_id'] == currentShopId && t['status'] == 'pending') {
        continue;
      }

      final localId = t['local_id'] as int;
      transfers.add(
        StockTransfersCompanion(
          id: Value(localId),
          shopId: Value(t['shop_id'] as String),
          ref: Value((t['ref'] as String?) ?? ''),
          sourceShopId: Value((t['source_shop_id'] as String?) ?? ''),
          targetShopId: Value((t['target_shop_id'] as String?) ?? ''),
          status: Value((t['status'] as String?) ?? 'pending'),
          notes: Value(t['notes'] as String?),
          terminalId: Value(t['terminal_id'] as String?),
          createdAt: Value(DateTime.parse(t['created_at'])),
          receivedAt: Value(
            t['received_at'] != null ? DateTime.parse(t['received_at']) : null,
          ),
        ),
      );

      final items = t['stock_transfer_items'] as List? ?? [];
      for (final item in items) {
        transferItems.add(
          StockTransferItemsCompanion(
            id: Value((item['local_id'] as num).toInt()),
            transferId: Value(localId), // Référence l'ID local du transfert
            shopId: Value(
              t['shop_id'] as String,
            ), // Crucial pour que le destinataire puisse voir les articles
            productId: Value((item['product_id'] as num).toInt()),
            terminalId: Value(item['terminal_id'] ?? t['terminal_id']),
            quantitySent: Value((item['quantity_sent'] as num).toInt()),
            quantityReceived: Value(
              (item['quantity_received'] as num?)?.toInt(),
            ),
          ),
        );
      }
    }

    return {
      'shops': shops,
      'products': products,
      'sales': sales,
      'customers': customers,
      'transfers': transfers,
      'transferItems': transferItems,
      'inventory_sessions': inventorySessions,
      'inventory_lines': inventoryLines,
      'users': users,
      'categories': categories,
      'suppliers': suppliers,
      'purchase_orders': purchaseOrders,
      'product_variants': productVariants, // NEW
      'expenses': expenses,
      'sale_items': saleItems,
      'discounts': discounts,
      'payments': payments,
      'audit_logs': auditLogs,
    };
  }

  String _tableFor(String entityType) => switch (entityType) {
    'sale' => 'sales',
    'audit_log' => 'audit_logs',
    'product' => 'products',
    'sale_item' || 'sale_items' => 'sale_items',
    'cash_session' || 'cash_sessions' => 'cash_sessions',
    'user' || 'users' => 'users',
    'payment' || 'payments' => 'payments',
    'stock_movement' => 'stock_movements',
    'inventory' => 'inventory_sessions',
    'inventory_session' => 'inventory_sessions', // Added for consistency
    'inventory_line' => 'inventory_lines', // Added for consistency
    'stock_transfers' || 'stock_transfer' => 'stock_transfers',
    'stock_transfer_items' || 'stock_transfer_item' => 'stock_transfer_items',
    'category' => 'categories',
    'customer' => 'customers',
    'discount' => 'discounts',
    'supplier' => 'suppliers',
    'purchase_order' => 'purchase_orders',
    'expense' => 'expenses',
    'product_tag' => 'product_tags',
    'stock_delta' => 'products', // L'appel RPC agit sur la table 'products'
    _ => entityType,
  };

  Future<SyncStats> getStats() async {
    final pending = await (_db.select(
      _db.syncQueue,
    )..where((q) => q.status.equals('pending'))).get();
    final errors = await (_db.select(
      _db.syncQueue,
    )..where((q) => q.status.equals('error'))).get();
    final lastPull = await _db.getSetting('last_pull_at');
    return SyncStats(
      pendingCount: pending.length,
      errorCount: errors.length,
      isOnline: _isOnline,
      lastSyncAt: lastPull != null ? DateTime.tryParse(lastPull) : null,
    );
  }

  Future<void> dispose() async {
    _connectivitySub?.cancel();
    _syncTimer?.cancel();
    await _productChannel?.unsubscribe();
    await _transferChannel?.unsubscribe();
    await _statusController.close();
  }

  @visibleForTesting
  String tableForTest(String t) => _tableFor(t);

  @visibleForTesting
  String generateShopIdTest() => _shopId;

  Future<void> cleanupOldEntries() async {
    final now = DateTime.now();
    // On nettoie les succès après 1 jour seulement
    final successCutoff = now.subtract(const Duration(days: 1));
    // On nettoie les erreurs abandonnées (plus de 5 tentatives) après 7 jours.
    // Correction: La variable errorCutoff n'était pas utilisée dans la condition.
    final errorCutoff = now.subtract(const Duration(days: 7));

    await (_db.delete(_db.syncQueue)..where(
          (q) =>
              (q.status.equals('done') &
                  q.updatedAt.isSmallerThanValue(successCutoff)) |
              (q.retryCount.isBiggerOrEqualValue(5) &
                  q.updatedAt.isSmallerThanValue(errorCutoff)),
        ))
        .go();
  }
}

enum SyncStatus { idle, syncing, upToDate, partialError, error }

class SyncProgress {
  final SyncStatus status;
  final double value; // 0.0 à 1.0
  final String message;
  final String? errorMessage;
  final int total;
  final int done;

  const SyncProgress({
    required this.status,
    this.value = 0.0,
    this.message = '',
    this.errorMessage,
    this.total = 0,
    this.done = 0,
  });

  SyncProgress copyWith({
    SyncStatus? status,
    double? value,
    String? message,
    String? errorMessage,
    int? total,
    int? done,
  }) => SyncProgress(
    status: status ?? this.status,
    value: value ?? this.value,
    message: message ?? this.message,
    errorMessage: errorMessage ?? this.errorMessage,
    total: total ?? this.total,
    done: done ?? this.done,
  );
}

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
