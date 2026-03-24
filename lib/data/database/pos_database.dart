// lib/data/database/pos_database.dart
import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:convert';
import 'connection_native.dart'
    if (dart.library.html) 'connection_web.dart';
import 'package:flutter/material.dart' hide Table, Column;
import 'sales_dao.dart';

part 'pos_database.g.dart';

class CashSessionWithUser {
  final CashSession session;
  final User user;

  CashSessionWithUser({required this.session, required this.user});
}

class AuditLogWithActor {
  final AuditLog log;
  final String actorName;

  AuditLogWithActor({required this.log, required this.actorName});
}

class StockTransferItemWithProduct {
  final StockTransferItem item;
  final Product product;

  StockTransferItemWithProduct({required this.item, required this.product});
}

// ─── TABLES ───────────────────────────────────────────────────

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get pinHash => text()();
  // AJOUT : Colonne pour stocker le sel unique de chaque utilisateur.
  TextColumn get pinSalt => text().withDefault(const Constant(''))();
  TextColumn get role => text().withDefault(const Constant('cashier'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get email => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get color => text().withDefault(const Constant('#6366F1'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get priceHt => real()();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  IntColumn get stockAlert => integer().withDefault(const Constant(5))();
  TextColumn get unit => text().withDefault(const Constant('pce'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  RealColumn get loyaltyPoints => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CashSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get startingCash => real()(); // Fond de caisse
  RealColumn get endingCash => real().nullable()(); // Compté à la fin
  RealColumn get expectedCash => real().nullable()(); // Calculé (fond + ventes espèces)
  RealColumn get discrepancy => real().nullable()(); // Ecart
  TextColumn get status => text().withDefault(const Constant('open'))(); // open, closed
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ref => text()();
  IntColumn get cashSessionId => integer().nullable().references(CashSessions, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  RealColumn get totalHt => real()();
  RealColumn get totalTax => real()();
  RealColumn get totalTtc => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  RealColumn get unitPriceHt => real()();
  RealColumn get taxRate => real()();
  IntColumn get quantity => integer()();
  RealColumn get discountPct => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  RealColumn get changeGiven => real().withDefault(const Constant(0.0))();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get type => text()();
  IntColumn get qtyDelta => integer()();
  IntColumn get qtyAfter => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get inventoryRef => text().nullable()();
  DateTimeColumn get movedAt => dateTime().withDefault(currentDateAndTime)();
}

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().unique().references(Sales, #id)();
  TextColumn get format => text().withDefault(const Constant('escpos'))();
  TextColumn get content => text()();
  BoolColumn get isPrinted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get printedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class InventorySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ref => text()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get totalProducts => integer().withDefault(const Constant(0))();
  IntColumn get discrepancies => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class InventoryLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(InventorySessions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get barcode => text().nullable()();
  IntColumn get expectedQty => integer()();
  IntColumn get countedQty => integer().nullable()();
  IntColumn get difference => integer().nullable()();
  BoolColumn get isValidated => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}


// ─── TABLE SYNC QUEUE ─────────────────────────────────────────
// File d'attente locale pour la synchronisation Supabase.
// Chaque écriture (vente, stock, inventaire) crée une entrée ici.
// Le SyncService la vide en arrière-plan quand la connexion est dispo.

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Type d'entité : 'sale' | 'product' | 'stock_movement' | 'inventory'
  TextColumn get entityType => text()();

  // ID local (SQLite) de l'entité concernée
  IntColumn get entityId => integer()();

  // Action à effectuer : 'upsert' | 'delete'
  TextColumn get action => text().withDefault(const Constant('upsert'))();

  // Snapshot JSON de l'entité au moment de l'opération
  TextColumn get payload => text()();

  // Statut : 'pending' | 'syncing' | 'done' | 'error'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  // Nombre de tentatives (max 5, puis abandon)
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // Message d'erreur si status = 'error'
  TextColumn get errorMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── MULTI-MAGASINS & TRANSFERTS ──────────────────────────────

class Shops extends Table {
  TextColumn get id => text()(); // UUID Supabase
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class StockTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ref => text()(); // TRF-YYYYMMDD-XXXX
  TextColumn get sourceShopId => text()();
  TextColumn get targetShopId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, in_transit, completed, rejected
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get receivedAt => dateTime().nullable()();
  
  // Pour la sync Supabase
  TextColumn get remoteId => text().nullable()(); 
}

class StockTransferItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transferId => integer().references(StockTransfers, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantitySent => integer()();
  IntColumn get quantityReceived => integer().nullable()(); // Rempli à la réception
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actorId => integer().references(Users, #id)();
  TextColumn get action => text()(); // 'user_deactivated', 'user_role_changed'
  TextColumn get targetEntityType => text()(); // 'user'
  IntColumn get targetEntityId => integer()();
  TextColumn get details => text().nullable()(); // JSON string for extra info
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// ─── DATABASE ─────────────────────────────────────────────────

@DriftDatabase(tables: [
  Users, Categories, Products, Customers,
  Sales, SaleItems, Payments, StockMovements, Receipts,
  InventorySessions, InventoryLines, AppSettings, CashSessions,
  SyncQueue, Shops, StockTransfers, StockTransferItems, // Ajout des nouvelles tables
  AuditLogs,
], daos: [SalesDao])
class PosDatabase extends _$PosDatabase {
  PosDatabase() : super(openConnection());

  @override
  int get schemaVersion => 7;  // Incrémenté pour Auth Cloud (email/supabaseId)

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seed();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncQueue);
      }
      if (from < 3) {
        await m.createTable(cashSessions);
        await m.addColumn(sales, sales.cashSessionId);
      }
      if (from < 4) {
        await m.createTable(auditLogs);
      }
      if (from < 5) {
        // Ajoute la colonne `pin_salt` à la table `users`.
        await m.addColumn(users, users.pinSalt);
        // NOTE : Pour une application existante, il faudrait une stratégie pour migrer
        // les anciens hashs. Ici, nous nous assurons que les nouveaux utilisateurs
        // et les mises à jour de PIN utiliseront le nouveau système.
      }
      if (from < 6) {
        await m.createTable(shops);
        await m.createTable(stockTransfers);
        await m.createTable(stockTransferItems);
      }
      if (from < 7) {
        await m.addColumn(users, users.email);
        await m.addColumn(users, users.supabaseId);
      }
    },
    beforeOpen: (details) async {
      // SÉCURITÉ STANDARD : On s'assure qu'il y a au moins un admin au démarrage.
      // On ne crée le compte par défaut que si AUCUN admin n'existe.
      final adminCount = await (select(users)..where((u) => u.role.equals('admin'))).get().then((l) => l.length);

      if (adminCount == 0) {
        // Utilise la nouvelle méthode sécurisée pour créer l'admin par défaut.
        await _createDefaultAdmin();
      }
    },
  );

  // NOUVEAU : Méthode centralisée pour créer l'admin par défaut avec un PIN salé.
  Future<void> _createDefaultAdmin() async {
    const adminPin = '0000';
    final salt = _generateSalt();
    final hash = _hashPin(adminPin, salt);
    await into(users).insert(UsersCompanion.insert(
        name: 'Administrateur', pinHash: hash, pinSalt: Value(salt), role: const Value('admin')));
  }

  Future<void> _seed() async {
    // Utilise la nouvelle méthode sécurisée pour créer l'admin initial.
    await _createDefaultAdmin();

    for (final c in ['Alimentation', 'Boissons', 'Hygiène', 'Électronique', 'Autre']) {
      await into(categories).insert(CategoriesCompanion.insert(name: c));
    }
    final defaults = {
      'shop_name': 'Mon Magasin', 'shop_address': '', 'shop_phone': '',
      'currency': 'FCFA', 'currency_symbol': 'F',
      'tax_rate_default': '0.0', 'receipt_footer': 'Merci de votre visite !',
      'loyalty_enabled': '1', 'loyalty_points_rate': '0.01',
      'printer_mac': '', 'printer_name': '', 'low_stock_alert': '1',
    };
    for (final e in defaults.entries) {
      await into(appSettings)
          .insert(AppSettingsCompanion.insert(key: e.key, value: e.value));
    }
  }

  // ── NOUVEAUX HELPERS POUR PIN & SEL ───────────────────

  /// Génère une chaîne de caractères aléatoire (sel).
  String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Hache un PIN avec un sel donné.
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt); // On combine le PIN et le sel
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// SÉCURITÉ : Vérifie si l'utilisateur utilise le mot de passe par défaut "0000".
  /// Doit être utilisé pour afficher une alerte de sécurité bloquante.
  bool isUsingDefaultPin(User user) {
    // Vérifie si le hash correspond à "0000" avec le sel de l'utilisateur
    final defaultHash = _hashPin('0000', user.pinSalt);
    return user.pinHash == defaultHash;
  }

  // ── UTILISATEURS (AUTH) ───────────────────────────────

  /// Vérifie le PIN pour un utilisateur spécifique.
  Future<User?> verifyUserPin(int userId, String pin) {
    return transaction(() async {
      final user = await (select(users)..where((u) => u.id.equals(userId) & u.isActive.equals(true))).getSingleOrNull();
      if (user == null) return null;

      // Le sel peut être vide pour les utilisateurs créés avant la migration.
      if (user.pinSalt.isEmpty) {
        // Logique de secours pour les anciens PINs non salés.
        final legacyHash = sha256.convert(utf8.encode(pin)).toString();
        if (legacyHash == user.pinHash) {
          // IDÉALEMENT : ici, on forcerait la mise à jour du PIN pour le saler.
          // Pour l'instant, on autorise la connexion.
          return user;
        }
      } else {
        // Logique standard pour les PINs salés.
        final currentPinHash = _hashPin(pin, user.pinSalt);
        if (currentPinHash == user.pinHash) {
          return user; // Utilisateur trouvé
        }
      }

      return null; // PIN incorrect
    });
  }

  Future<List<User>> getUsersByRole(String role) {
    return (select(users)..where((u) => u.role.equals(role) & u.isActive.equals(true))).get();
  }

  Stream<List<User>> watchAllUsers() =>
      (select(users)..orderBy([(u) => OrderingTerm.asc(u.name)])).watch();

  Stream<User?> watchUser(int userId) =>
      (select(users)..where((u) => u.id.equals(userId))).watchSingleOrNull();

  /// NOUVEAU : Méthode sécurisée pour créer un utilisateur.
  Future<int> createUserWithPin({required String name, required String pin, required String role}) {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    return into(users).insert(UsersCompanion.insert(
      name: name,
      pinHash: hash,
      pinSalt: Value(salt),
      role: Value(role),
    ));
  }

  /// Synchronise ou crée un utilisateur local à partir d'une connexion Cloud (Supabase).
  Future<User> ensureLocalOwner({required String supabaseId, String? email, String? name}) {
    return transaction(() async {
      // 1. Chercher par ID Supabase (déjà connecté auparavant)
      final existing = await (select(users)..where((u) => u.supabaseId.equals(supabaseId))).getSingleOrNull();
      if (existing != null) return existing;

      // 2. Chercher par email (compte existant localement ?)
      if (email != null) {
         final byEmail = await (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
         if (byEmail != null) {
           // On lie le compte local au compte Cloud
           await (update(users)..where((u) => u.id.equals(byEmail.id))).write(UsersCompanion(supabaseId: Value(supabaseId)));
           // Re-fetch to get the updated user with the new supabaseId
           return (select(users)..where((u) => u.id.equals(byEmail.id))).getSingle();
         }
      }

      // 3. Créer un nouveau compte local "Propriétaire Cloud"
      final id = await into(users).insert(UsersCompanion.insert(
        name: name ?? 'Propriétaire',
        email: Value(email),
        supabaseId: Value(supabaseId),
        role: const Value('owner'),
        pinHash: 'CLOUD_AUTH', // Pas de PIN utilisable localement par défaut
        pinSalt: const Value(''),
      ));
      return (select(users)..where((u) => u.id.equals(id))).getSingle();
    });
  }

  /// NOUVEAU : Méthode sécurisée pour mettre à jour le PIN d'un utilisateur.
  Future<bool> updateUserPin({required int userId, required String newPin}) async {
    final salt = _generateSalt();
    final hash = _hashPin(newPin, salt);
    final updatedRows = await (update(users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(pinHash: Value(hash), pinSalt: Value(salt)));
    return updatedRows > 0;
  }

  // Cette méthode peut toujours être utilisée pour mettre à jour d'autres champs (nom, rôle, etc.)
  Future<int> addUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(UsersCompanion user) =>
      update(users).replace(user);


  Future<int> softDeleteUser(int userId) =>
      (update(users)..where((u) => u.id.equals(userId)))
          .write(const UsersCompanion(isActive: Value(false)));

  // ── AUDIT ─────────────────────────────────────────────

  Future<int> addAuditLog({
    required int actorId,
    required String action,
    required String targetEntityType,
    required int targetEntityId,
    String? details,
  }) {
    return into(auditLogs).insert(AuditLogsCompanion.insert(
      actorId: actorId,
      action: action,
      targetEntityType: targetEntityType,
      targetEntityId: targetEntityId,
      details: Value(details),
    ));
  }

  Stream<List<AuditLogWithActor>> watchAuditLogs() {
    final query = select(auditLogs).join([
      innerJoin(users, users.id.equalsExp(auditLogs.actorId)),
    ]);
    query.orderBy([OrderingTerm.desc(auditLogs.timestamp)]);
    return query.watch().map((rows) => rows.map((row) => AuditLogWithActor(log: row.readTable(auditLogs), actorName: row.readTable(users).name)).toList());
  }

  // ── SESSIONS DE CAISSE ────────────────────────────────

  Future<CashSession?> getCurrentOpenSession() =>
      (select(cashSessions)..where((c) => c.status.equals('open'))).getSingleOrNull();

  Future<int> openCashSession({required int userId, required double startingCash}) {
    return into(cashSessions).insert(CashSessionsCompanion.insert(
      userId: userId,
      startingCash: startingCash,
    ));
  }

  Future<void> closeCashSession({
    required int sessionId,
    required double endingCash,
    required double expectedCash,
    String? notes,
  }) {
    return (update(cashSessions)..where((c) => c.id.equals(sessionId)))
        .write(CashSessionsCompanion(
            endedAt: Value(DateTime.now()),
            endingCash: Value(endingCash),
            expectedCash: Value(expectedCash),
            discrepancy: Value(endingCash - expectedCash),
            status: const Value('closed'),
            notes: notes != null ? Value(notes) : const Value.absent()));
  }

  Stream<List<CashSessionWithUser>> watchAllCashSessions({DateTimeRange? range}) {
    final query = select(cashSessions).join([
      innerJoin(users, users.id.equalsExp(cashSessions.userId))
    ]);

    if (range != null) {
      final endOfDay = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      query.where(cashSessions.startedAt.isBetweenValues(range.start, endOfDay));
    }

    query.orderBy([OrderingTerm.desc(cashSessions.startedAt)]);

    return query.watch().map((rows) => rows.map((row) => CashSessionWithUser(
      session: row.readTable(cashSessions),
      user: row.readTable(users),
    )).toList());
  }



  // ── PRODUITS ──────────────────────────────────────────────────

  Stream<List<Product>> watchActiveProducts({int? categoryId}) =>
      (select(products)
            ..where((p) => categoryId != null
                ? p.isActive.equals(true) & p.categoryId.equals(categoryId)
                : p.isActive.equals(true))
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Product?> getProductByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<List<Product>> searchProducts(String query) =>
      (select(products)
            ..where((p) =>
                p.isActive.equals(true) &
                (p.name.like('%$query%') | p.barcode.like('%$query%')))
            ..limit(50))
          .get();

  Future<List<Product>> getLowStockProducts() =>
      (select(products)
            ..where((p) =>
                p.stockQty.isSmallerOrEqualValue(5) &
                p.isActive.equals(true)))
          .get();

  Stream<List<Product>> watchLowStockProducts() =>
      (select(products)
            ..where((p) =>
                p.stockQty.isSmallerOrEqualValue(5) &
                p.isActive.equals(true)))
          .watch();

  Future<List<String>> getAllProductImagePaths() async {
    final rows = await (select(products)
          ..where((p) => p.imagePath.isNotNull()))
        .get();
    return rows.map((p) => p.imagePath).whereType<String>().toList();
  }

  // ── TRANSFERTS DE STOCK ──────────────────────────────────────

  Future<int> createStockTransfer({
    required String targetShopId,
    required String sourceShopId,
    required List<Map<String, int>> items, // [{productId: 1, qty: 5}]
    String? notes,
  }) async {
    return transaction(() async {
      final now = DateTime.now();
      final ref = 'TRF-${now.year}${_p(now.month)}${_p(now.day)}-${(now.millisecondsSinceEpoch % 10000)}';

      final transferId = await into(stockTransfers).insert(StockTransfersCompanion.insert(
        ref: ref,
        sourceShopId: sourceShopId,
        targetShopId: targetShopId,
        status: const Value('pending'),
        notes: Value(notes),
      ));

      for (final item in items) {
        final pId = item['productId']!;
        final qty = item['qty']!;

        // Créer la ligne de transfert
        await into(stockTransferItems).insert(StockTransferItemsCompanion.insert(
          transferId: transferId,
          productId: pId,
          quantitySent: qty,
        ));

        // Déduire du stock local immédiatement (le stock est "en transit")
        final product = await (select(products)..where((p) => p.id.equals(pId))).getSingle();
        final newQty = product.stockQty - qty;
        
        await updateStock(pId, newQty);
        
        // Audit log du mouvement
        await into(stockMovements).insert(StockMovementsCompanion.insert(
          productId: pId,
          type: 'transfer_out',
          qtyDelta: -qty,
          qtyAfter: newQty,
          reason: Value('Transfert vers $targetShopId ($ref)'),
        ));
      }

      // --- SYNCHRONISATION ---
      // 1. Mettre en file d'attente l'en-tête du transfert
      final transferData = await (select(stockTransfers)..where((t) => t.id.equals(transferId))).getSingle();
      await into(syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'stock_transfers',
        entityId: transferId,
        payload: jsonEncode(transferData.toJson()),
      ));

      // 2. Mettre en file d'attente chaque ligne d'article
      final itemsData = await (select(stockTransferItems)..where((i) => i.transferId.equals(transferId))).get();
      for (final itemData in itemsData) {
        await into(syncQueue).insert(SyncQueueCompanion.insert(
          entityType: 'stock_transfer_items',
          entityId: itemData.id,
          payload: jsonEncode(itemData.toJson()),
        ));
      }
      // Le SyncService sera déclenché automatiquement s'il est en ligne.

      return transferId;
    });
  }

  Stream<List<StockTransfer>> watchIncomingTransfers(String myShopId) {
    return (select(stockTransfers)
      ..where((t) => t.targetShopId.equals(myShopId) & t.status.equals('pending'))
    ).watch();
  }

  /// Surveille le NOMBRE de transferts entrants en attente.
  Stream<int> watchIncomingTransfersCount(String myShopId) {
    return watchIncomingTransfers(myShopId).map((transfers) => transfers.length);
  }

  // Surveille l'historique des transferts envoyés (sortants)
  Stream<List<StockTransfer>> watchOutgoingTransfers(String myShopId) {
    return (select(stockTransfers)
      ..where((t) => t.sourceShopId.equals(myShopId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).watch();
  }

  // Récupère la liste des autres magasins pour le transfert
  Future<List<Shop>> getOtherShops(String myShopId) =>
      (select(shops)..where((s) => s.id.isNotValue(myShopId))).get();

  Future<List<StockTransferItemWithProduct>> getStockTransferItemsWithProducts(int transferId) {
    final query = select(stockTransferItems).join([
      innerJoin(products, products.id.equalsExp(stockTransferItems.productId))
    ])
      ..where(stockTransferItems.transferId.equals(transferId));

    return query.map((row) {
      return StockTransferItemWithProduct(
        item: row.readTable(stockTransferItems),
        product: row.readTable(products),
      );
    }).get();
  }

  /// Valide la réception d'un transfert, met à jour les stocks et le statut.
  Future<void> validateStockTransferReception({
    required int transferId,
    required int userId,
    Map<int, int>? actualQuantities,
  }) async {
    return transaction(() async {
      // 1. Récupérer le transfert et ses lignes
      final transfer = await (select(stockTransfers)..where((t) => t.id.equals(transferId))).getSingle();
      final items = await (select(stockTransferItems)..where((i) => i.transferId.equals(transferId))).get();

      // 2. Mettre à jour le stock pour chaque produit reçu
      for (final item in items) {
        // Quantité reçue réelle (ou par défaut la quantité envoyée si non spécifié)
        final receivedQty = actualQuantities?[item.id] ?? item.quantitySent;

        // Mettre à jour la ligne de transfert avec la quantité reçue
        await (update(stockTransferItems)..where((i) => i.id.equals(item.id)))
            .write(StockTransferItemsCompanion(
          quantityReceived: Value(receivedQty),
        ));

        // Mettre à jour le stock du produit
        final product = await (select(products)..where((p) => p.id.equals(item.productId))).getSingle();
        final newQty = product.stockQty + receivedQty;
        
        await updateStock(item.productId, newQty);

        // 3. Créer un mouvement de stock pour l'audit
        await into(stockMovements).insert(StockMovementsCompanion.insert(
          productId: item.productId,
          userId: Value(userId),
          type: 'transfer_in',
          qtyDelta: receivedQty,
          qtyAfter: newQty,
          reason: Value('Réception transfert ${transfer.ref}'),
        ));
      }

      // 4. Mettre à jour le statut global du transfert
      await (update(stockTransfers)..where((t) => t.id.equals(transferId)))
          .write(StockTransfersCompanion(
        status: Value('completed'),
        receivedAt: Value(DateTime.now()),
      ));

      // --- SYNCHRONISATION ---
      // Mettre en file d'attente les mises à jour pour le cloud

      // 1. En-tête du transfert (statut complété)
      final updatedTransfer = await (select(stockTransfers)..where((t) => t.id.equals(transferId))).getSingle();
      await into(syncQueue).insert(SyncQueueCompanion.insert(
        entityType: 'stock_transfers',
        entityId: transferId,
        payload: jsonEncode(updatedTransfer.toJson()),
      ));

      // 2. Lignes de transfert (quantité reçue mise à jour)
      for (final item in items) {
        final updatedItem = await (select(stockTransferItems)..where((i) => i.id.equals(item.id))).getSingle();
        await into(syncQueue).insert(SyncQueueCompanion.insert(
          entityType: 'stock_transfer_items',
          entityId: updatedItem.id,
          payload: jsonEncode(updatedItem.toJson()),
        ));
      }
    });
  }

  Future<List<InventoryLine>> getInventoryLines(int sessionId) =>
      (select(inventoryLines)
            ..where((l) => l.sessionId.equals(sessionId))
            ..orderBy([(l) => OrderingTerm.asc(l.productName)]))
          .get();

  Stream<List<InventoryLine>> watchInventoryLines(int sessionId) =>
      (select(inventoryLines)
            ..where((l) => l.sessionId.equals(sessionId))
            ..orderBy([(l) => OrderingTerm.asc(l.productName)]))
          .watch();

  /// Enregistre le comptage d'une ligne.
  /// Champs réels dans InventoryLines : countedQty, difference, isValidated, notes
  Future<void> updateInventoryLine({
    required int lineId,
    required int countedQty,
    String? notes,
  }) async {
    final line = await (select(inventoryLines)
          ..where((l) => l.id.equals(lineId)))
        .getSingle();

    await (update(inventoryLines)..where((l) => l.id.equals(lineId)))
        .write(InventoryLinesCompanion(
      countedQty: Value(countedQty),
      difference: Value(countedQty - line.expectedQty),
      isValidated: const Value(true),
      notes: notes != null ? Value(notes) : const Value.absent(),
    ));
  }

  Future<InventoryLine?> getInventoryLineByBarcode(
          int sessionId, String barcode) =>
      (select(inventoryLines)
            ..where((l) =>
                l.sessionId.equals(sessionId) &
                l.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<void> validateInventorySession({
    required int sessionId,
    required int userId,
  }) async {
    return transaction(() async {
      final session = await (select(inventorySessions)
            ..where((s) => s.id.equals(sessionId)))
          .getSingle();
      final lines = await getInventoryLines(sessionId);
      final validated =
          lines.where((l) => l.isValidated && l.countedQty != null).toList();

      int discrepancyCount = 0;
      for (final line in validated) {
        final counted = line.countedQty!;
        final delta = counted - line.expectedQty;
        if (delta == 0) continue;
        discrepancyCount++;

        await (update(products)..where((p) => p.id.equals(line.productId)))
            .write(ProductsCompanion(
          stockQty: Value(counted),
          updatedAt: Value(DateTime.now()),
        ));
        await into(stockMovements).insert(StockMovementsCompanion.insert(
          productId: line.productId,
          userId: Value(userId),
          type: 'inventory',
          qtyDelta: delta,
          qtyAfter: counted,
          reason: Value('Inventaire ${session.ref}'),
          inventoryRef: Value(session.ref),
        ));
      }

      await (update(inventorySessions)
            ..where((s) => s.id.equals(sessionId)))
          .write(InventorySessionsCompanion(
        status: const Value('completed'),
        discrepancies: Value(discrepancyCount),
        completedAt: Value(DateTime.now()),
      ));
    });
  }

  Stream<List<InventorySession>> watchInventorySessions() =>
      (select(inventorySessions)
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .watch();

  // ── PARAMÈTRES ────────────────────────────────────────────────

  Future<String?> getSetting(String key) async =>
      (await (select(appSettings)..where((s) => s.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Future<void> setSetting(String key, String value) async =>
      into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  // ── UTILITAIRES ───────────────────────────────────────────────

  String _p(int n) => n.toString().padLeft(2, '0');

  // ── MÉTHODES MANQUANTES ───────────────────────────────────────

  /// Met à jour le stock d'un produit directement
  Future<void> updateStock(int productId, int newQty) async {
    await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      stockQty: Value(newQty),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Stream des produits actifs avec filtre texte et catégorie
  /// Utilisé par produits_screen.dart via watchProducts(query: ..., categoryId: ...)
  Stream<List<Product>> watchProducts({String query = '', int? categoryId}) {
    return (select(products)
          ..where((p) {
            final active = p.isActive.equals(true);
            if (query.isNotEmpty && categoryId != null) {
              return active &
                  p.categoryId.equals(categoryId) &
                  (p.name.like('%$query%') | p.barcode.like('%$query%'));
            }
            if (query.isNotEmpty) {
              return active &
                  (p.name.like('%$query%') | p.barcode.like('%$query%'));
            }
            if (categoryId != null) {
              return active & p.categoryId.equals(categoryId);
            }
            return active;
          })
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

}