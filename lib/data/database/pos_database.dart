// lib/data/database/pos_database.dart
import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'connection_native.dart' if (dart.library.html) 'connection_web.dart';
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

class PurchaseOrderWithSupplier {
  final PurchaseOrder purchaseOrder;
  final Supplier supplier;

  PurchaseOrderWithSupplier({
    required this.purchaseOrder,
    required this.supplier,
  });
}

class PurchaseOrderItemWithProduct {
  final PurchaseOrderItem item;
  final Product product;

  PurchaseOrderItemWithProduct({required this.item, required this.product});
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
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get email => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  // Sécurité Lockout
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get shopId => text().nullable().references(
    Shops,
    #id,
  )(); // ADDED: For multi-shop support
}

class Discounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text().withDefault(
    const Constant('percentage'),
  )(); // 'percentage' or 'fixed'
  RealColumn get value => real()();
  RealColumn get minAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get usageLimit => integer().nullable()(); // null = illimité
  BoolColumn get limitPerCustomer =>
      boolean().withDefault(const Constant(false))();
  IntColumn get currentUsage => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get rules => text()
      .nullable()(); // Logique JSON : { "type": "bxgy", "buy_qty": 3, "get_qty": 1 }
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get isStackable => boolean().withDefault(const Constant(false))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get description =>
      text().nullable().withDefault(const Constant(''))();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get preferredSupplierId =>
      integer().nullable().references(Suppliers, #id)(); // NOUVEAU
  RealColumn get priceHt => real()();
  RealColumn get taxRate =>
      real().nullable().withDefault(const Constant(0.0))();
  RealColumn get costPrice =>
      real().nullable().withDefault(const Constant(0.0))();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  IntColumn get stockAlert => integer().withDefault(const Constant(5))();
  // TextColumn get terminalId => text().nullable()(); // REMOVED for shared products
  TextColumn get unit => text().withDefault(const Constant('pce'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiryDate => dateTime().nullable()();
}

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ref => text()(); // PO-YYYYMMDD-XXXX
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, ordered, received, cancelled
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get receivedAt => dateTime().nullable()();
}

class PurchaseOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseOrderId => integer().references(PurchaseOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get quantityReceived => integer().nullable()(); // NOUVEAU
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()();
  RealColumn get unitCost => real()();
  RealColumn get lineTotal => real()();
}

class ProductVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get name => text()(); // ex: "Bleu / XL"
  TextColumn get barcode => text().nullable()();
  RealColumn get priceModifier => real().withDefault(const Constant(0.0))();
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  RealColumn get loyaltyPoints => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get shopId => text().nullable()(); // ID du magasin Supabase
  TextColumn get remoteId => text().nullable()(); // UUID du client sur Supabase
}

class CashSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get startingCash => real()(); // Fond de caisse
  RealColumn get endingCash => real().nullable()(); // Compté à la fin
  RealColumn get expectedCash =>
      real().nullable()(); // Calculé (fond + ventes espèces)
  RealColumn get discrepancy => real().nullable()(); // Ecart
  TextColumn get status =>
      text().withDefault(const Constant('open'))(); // open, closed
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()(); // Lié au terminal
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ref => text()();
  IntColumn get cashSessionId =>
      integer().nullable().references(CashSessions, #id)();
  IntColumn get userId =>
      integer().references(Users, #id)(); // L'utilisateur local
  TextColumn get customerId => text().nullable().references(
    Customers,
    #remoteId,
  )(); // UUID du client sur Supabase
  RealColumn get totalHt => real()();
  RealColumn get totalTax => real()();
  RealColumn get totalTtc => real()();
  TextColumn get discountType =>
      text().withDefault(const Constant('fixed'))(); // 'percentage' | 'fixed'
  TextColumn get couponCode => text().nullable()();
  RealColumn get amountDue => real().withDefault(const Constant(0.0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('paid'))();
  RealColumn get refundedAmount => real().withDefault(const Constant(0.0))();
  BoolColumn get isRefunded => boolean().withDefault(const Constant(false))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // NOUVEAU : ID du magasin auquel appartient cette vente
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()();
  // Champs pour la conformité fiscale (NF525 / certification)
  TextColumn get fiscalHash => text().nullable()();
  TextColumn get previousFiscalHash => text().nullable()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  IntColumn get productId =>
      integer().references(Products, #id)(); // ID local du produit
  TextColumn get productName => text()();
  RealColumn get unitPriceHt => real()();
  RealColumn get taxRate => real()();
  IntColumn get quantity => integer()();
  RealColumn get costPriceAtSale => real().withDefault(const Constant(0.0))();
  RealColumn get discountPct => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()();
  TextColumn get barcode => text().nullable()();
  TextColumn get terminalId => text().nullable()();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get method => text()();
  RealColumn get amount => real()();
  RealColumn get changeGiven => real().withDefault(const Constant(0.0))();
  TextColumn get terminalId => text().nullable()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get type => text()();
  IntColumn get qtyDelta => integer()();
  IntColumn get qtyAfter => integer()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get inventoryRef => text().nullable()();
  TextColumn get imagePath =>
      text().nullable()(); // AJOUTÉ : Justification photo
  TextColumn get terminalId => text().nullable()();
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
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get terminalId => text().nullable()(); // Identifiant de l'appareil
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
  IntColumn get defectiveQty => integer().withDefault(const Constant(0))();
  IntColumn get obsoleteQty => integer().withDefault(const Constant(0))();
  IntColumn get expiredQty => integer().withDefault(const Constant(0))();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId =>
      text().nullable()(); // Ajouté pour la synchronisation
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

  TextColumn get shopId => text().nullable().references(Shops, #id)();

  TextColumn get terminalId => text().nullable()();

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

  // Date de la prochaine tentative pour les retries exponentiels
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductRecipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('recipeEntries')
  IntColumn get parentProductId => integer().references(Products, #id)();
  @ReferenceName('ingredientEntries')
  IntColumn get componentProductId => integer().references(Products, #id)();
  RealColumn get quantity => real()(); // ex: 0.5 pour 500g
}

class ParkedCarts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  RealColumn get globalDiscount => real().withDefault(const Constant(0.0))();
  IntColumn get customerId => integer().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get parkedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get cartData => text()(); // Liste des articles sérialisée en JSON
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
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get sourceShopId => text()();
  TextColumn get targetShopId => text()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, in_transit, completed, rejected
  TextColumn get notes => text().nullable()();
  TextColumn get terminalId => text().nullable()();
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
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()();
  IntColumn get quantityReceived =>
      integer().nullable()(); // Rempli à la réception
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actorId => integer().references(Users, #id)();
  TextColumn get action => text()(); // 'user_deactivated', 'user_role_changed'
  TextColumn get targetEntityType => text()(); // 'user'
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()();
  IntColumn get targetEntityId => integer()();
  TextColumn get details => text().nullable()(); // JSON string for extra info
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()(); // 'rent', 'utilities', 'salary', 'other'
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  TextColumn get terminalId => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get imagePath => text().nullable()(); // NOUVEAU

  // Pour la sync Supabase
  TextColumn get remoteId => text().nullable()();
}

class ProductTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withDefault(const Constant('#9E9E9E'))();
  TextColumn get shopId => text().nullable().references(Shops, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── DATABASE ─────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Users,
    Categories,
    Products,
    Customers,
    Sales,
    SaleItems,
    Payments,
    StockMovements,
    Receipts,
    InventorySessions,
    InventoryLines,
    AppSettings,
    CashSessions,
    Discounts,
    SyncQueue,
    Shops,
    StockTransfers,
    StockTransferItems,
    AuditLogs,
    Expenses,
    Suppliers,
    ProductVariants,
    PurchaseOrders,
    PurchaseOrderItems,
    ProductRecipes,
    ParkedCarts,
    ProductTags,
  ],
  daos: [SalesDao],
)
class PosDatabase extends _$PosDatabase {
  PosDatabase() : super(openConnection());

  @override
  int get schemaVersion => 45;

  static Future<File> getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_database.sqlite'));
    debugPrint('--- CHEMIN DE LA BASE DE DONNÉES : ${file.path} ---');
    return file;
  }

  /// Vérifie l'intégrité de la base de données SQLite.
  /// Retourne true si la base est intègre, false ou lève une exception sinon.
  /// Peut être appelé au démarrage ou via un outil d'administration.
  Future<bool> checkIntegrity() async {
    try {
      final result = await customSelect('PRAGMA integrity_check;').get();
      // Le résultat attendu est une seule ligne avec 'ok'
      return result.isNotEmpty &&
          result.first.read<String>('integrity_check') == 'ok';
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'intégrité: $e');
      return false;
    }
  }

  /// Méthode utilitaire pour forcer la suppression de la base au prochain redémarrage
  /// À utiliser uniquement pour le débogage.
  static Future<void> forceDeleteDatabase() async {
    final file = await getDatabaseFile();
    if (await file.exists()) {
      await file.delete();
      debugPrint('--- BASE DE DONNÉES SUPPRIMÉE AVEC SUCCÈS ---');
    }
  }

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
      if (from < 8) {
        await m.addColumn(users, users.failedAttempts);
        await m.addColumn(users, users.lockedUntil);
      }
      if (from < 9) {
        // Ajout de la colonne shopId à la table Sales
        await m.addColumn(sales, sales.shopId);
      }
      if (from < 10) {
        await m.addColumn(sales, sales.terminalId);
        await m.addColumn(saleItems, saleItems.terminalId);
        await m.addColumn(stockMovements, stockMovements.terminalId);
      }
      if (from < 11) {
        // Supprime la colonne terminal_id de la table products
        await customStatement('ALTER TABLE products DROP COLUMN terminal_id;');
      }
      if (from < 12) {
        // Ajout du terminalId à la table Payments
        await m.addColumn(payments, payments.terminalId);
      }
      if (from < 13) {
        // Ajout du terminalId à la table CashSessions
        await m.addColumn(cashSessions, cashSessions.terminalId);
      }
      if (from < 14) {
        await m.addColumn(customers, customers.shopId);
        await m.addColumn(customers, customers.remoteId);
      }
      if (from < 15) {
        await m.addColumn(inventorySessions, inventorySessions.terminalId);
      }
      if (from < 16) {
        await m.addColumn(users, users.shopId);
      }
      if (from < 17) {
        await m.addColumn(cashSessions, cashSessions.shopId);
        await m.addColumn(inventorySessions, inventorySessions.shopId);
        await m.addColumn(inventoryLines, inventoryLines.shopId);
      }
      if (from < 18) {
        await m.addColumn(stockTransfers, stockTransfers.terminalId);
        await m.addColumn(stockTransferItems, stockTransferItems.terminalId);
      }
      if (from < 19) {
        await m.createTable(expenses);
        try {
          await m.addColumn(saleItems, saleItems.costPriceAtSale);
        } catch (e) {
          // On ignore si la colonne existe déjà (cas fréquent en développement)
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 20) {
        await m.createTable(suppliers);
        await m.createTable(productVariants);
      }
      if (from < 21) {
        await m.addColumn(sales, sales.amountDue);
        await m.addColumn(sales, sales.paymentStatus);
      }
      if (from < 22) {
        await m.createTable(purchaseOrders);
        await m.createTable(purchaseOrderItems);
      }
      if (from < 23) {
        await m.addColumn(
          purchaseOrderItems,
          purchaseOrderItems.quantityReceived,
        );
      }
      if (from < 24) {
        await m.addColumn(products, products.preferredSupplierId);
      }
      if (from < 25) {
        await m.addColumn(suppliers, suppliers.notes);
      }
      if (from < 26) {
        await m.addColumn(expenses, expenses.imagePath);
      }
      if (from < 27) {
        await m.addColumn(categories, categories.shopId);
      }
      if (from < 28) {
        await m.createTable(parkedCarts);
      }
      if (from < 29) {
        await m.addColumn(inventoryLines, inventoryLines.defectiveQty);
        await m.addColumn(inventoryLines, inventoryLines.obsoleteQty);
        await m.addColumn(inventoryLines, inventoryLines.expiredQty);
      }
      if (from < 30) {
        await m.addColumn(suppliers, suppliers.updatedAt);
      }
      if (from < 31) {
        await m.addColumn(stockMovements, stockMovements.imagePath);
      }
      if (from < 32) {
        await m.addColumn(sales, sales.fiscalHash);
        await m.addColumn(sales, sales.previousFiscalHash);
      }
      if (from < 33) {
        await m.createTable(discounts);
        try {
          await m.addColumn(sales, sales.discountType);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
        try {
          await m.addColumn(sales, sales.couponCode);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
        try {
          await m.addColumn(saleItems, saleItems.discountAmount);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 34) {
        try {
          await m.addColumn(discounts, discounts.isArchived);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 35) {
        try {
          await m.addColumn(discounts, discounts.usageLimit);
          await m.addColumn(discounts, discounts.currentUsage);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 36) {
        try {
          await m.addColumn(discounts, discounts.limitPerCustomer);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 37) {
        // Nouvelle version du schéma
        try {
          await m.addColumn(syncQueue, syncQueue.nextAttemptAt);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 38) {
        // Utilisation de customStatement pour éviter les blocages de compilation du générateur
        await customStatement(
          'ALTER TABLE stock_movements ADD COLUMN shop_id TEXT;',
        );
        await customStatement(
          'ALTER TABLE stock_transfer_items ADD COLUMN shop_id TEXT;',
        );
      }
      if (from < 39) {
        await customStatement('ALTER TABLE products ADD COLUMN shop_id TEXT;');
        await customStatement(
          'ALTER TABLE sale_items ADD COLUMN shop_id TEXT;',
        );
        await customStatement('ALTER TABLE payments ADD COLUMN shop_id TEXT;');
        await customStatement(
          'ALTER TABLE parked_carts ADD COLUMN shop_id TEXT;',
        );
      }
      if (from < 40) {
        await customStatement(
          'ALTER TABLE sync_queue ADD COLUMN shop_id TEXT;',
        );
      }
      if (from < 41) {
        await customStatement(
          'ALTER TABLE purchase_order_items ADD COLUMN shop_id TEXT;',
        );
        await customStatement(
          'ALTER TABLE purchase_order_items ADD COLUMN terminal_id TEXT;',
        );
      }
      if (from < 42) {
        try {
          await m.addColumn(saleItems, saleItems.barcode);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 43) {
        try {
          await customStatement('ALTER TABLE categories ADD COLUMN icon TEXT;');
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 44) {
        try {
          await m.addColumn(products, products.expiryDate);
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
      }
      if (from < 45) {
        await m.createTable(productTags);
      }
    },
    beforeOpen: (details) async {
      // SÉCURITÉ STANDARD : On s'assure qu'il y a au moins un admin au démarrage.
      // On ne crée le compte par défaut que si AUCUN admin n'existe.
      final adminCount = await (select(
        users,
      )..where((u) => u.role.equals('admin'))).get().then((l) => l.length);

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
    await into(users).insert(
      UsersCompanion(
        name: const Value('Administrateur'),
        pinHash: Value(hash),
        pinSalt: Value(salt),
        role: const Value('admin'),
        shopId:
            const Value.absent(), // L'admin global peut ne pas avoir de boutique initiale
      ),
    );
  }

  Future<void> _seed() async {
    // Utilise la nouvelle méthode sécurisée pour créer l'admin initial.
    await _createDefaultAdmin();

    for (final c in [
      'Alimentation',
      'Boissons',
      'Hygiène',
      'Électronique',
      'Autre',
    ]) {
      await into(categories).insert(CategoriesCompanion.insert(name: c));
    }
    final defaults = {
      'shop_name': 'Gpos',
      'shop_address': '',
      'shop_phone': '',
      'currency': 'FCFA',
      'currency_symbol': 'F',
      'tax_rate_default': '0.0',
      'receipt_footer': 'Merci de votre visite !',
      'loyalty_enabled': '1',
      'loyalty_points_rate': '0.01',
      'printer_mac': '',
      'printer_name': '',
      'low_stock_alert': '1',
    };
    for (final e in defaults.entries) {
      await into(
        appSettings,
      ).insert(AppSettingsCompanion.insert(key: e.key, value: e.value));
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

  /// Vérifie si le PIN fourni appartient à un administrateur ou au propriétaire.
  /// Utilisé pour les "Admin Overrides" sans changer de session.
  Future<User?> verifyAdminOverride(String pin) async {
    return transaction(() async {
      final admins =
          await (select(users)..where(
                (u) =>
                    u.isActive.equals(true) &
                    (u.role.equals('admin') | u.role.equals('owner')),
              ))
              .get();

      for (final admin in admins) {
        String checkHash;
        if (admin.pinSalt.isEmpty) {
          checkHash = sha256.convert(utf8.encode(pin)).toString();
        } else {
          checkHash = _hashPin(pin, admin.pinSalt);
        }

        if (checkHash == admin.pinHash) return admin;
      }
      return null;
    });
  }

  // ── UTILISATEURS (AUTH) ───────────────────────────────

  /// Vérifie le PIN pour un utilisateur spécifique.
  /// Retourne l'utilisateur si succès, lève une Exception si verrouillé ou échec.
  Future<User> verifyUserPin(int userId, String pin) {
    return transaction(() async {
      final user =
          await (select(users)
                ..where((u) => u.id.equals(userId) & u.isActive.equals(true)))
              .getSingleOrNull();

      if (user == null) throw Exception('Utilisateur introuvable ou inactif.');

      // 1. Vérifier si le compte est verrouillé
      if (user.lockedUntil != null &&
          user.lockedUntil!.isAfter(DateTime.now())) {
        final minutes =
            user.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
        throw Exception('Compte verrouillé. Réessayez dans $minutes min.');
      }

      bool isMatch = false;

      // Le sel peut être vide pour les utilisateurs créés avant la migration.
      if (user.pinSalt.isEmpty) {
        final legacyHash = sha256.convert(utf8.encode(pin)).toString();
        isMatch = (legacyHash == user.pinHash);
      } else {
        final currentPinHash = _hashPin(pin, user.pinSalt);
        isMatch = (currentPinHash == user.pinHash);
      }

      if (isMatch) {
        // Succès : Réinitialiser les tentatives
        await (update(users)..where((u) => u.id.equals(userId))).write(
          const UsersCompanion(
            failedAttempts: Value(0),
            lockedUntil: Value(null),
          ),
        );
        return user;
      } else {
        // Échec : Incrémenter les tentatives
        final newAttempts = user.failedAttempts + 1;
        DateTime? newLock;

        if (newAttempts >= 5) {
          // Verrouillage de 5 minutes après 5 échecs
          newLock = DateTime.now().add(const Duration(minutes: 5));
        }

        await (update(users)..where((u) => u.id.equals(userId))).write(
          UsersCompanion(
            failedAttempts: Value(newAttempts),
            lockedUntil: Value(newLock),
          ),
        );

        throw Exception(
          newLock != null
              ? 'Trop de tentatives. Compte verrouillé pour 5 minutes.'
              : 'Code PIN incorrect ($newAttempts/5).',
        );
      }
    });
  }

  Future<List<User>> getUsersByRole(String role, [String? shopId]) {
    final query = select(users)
      ..where((u) => u.role.equals(role) & u.isActive.equals(true));
    if (shopId != null && shopId.isNotEmpty) {
      query.where((u) => u.shopId.equals(shopId));
    }
    return query.get();
  }

  Stream<List<User>> watchAllUsers([String? shopId]) {
    final query = select(users);
    if (shopId != null && shopId.isNotEmpty) {
      query.where((u) => u.shopId.equals(shopId));
    }
    return (query..orderBy([(u) => OrderingTerm.asc(u.name)])).watch();
  }

  Stream<User?> watchUser(int userId) =>
      (select(users)..where((u) => u.id.equals(userId))).watchSingleOrNull();

  /// NOUVEAU : Méthode sécurisée pour créer un utilisateur.
  Future<int> createUserWithPin({
    required String name,
    required String pin,
    required String role,
    required String shopId,
    required int actorId,
  }) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    return transaction(() async {
      final id = await into(users).insert(
        UsersCompanion.insert(
          name: name,
          pinHash: hash,
          pinSalt: Value(salt),
          role: Value(role),
          shopId: Value(shopId),
        ),
      );

      // Log d'audit Elite : On trace qui a créé ce membre du personnel
      await addAuditLog(
        actorId: actorId,
        action: 'user_created',
        targetEntityType: 'user',
        targetEntityId: id,
        details: jsonEncode({'name': name, 'role': role}),
      );

      final userData = await (select(
        users,
      )..where((u) => u.id.equals(id))).getSingle();
      await enqueue(
        entityType: 'user',
        entityId: id,
        shopId: shopId,
        payload: userData.toJson(),
      );
      return id;
    });
  }

  /// Synchronise ou crée un utilisateur local à partir d'une connexion Cloud (Supabase).
  Future<User> ensureLocalOwner({
    required String supabaseId,
    String? email,
    String? name,
  }) {
    return transaction(() async {
      // 1. Chercher par ID Supabase (déjà connecté auparavant)
      final existing = await (select(
        users,
      )..where((u) => u.supabaseId.equals(supabaseId))).getSingleOrNull();
      if (existing != null) return existing;

      // 2. Chercher par email (compte existant localement ?)
      if (email != null) {
        final byEmail = await (select(
          users,
        )..where((u) => u.email.equals(email))).getSingleOrNull();
        if (byEmail != null) {
          // On lie le compte local au compte Cloud
          await (update(users)..where((u) => u.id.equals(byEmail.id))).write(
            UsersCompanion(supabaseId: Value(supabaseId)),
          );
          // Re-fetch to get the updated user with the new supabaseId
          return (select(
            users,
          )..where((u) => u.id.equals(byEmail.id))).getSingle();
        }
      }

      // 3. Créer un nouveau compte local "Propriétaire Cloud"
      final companion = UsersCompanion.insert(
        name: name ?? 'Propriétaire',
        email: Value(email),
        supabaseId: Value(supabaseId),
        role: const Value('owner'),
        pinHash: 'CLOUD_AUTH', // Pas de PIN utilisable localement par défaut
        pinSalt: const Value(''),
      );
      final id = await into(users).insert(companion);
      final newUser = await (select(
        users,
      )..where((u) => u.id.equals(id))).getSingle();

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'user',
          entityId: id,
          shopId: Value(newUser.shopId),
          payload: jsonEncode(newUser.toJson()),
        ),
      );
      return newUser;
    });
  }

  /// NOUVEAU : Méthode sécurisée pour mettre à jour le PIN d'un utilisateur.
  Future<bool> updateUserPin({
    required int userId,
    required String newPin,
  }) async {
    return transaction(() async {
      final salt = _generateSalt();
      final hash = _hashPin(newPin, salt);
      final updatedRows =
          await (update(users)..where((u) => u.id.equals(userId))).write(
            UsersCompanion(pinHash: Value(hash), pinSalt: Value(salt)),
          );

      if (updatedRows > 0) {
        final updatedUser = await (select(
          users,
        )..where((u) => u.id.equals(userId))).getSingle();
        await into(syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: 'user',
            entityId: userId,
            shopId: Value(updatedUser.shopId),
            payload: jsonEncode(updatedUser.toJson()),
          ),
        );
      }
      return updatedRows > 0;
    });
  }

  // Cette méthode peut toujours être utilisée pour mettre à jour d'autres champs (nom, rôle, etc.)
  Future<int> addUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);

  /// Met à jour un utilisateur et enregistre les logs d'audit pour les changements critiques.
  Future<void> updateUserWithAudit({
    required int userId,
    required String name,
    required String role,
    required bool isActive,
    required int actorId,
    String? newPin, // Optionnel: si le PIN doit être mis à jour
  }) {
    return transaction(() async {
      final currentUser = await (select(
        users,
      )..where((u) => u.id.equals(userId))).getSingle();

      // 1. Mettre à jour le PIN si fourni
      if (newPin != null && newPin.isNotEmpty) {
        await updateUserPin(userId: userId, newPin: newPin);
        // Log PIN change
        await addAuditLog(
          actorId: actorId,
          action: 'user_pin_changed',
          targetEntityType: 'user',
          targetEntityId: userId,
          details: jsonEncode({'targetName': currentUser.name}),
        );
      }

      // 2. Mettre à jour les autres champs de l'utilisateur
      final companion = UsersCompanion(
        id: Value(userId),
        name: Value(name),
        role: Value(role),
        isActive: Value(isActive),
      );
      await updateUser(companion);
      final updatedUser = await (select(
        users,
      )..where((u) => u.id.equals(userId))).getSingle();

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          entityType: 'user',
          entityId: userId,
          shopId: Value(updatedUser.shopId),
          payload: jsonEncode(updatedUser.toJson()),
        ),
      );

      // 3. Log des changements de rôle
      if (currentUser.role != role) {
        await addAuditLog(
          actorId: actorId,
          action: 'user_role_changed',
          targetEntityType: 'user',
          targetEntityId: userId,
          details: jsonEncode({
            'from': currentUser.role,
            'to': role,
            'targetName': currentUser.name,
          }),
        );
      }
      // 4. Log des changements d'état actif/inactif
      if (currentUser.isActive != isActive) {
        await addAuditLog(
          actorId: actorId,
          action: isActive ? 'user_activated' : 'user_deactivated',
          targetEntityType: 'user',
          targetEntityId: userId,
          details: jsonEncode({'targetName': currentUser.name}),
        );
      }
    });
  }

  Future<void> softDeleteUser(int userId, int adminId) {
    return transaction(() async {
      await (update(users)..where((u) => u.id.equals(userId))).write(
        const UsersCompanion(isActive: Value(false)),
      );

      // SYNCHRO : Notifier le cloud de la désactivation
      final updatedUser = await (select(
        users,
      )..where((u) => u.id.equals(userId))).getSingle();
      await enqueue(
        entityType: 'user',
        entityId: userId,
        payload: updatedUser.toJson(),
        shopId: updatedUser.shopId,
      );

      await addAuditLog(
        actorId: adminId,
        action: 'user_deactivated',
        targetEntityType: 'user',
        targetEntityId: userId,
        details: 'Désactivation de l\'utilisateur par l\'administrateur',
      );
    });
  }

  // ── AUDIT ─────────────────────────────────────────────

  /// Enregistre un log d'audit et l'envoie vers la file de synchronisation.
  Future<void> addAuditLog({
    required int actorId,
    required String action,
    required String targetEntityType,
    required int targetEntityId,
    String? details,
  }) async {
    final currentShopId = await getSetting('shop_id');
    final currentTerminalId = await getSetting('terminal_id');

    final id = await into(auditLogs).insert(
      AuditLogsCompanion.insert(
        actorId: actorId,
        action: action,
        targetEntityType: targetEntityType,
        shopId: Value(currentShopId),
        terminalId: Value(currentTerminalId),
        targetEntityId: targetEntityId,
        details: Value(details),
      ),
    );

    final logData = await (select(
      auditLogs,
    )..where((l) => l.id.equals(id))).getSingle();
    await enqueue(
      entityType: 'audit_log',
      entityId: id,
      payload: logData.toJson(),
      shopId: currentShopId, // Pass String? directly
      terminalId: currentTerminalId, // Pass String? directly
    );
  }

  Stream<List<AuditLogWithActor>> watchAuditLogs({
    DateTime? start,
    DateTime? end,
  }) {
    final query = select(
      auditLogs,
    ).join([innerJoin(users, users.id.equalsExp(auditLogs.actorId))]);

    if (start != null) {
      query.where(auditLogs.timestamp.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      // On s'assure de prendre jusqu'à la fin de la journée sélectionnée
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      query.where(auditLogs.timestamp.isSmallerOrEqualValue(endOfDay));
    }

    query.orderBy([OrderingTerm.desc(auditLogs.timestamp)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => AuditLogWithActor(
              log: row.readTable(auditLogs),
              actorName: row.readTable(users).name,
            ),
          )
          .toList(),
    );
  }

  /// Surveille spécifiquement les autorisations de remises (Overrides) avec filtre de date
  Stream<List<AuditLogWithActor>> watchOverrideLogs({
    DateTime? start,
    DateTime? end,
  }) {
    final query = select(
      auditLogs,
    ).join([innerJoin(users, users.id.equalsExp(auditLogs.actorId))]);

    query.where(auditLogs.action.equals('discount_override'));
    if (start != null) {
      query.where(auditLogs.timestamp.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      query.where(auditLogs.timestamp.isSmallerOrEqualValue(endOfDay));
    }

    query.orderBy([OrderingTerm.desc(auditLogs.timestamp)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => AuditLogWithActor(
              log: row.readTable(auditLogs),
              actorName: row.readTable(users).name,
            ),
          )
          .toList(),
    );
  }

  // ── SESSIONS DE CAISSE ────────────────────────────────

  Future<CashSession?> getCurrentOpenSession(String terminalId) =>
      (select(cashSessions)..where(
            (c) => c.status.equals('open') & c.terminalId.equals(terminalId),
          ))
          .getSingleOrNull();

  Future<int> openCashSession({
    required int userId,
    required double startingCash,
    required String terminalId,
    required String shopId,
  }) {
    return transaction(() async {
      final id = await into(cashSessions).insert(
        CashSessionsCompanion.insert(
          userId: userId,
          startingCash: startingCash,
          shopId: Value(shopId),
          terminalId: Value(terminalId),
        ),
      );

      // SYNCHRO : Envoyer l'ouverture de session
      final sessionData = await (select(
        cashSessions,
      )..where((c) => c.id.equals(id))).getSingle();
      await enqueue(
        entityType: 'cash_session',
        entityId: id,
        payload: sessionData.toJson(),
        shopId: shopId,
      );

      return id;
    });
  }

  Future<void> closeCashSession({
    required int sessionId,
    required double endingCash,
    required double expectedCash,
    String? notes,
  }) {
    return transaction(() async {
      await (update(cashSessions)..where((c) => c.id.equals(sessionId))).write(
        CashSessionsCompanion(
          endedAt: Value(DateTime.now()),
          endingCash: Value(endingCash),
          expectedCash: Value(expectedCash),
          discrepancy: Value(endingCash - expectedCash),
          status: const Value('closed'),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // SYNCHRO : Envoyer la fermeture
      final sessionData = await (select(
        cashSessions,
      )..where((c) => c.id.equals(sessionId))).getSingle();
      await enqueue(
        entityType: 'cash_session',
        entityId: sessionId,
        payload: sessionData.toJson(),
        shopId: sessionData.shopId,
      );
    });
  }

  Stream<List<CashSessionWithUser>> watchAllCashSessions({
    DateTimeRange? range,
  }) {
    final query = select(
      cashSessions,
    ).join([innerJoin(users, users.id.equalsExp(cashSessions.userId))]);

    if (range != null) {
      final endOfDay = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      query.where(
        cashSessions.startedAt.isBetweenValues(range.start, endOfDay),
      );
    }

    query.orderBy([OrderingTerm.desc(cashSessions.startedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CashSessionWithUser(
              session: row.readTable(cashSessions),
              user: row.readTable(users),
            ),
          )
          .toList(),
    );
  }

  // ── PRODUITS ──────────────────────────────────────────────────

  Stream<List<Product>> watchActiveProducts({int? categoryId}) =>
      (select(products)
            ..where(
              (p) => categoryId != null
                  ? p.isActive.equals(true) & p.categoryId.equals(categoryId)
                  : p.isActive.equals(true),
            )
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Product?> getProductByBarcode(String barcode) =>
      (select(products)
            ..where((p) => p.barcode.equals(barcode) & p.isActive.equals(true)))
          .getSingleOrNull();

  /// Récupère la ligne d'inventaire active (en brouillon) pour un produit donné.
  Future<InventoryLine?> getActiveInventoryLine(int productId) async {
    final shopId = await getSetting('shop_id') ?? '';
    final session =
        await (select(
              inventorySessions,
            )..where((s) => s.shopId.equals(shopId) & s.status.equals('draft')))
            .getSingleOrNull();

    if (session == null) return null;

    return (select(inventoryLines)..where(
          (l) => l.sessionId.equals(session.id) & l.productId.equals(productId),
        ))
        .getSingleOrNull();
  }

  /// Trouve une catégorie par nom pour un magasin donné, ou la crée si elle n'existe pas.
  Future<int> findOrCreateCategoryByName(String name, String shopId) async {
    final existing =
        await (select(categories)
              ..where((c) => c.name.equals(name) & c.shopId.equals(shopId)))
            .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    } else {
      return into(
        categories,
      ).insert(CategoriesCompanion.insert(name: name, shopId: Value(shopId)));
    }
  }

  Future<List<Product>> searchProducts(String query) =>
      (select(products)
            ..where(
              (p) =>
                  p.isActive.equals(true) &
                  (p.name.like('%$query%') | p.barcode.like('%$query%')),
            )
            ..limit(50))
          .get();

  Future<List<Product>> getLowStockProducts() =>
      (select(products)..where(
            (p) =>
                p.stockQty.isSmallerOrEqual(p.stockAlert) &
                p.isActive.equals(true),
          ))
          .get();

  Stream<List<Product>> watchLowStockProducts() =>
      (select(products)..where(
            (p) =>
                p.stockQty.isSmallerOrEqual(p.stockAlert) &
                p.isActive.equals(true),
          ))
          .watch();

  Stream<int> watchProductAlertsCount(String shopId) {
    return (select(products)..where(
          (p) =>
              p.shopId.equals(shopId) &
              p.isActive.equals(true) &
              p.stockQty.isSmallerOrEqual(p.stockAlert),
        ))
        .watch()
        .map((list) => list.length);
  }

  Stream<int> watchCriticalOutOfStockProductsCount(String shopId) {
    return (select(products)..where(
          (p) =>
              p.shopId.equals(shopId) &
              p.isActive.equals(true) &
              p.stockQty.isSmallerOrEqualValue(0),
        )) // Critical: stockQty <= 0
        .watch()
        .map((list) => list.length);
  }

  Future<List<String>> getAllProductImagePaths() async {
    final rows = await (select(
      products,
    )..where((p) => p.imagePath.isNotNull())).get();
    return rows.map((p) => p.imagePath!).whereType<String>().toList();
  }

  /// Récupère tous les chemins de fichiers des photos justificatives stockés en base.
  Future<List<String>> getAllJustificationImagePaths() async {
    final rows = await (select(
      stockMovements,
    )..where((m) => m.imagePath.isNotNull())).get();
    return rows.map((m) => m.imagePath).whereType<String>().toList();
  }

  /// Supprime les fichiers images des justifications de stock datant de plus de [days] jours.
  /// Cela permet de libérer de l'espace tout en conservant l'historique texte des mouvements.
  Future<int> purgeOldJustificationImages(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    // 1. Trouver les mouvements avec image plus vieux que le seuil
    final oldMovements =
        await (select(stockMovements)..where(
              (m) =>
                  m.movedAt.isSmallerThanValue(cutoff) &
                  m.imagePath.isNotNull(),
            ))
            .get();

    int deletedFilesCount = 0;

    for (final movement in oldMovements) {
      if (movement.imagePath != null && movement.imagePath!.isNotEmpty) {
        try {
          final file = File(movement.imagePath!);
          if (await file.exists()) {
            await file.delete();
            deletedFilesCount++;
          }
        } catch (e) {
          debugPrint('Erreur lors de la suppression physique du fichier: $e');
        }
      }
    }

    // 2. Mettre à jour la base pour retirer les références aux fichiers supprimés
    await (update(stockMovements)
          ..where((m) => m.movedAt.isSmallerThanValue(cutoff)))
        .write(const StockMovementsCompanion(imagePath: Value(null)));

    return deletedFilesCount;
  }

  /// Récupère la liste des produits ayant subi un changement de prix depuis une certaine date.
  Future<List<Product>> getProductsWithRecentPriceChanges(
    DateTime since,
  ) async {
    final query = select(auditLogs)
      ..where(
        (l) =>
            l.action.equals('product_price_changed') &
            l.targetEntityType.equals('product') &
            l.timestamp.isBiggerOrEqualValue(since),
      );

    final logs = await query.get();
    final ids = logs.map((l) => l.targetEntityId).toSet();

    if (ids.isEmpty) return [];
    return (select(products)..where((p) => p.id.isIn(ids))).get();
  }

  /// Récupère les remises actives qui expirent dans les prochaines 24 heures.
  Future<List<Discount>> getDiscountsExpiringSoon() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return (select(discounts)..where(
          (d) =>
              d.isActive.equals(true) &
              d.endDate.isBetweenValues(now, tomorrow),
        ))
        .get();
  }

  /// Vérifie si un client a déjà utilisé un coupon spécifique dans une vente complétée.
  Future<bool> checkCouponAlreadyUsedByCustomer(
    int customerLocalId,
    String couponCode,
  ) async {
    // 1. Récupérer le remoteId (UUID) du client car la table Sales utilise les IDs Supabase
    final customer = await (select(
      customers,
    )..where((c) => c.id.equals(customerLocalId))).getSingleOrNull();
    if (customer?.remoteId == null) return false;

    // 2. Chercher une vente existante avec ce client et ce code
    final used =
        await (select(sales)..where(
              (s) =>
                  s.customerId.equals(customer!.remoteId!) &
                  s.couponCode.equals(couponCode) &
                  s.status.equals('completed'),
            ))
            .getSingleOrNull();
    return used != null;
  }

  /// Récupère les statistiques d'utilisation des coupons pour une période donnée.
  Future<List<Map<String, dynamic>>> getCouponUsageStats(
    DateTime start,
    DateTime end,
  ) async {
    final shopId = await getSetting('shop_id') ?? '';

    // Nous filtrons les ventes terminées avec un coupon sur la période
    final query = select(sales)
      ..where(
        (s) =>
            s.shopId.equals(shopId) &
            s.couponCode.isNotNull() &
            s.status.equals('completed') &
            s.createdAt.isBetweenValues(start, end),
      );

    final results = await query.get();
    final Map<String, Map<String, dynamic>> stats = {};

    for (final s in results) {
      final code = s.couponCode!;
      stats.putIfAbsent(
        code,
        () => {'code': code, 'count': 0, 'discount': 0.0, 'revenue': 0.0},
      );
      stats[code]!['count'] = (stats[code]!['count'] as int) + 1;
      stats[code]!['discount'] =
          (stats[code]!['discount'] as double) + s.discountAmount;
      stats[code]!['revenue'] =
          (stats[code]!['revenue'] as double) + s.totalTtc;
    }

    return stats.values.toList();
  }

  /// Récupère les coupons qui génèrent des remises excessives (> 20% du CA) sur les 30 derniers jours.
  Future<List<Map<String, dynamic>>> getHighLossDiscounts() async {
    final shopId = await getSetting('shop_id') ?? '';
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    // Utilisation de customSelect pour une agrégation complexe avec HAVING
    final query = customSelect(
      'SELECT coupon_code, SUM(discount_amount) as total_discount, SUM(total_ttc) as total_revenue '
      'FROM sales '
      'WHERE shop_id = ? AND coupon_code IS NOT NULL AND status = ? AND created_at >= ? '
      'GROUP BY coupon_code '
      'HAVING SUM(total_ttc) > 0 AND SUM(discount_amount) > (0.20 * SUM(total_ttc))',
      variables: [
        Variable(shopId),
        const Variable('completed'),
        Variable(thirtyDaysAgo),
      ],
    );

    final results = await query.get();

    return results
        .map(
          (row) => {
            'couponCode': row.read<String>('coupon_code'),
            'lossPercentage':
                (row.read<double>('total_discount') /
                    row.read<double>('total_revenue')) *
                100,
          },
        )
        .toList();
  }

  /// Archive toutes les remises expirées qui ne le sont pas encore.
  Future<void> archiveExpiredDiscounts() async {
    final now = DateTime.now();
    await transaction(() async {
      final toArchive =
          await (select(discounts)..where(
                (d) =>
                    d.isArchived.equals(false) &
                    d.endDate.isSmallerThanValue(now),
              ))
              .get();

      if (toArchive.isEmpty) return;

      for (final d in toArchive) {
        await (update(discounts)..where((tbl) => tbl.id.equals(d.id))).write(
          const DiscountsCompanion(isArchived: Value(true)),
        );

        final updated = await (select(
          discounts,
        )..where((tbl) => tbl.id.equals(d.id))).getSingle();
        await enqueue(
          entityType: 'discount',
          entityId: d.id,
          payload: updated.toJson(),
          shopId: updated.shopId,
        );
      }
    });
  }

  // ── TRANSFERTS DE STOCK ──────────────────────────────────────

  Future<int> createStockTransfer({
    required String targetShopId,
    required String sourceShopId,
    required List<Map<String, int>> items, // [{productId: 1, qty: 5}]
    required String terminalId, // Ajouté
    String? notes,
  }) async {
    return transaction(() async {
      final now = DateTime.now();
      final ref =
          'TRF-${now.year}${_p(now.month)}${_p(now.day)}-${(now.millisecondsSinceEpoch % 10000)}';

      final transferId = await into(stockTransfers).insert(
        StockTransfersCompanion.insert(
          ref: ref,
          shopId: sourceShopId,
          sourceShopId: sourceShopId,
          targetShopId: targetShopId,
          status: const Value('pending'),
          terminalId: Value(terminalId),
          notes: Value(notes),
        ),
      );

      for (final item in items) {
        final pId = item['productId']!;
        final qty = item['qty']!;

        // Créer la ligne de transfert
        await into(stockTransferItems).insert(
          StockTransferItemsCompanion.insert(
            transferId: transferId,
            productId: pId,
            shopId: Value(sourceShopId),
            terminalId: Value(terminalId),
            quantitySent: qty,
          ),
        );

        // Déduire du stock local immédiatement (le stock est "en transit")
        final product = await (select(
          products,
        )..where((p) => p.id.equals(pId))).getSingle();
        final newQty = product.stockQty - qty;

        await updateStock(pId, -qty); // Déduire le stock localement

        // Audit log du mouvement
        final movementId = await into(stockMovements).insert(
          StockMovementsCompanion(
            productId: Value(pId),
            shopId: Value(sourceShopId),
            type: const Value('transfer_out'),
            qtyDelta: Value(-qty),
            terminalId: Value(terminalId),
            qtyAfter: Value(newQty),
            reason: Value('Transfert vers $targetShopId ($ref)'),
          ),
        );

        // SYNCHRONISATION DU MOUVEMENT (Audit)
        final movementData = await (select(
          stockMovements,
        )..where((m) => m.id.equals(movementId))).getSingle();
        await enqueue(
          entityType: 'stock_movement',
          entityId: movementId,
          payload: movementData.toJson(),
        );
      }

      // --- SYNCHRONISATION : Utilisation de la méthode enqueue ---
      // 1. Mettre en file d'attente l'en-tête du transfert (upsert)
      final transferData = await (select(
        stockTransfers,
      )..where((t) => t.id.equals(transferId))).getSingle();
      await enqueue(
        entityType: 'stock_transfer',
        entityId: transferId,
        payload: transferData.toJson(),
      );

      // 2. Mettre en file d'attente chaque ligne d'article (upsert)
      final itemsData = await (select(
        stockTransferItems,
      )..where((i) => i.transferId.equals(transferId))).get();
      for (final itemData in itemsData) {
        await enqueue(
          entityType: 'stock_transfer_item',
          entityId: itemData.id,
          payload: itemData.toJson(),
        );
      }

      return transferId;
    });
  }

  Stream<List<StockTransfer>> watchIncomingTransfers(
    String myShopId, {
    bool onlyNew = false,
  }) {
    final query = select(stockTransfers)
      ..where((t) => t.targetShopId.equals(myShopId));

    if (onlyNew) {
      query.where((t) => t.status.equals('pending'));
    } else {
      query.where(
        (t) => t.status.equals('pending') | t.status.equals('in_transit'),
      );
    }

    return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Surveille le NOMBRE de transferts entrants en attente.
  Stream<int> watchIncomingTransfersCount(String myShopId) {
    // Le badge ne compte que les transferts strictement au statut 'pending'
    return (select(stockTransfers)..where(
          (t) => t.targetShopId.equals(myShopId) & t.status.equals('pending'),
        ))
        .watch()
        .map((transfers) => transfers.length);
  }

  /// Marque tous les transferts entrants comme 'vus' (in_transit) pour effacer le badge.
  Future<void> markIncomingTransfersAsSeen(String shopId) async {
    return transaction(() async {
      final pending =
          await (select(stockTransfers)..where(
                (t) =>
                    t.targetShopId.equals(shopId) & t.status.equals('pending'),
              ))
              .get();

      for (final transfer in pending) {
        await (update(stockTransfers)..where((t) => t.id.equals(transfer.id)))
            .write(const StockTransfersCompanion(status: Value('in_transit')));

        // On synchronise le changement de statut vers Supabase
        final updated = await (select(
          stockTransfers,
        )..where((t) => t.id.equals(transfer.id))).getSingle();
        await enqueue(
          entityType: 'stock_transfer',
          entityId: transfer.id,
          payload: updated.toJson(),
          shopId: updated.shopId,
        );
      }
    });
  }

  // Surveille l'historique des transferts envoyés (sortants)
  Stream<List<StockTransfer>> watchOutgoingTransfers(String myShopId) {
    return (select(stockTransfers)
          ..where((t) => t.sourceShopId.equals(myShopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // Récupère la liste des autres magasins pour le transfert
  Future<List<Shop>> getOtherShops(String myShopId) =>
      (select(shops)..where((s) => s.id.isNotValue(myShopId))).get();

  Future<List<StockTransferItemWithProduct>> getStockTransferItemsWithProducts(
    int transferId,
  ) {
    final query = select(stockTransferItems).join([
      leftOuterJoin(
        products,
        products.id.equalsExp(stockTransferItems.productId),
      ),
    ])..where(stockTransferItems.transferId.equals(transferId));

    return query.map((row) {
      final item = row.readTable(stockTransferItems);
      final product = row.readTableOrNull(products);
      return StockTransferItemWithProduct(
        item: item,
        product:
            product ??
            Product(
              id: item.productId,
              name: 'Produit Inconnu (ID: ${item.productId})',
              priceHt: 0,
              stockQty: 0,
              stockAlert: 0,
              unit: 'pce',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      );
    }).get();
  }

  /// Valide la réception d'un transfert, met à jour les stocks et le statut.
  Future<void> validateStockTransferReception({
    required int transferId,
    required int userId,
    Map<int, int>? actualQuantities,
  }) async {
    final int tId =
        transferId; // Copie locale pour éviter les conflits de nommage Drift
    final myShopId = await getSetting('shop_id') ?? '';
    final myTerminalId = await getSetting('terminal_id') ?? '';
    return transaction(() async {
      // 1. Récupérer le transfert et ses lignes
      final transfer = await (select(
        stockTransfers,
      )..where((t) => t.id.equals(tId))).getSingle();
      final items = await (select(
        stockTransferItems,
      )..where((i) => i.transferId.equals(tId))).get();

      // 2. Mettre à jour le stock pour chaque produit reçu
      for (final item in items) {
        // Quantité reçue réelle (ou par défaut la quantité envoyée si non spécifié)
        final receivedQty = actualQuantities?[item.id] ?? item.quantitySent;

        // Mettre à jour la ligne de transfert avec la quantité reçue
        await (update(
          stockTransferItems,
        )..where((i) => i.id.equals(item.id))).write(
          StockTransferItemsCompanion(quantityReceived: Value(receivedQty)),
        );

        // Mettre à jour le stock du produit
        final product = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingle();
        final newQty = product.stockQty + receivedQty;

        await updateStock(
          item.productId,
          receivedQty,
        ); // Ajouter le stock localement

        // 3. Créer un mouvement de stock pour l'audit
        final int mRowId = await into(stockMovements).insert(
          StockMovementsCompanion(
            productId: Value(item.productId),
            shopId: Value(myShopId),
            userId: Value(userId),
            type: const Value('transfer_in'),
            qtyDelta: Value(receivedQty),
            qtyAfter: Value(newQty),
            terminalId: Value(myTerminalId),
            reason: Value('Réception transfert ${transfer.ref}'),
          ),
        );

        // SYNCHRONISATION DU MOUVEMENT (Audit réception)
        final movementData = await (select(
          stockMovements,
        )..where((m) => m.id.equals(mRowId))).getSingle();
        await enqueue(
          entityType: 'stock_movement',
          entityId: mRowId,
          payload: movementData.toJson(),
        );
      }

      // 4. Mettre à jour le statut global du transfert
      await (update(stockTransfers)..where((t) => t.id.equals(tId))).write(
        StockTransfersCompanion(
          status: const Value('completed'),
          receivedAt: Value(DateTime.now()),
        ),
      );

      // --- SYNCHRONISATION ---
      // Mettre en file d'attente les mises à jour pour le cloud

      // 1. En-tête du transfert (statut complété)
      final updatedTransfer = await (select(
        stockTransfers,
      )..where((t) => t.id.equals(tId))).getSingle();
      await enqueue(
        entityType: 'stock_transfer',
        entityId: tId,
        payload: updatedTransfer.toJson(),
        shopId: updatedTransfer.shopId,
      );

      // 2. Lignes de transfert (quantité reçue mise à jour)
      for (final item in items) {
        final itemData = await (select(
          stockTransferItems,
        )..where((i) => i.id.equals(item.id))).getSingle();
        await enqueue(
          entityType: 'stock_transfer_item',
          entityId: itemData.id,
          payload: itemData.toJson(),
          shopId: itemData.shopId,
        );
      }
    });
  }

  /// Récupère la liste des fournisseurs du magasin.
  Future<List<Supplier>> getSuppliers(String shopId) =>
      (select(suppliers)..where((s) => s.shopId.equals(shopId))).get();

  /// Ajoute ou met à jour un produit et retourne l'entité créée ou mise à jour.
  Future<Product> upsertProduct(ProductsCompanion product) async {
    final id = await into(products).insertOnConflictUpdate(product);
    final data = await (select(
      products,
    )..where((p) => p.id.equals(id))).getSingle();
    await enqueue(
      entityType: 'product',
      entityId: id,
      payload: data.toJson(),
      shopId: data.shopId,
    );
    return data;
  }

  /// Ajoute ou met à jour une promotion et enfile la synchronisation.
  Future<Discount> upsertDiscount(DiscountsCompanion discount) async {
    final id = await into(discounts).insertOnConflictUpdate(discount);
    final data = await (select(
      discounts,
    )..where((d) => d.id.equals(id))).getSingle();
    await enqueue(
      entityType: 'discount',
      entityId: id,
      payload: data.toJson(),
      shopId: data.shopId,
    );
    return data;
  }

  /// Supprime une promotion.
  Future<void> deleteDiscount(int id) async {
    await (delete(discounts)..where((d) => d.id.equals(id))).go();
    final shopId = await getSetting('shop_id');
    await enqueue(
      entityType: 'discount',
      entityId: id,
      action: 'delete',
      shopId: shopId,
      payload: {},
    );
  }

  /// Insère ou met à jour une liste de produits en batch.
  /// Gère la création de catégories si elles n'existent pas.
  Future<void> batchUpsertProducts(
    List<ProductsCompanion> productsCompanions,
  ) async {
    final shopId = await getSetting('shop_id') ?? '';
    final terminalId = await getSetting('terminal_id') ?? '';

    await transaction(() async {
      for (final productCompanion in productsCompanions) {
        // Assurez-vous que le shopId est toujours présent pour la recherche et l'insertion
        // Tenter de trouver le produit existant par code-barres ou nom
        Product? existingProduct;
        if (productCompanion.barcode.value != null &&
            productCompanion.barcode.value!.isNotEmpty) {
          existingProduct =
              await (select(products)..where(
                    (p) =>
                        p.barcode.equals(productCompanion.barcode.value!) &
                        p.shopId.equals(shopId),
                  ))
                  .getSingleOrNull();
        }
        if (existingProduct == null && productCompanion.name.value.isNotEmpty) {
          existingProduct =
              await (select(products)..where(
                    (p) =>
                        p.name.equals(productCompanion.name.value) &
                        p.shopId.equals(shopId),
                  ))
                  .getSingleOrNull();
        }

        int productId;
        ProductsCompanion finalCompanion;

        if (existingProduct != null) {
          // Mettre à jour le produit existant
          finalCompanion = productCompanion.copyWith(
            id: Value(existingProduct.id),
            updatedAt: Value(DateTime.now()),
            shopId: Value(shopId), // S'assurer que shopId est défini
          );
          await update(products).replace(finalCompanion);
          productId = existingProduct.id;
        } else {
          // Insérer un nouveau produit
          finalCompanion = productCompanion.copyWith(
            createdAt: Value(
              DateTime.now(),
            ), // Définir createdAt pour les nouveaux produits
            updatedAt: Value(DateTime.now()),
            shopId: Value(shopId), // S'assurer que shopId est défini
          );
          productId = await into(products).insert(finalCompanion);
        }

        // Mettre en file d'attente pour la synchronisation
        final updatedProduct = await (select(
          products,
        )..where((p) => p.id.equals(productId))).getSingle();
        await enqueue(
          entityType: 'product',
          entityId: productId,
          payload: updatedProduct.toJson(),
          shopId: shopId,
          terminalId: terminalId,
        );
      }
    });
  }

  /// Ajoute ou met à jour un fournisseur et enfile la synchronisation.
  Future<Supplier> upsertSupplier(SuppliersCompanion supplier) async {
    final id = await into(suppliers).insertOnConflictUpdate(supplier);
    final data = await (select(
      suppliers,
    )..where((s) => s.id.equals(id))).getSingle();
    await enqueue(
      entityType: 'supplier',
      entityId: id,
      payload: data.toJson(),
      shopId: data.shopId,
    );
    return data;
  }

  /// Supprime un fournisseur.
  Future<void> deleteSupplier(int id) async {
    await (delete(suppliers)..where((s) => s.id.equals(id))).go();
    // Note: Dans un système complet, on devrait gérer les FK ou faire du soft delete.
    final shopId = await getSetting('shop_id');
    await enqueue(
      entityType: 'supplier',
      entityId: id,
      action: 'delete',
      shopId: shopId,
      payload: {},
    );
  }

  /// Récupère un fournisseur par son ID local.
  Future<Supplier?> getSupplierById(int id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Ajoute ou met à jour une dépense et enfile la synchronisation.
  Future<Expense> upsertExpense(ExpensesCompanion expense) async {
    final id = await into(expenses).insertOnConflictUpdate(expense);
    final data = await (select(
      expenses,
    )..where((e) => e.id.equals(id))).getSingle();
    await enqueue(
      entityType: 'expense',
      entityId: id,
      payload: data.toJson(),
      shopId: data.shopId,
    );
    return data;
  }

  /// Supprime une dépense localement et sur le Cloud.
  Future<void> deleteExpense(int id) async {
    await (delete(expenses)..where((e) => e.id.equals(id))).go();
    final shopId = await getSetting('shop_id');
    await enqueue(
      entityType: 'expense',
      entityId: id,
      action: 'delete',
      shopId: shopId,
      payload: {},
    );
  }

  /// Surveille les dépenses d'un magasin spécifique.
  Stream<List<Expense>> watchExpenses(
    String shopId, {
    DateTime? from,
    DateTime? to,
  }) {
    final query = select(expenses);
    if (shopId.isNotEmpty) {
      query.where((e) => e.shopId.equals(shopId));
    }

    if (from != null) {
      query.where((e) => e.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      query.where((e) => e.date.isSmallerOrEqualValue(endOfDay));
    }

    return (query..orderBy([(e) => OrderingTerm.desc(e.date)])).watch();
  }

  /// Crée un nouveau bon de commande fournisseur.
  Future<int> createPurchaseOrder({
    required int supplierId,
    required String shopId,
    required List<Map<String, dynamic>> items, // [{productId, qty, unitCost}]
    required String terminalId, // ADDED
  }) async {
    return transaction(() async {
      final now = DateTime.now();
      final ref =
          'BC-${now.year}${_p(now.month)}${_p(now.day)}-${(now.millisecondsSinceEpoch % 10000)}';

      double total = 0;
      for (var item in items) {
        total += (item['qty'] as int) * (item['unitCost'] as double);
      }

      final poId = await into(purchaseOrders).insert(
        PurchaseOrdersCompanion.insert(
          ref: ref,
          supplierId: supplierId,
          status: const Value('pending'),
          totalAmount: Value(total),
          shopId: Value(shopId),
          createdAt: Value(now),
        ),
      );

      for (final item in items) {
        final itemId = await into(purchaseOrderItems).insert(
          PurchaseOrderItemsCompanion.insert(
            purchaseOrderId: poId,
            productId: item['productId'],
            quantity: item['qty'],
            unitCost: item['unitCost'],
            lineTotal: (item['qty'] as int) * (item['unitCost'] as double),
            shopId: Value(shopId), // ADDED
            terminalId: Value(terminalId), // ADDED
          ),
        );
        // Envoi de chaque ligne au cloud
        final itemData = await (select(
          purchaseOrderItems,
        )..where((i) => i.id.equals(itemId))).getSingle();
        await enqueue(
          entityType: 'purchase_order_item',
          entityId: itemId,
          payload: itemData.toJson(),
          shopId: shopId,
        );
      }

      // Synchronisation
      final poData = await (select(
        purchaseOrders,
      )..where((p) => p.id.equals(poId))).getSingle();
      await enqueue(
        entityType: 'purchase_order',
        entityId: poId,
        payload: poData.toJson(),
        shopId: shopId,
      );

      return poId;
    });
  }

  /// Surveille les bons de commande en attente avec les informations du fournisseur.
  Stream<List<PurchaseOrderWithSupplier>> watchPendingPurchaseOrders() =>
      watchPurchaseOrders(status: 'pending');

  /// Surveille les bons de commande avec filtrage optionnel par statut.
  Stream<List<PurchaseOrderWithSupplier>> watchPurchaseOrders({
    String? status,
  }) {
    final query = select(purchaseOrders).join([
      innerJoin(suppliers, suppliers.id.equalsExp(purchaseOrders.supplierId)),
    ]);

    if (status != null) {
      query.where(purchaseOrders.status.equals(status));
    }

    query.orderBy([OrderingTerm.desc(purchaseOrders.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PurchaseOrderWithSupplier(
          purchaseOrder: row.readTable(purchaseOrders),
          supplier: row.readTable(suppliers),
        );
      }).toList();
    });
  }

  /// Récupère les bons de commande pour une période donnée (incluant les fournisseurs).
  Future<List<PurchaseOrderWithSupplier>> getPurchaseOrdersForPeriod(
    DateTime start,
    DateTime end, {
    String? shopId,
  }) async {
    final query = select(purchaseOrders).join([
      innerJoin(suppliers, suppliers.id.equalsExp(purchaseOrders.supplierId)),
    ]);

    query.where(purchaseOrders.createdAt.isBetweenValues(start, end));
    if (shopId != null && shopId.isNotEmpty) {
      query.where(purchaseOrders.shopId.equals(shopId));
    }

    query.orderBy([OrderingTerm.asc(purchaseOrders.createdAt)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => PurchaseOrderWithSupplier(
            purchaseOrder: row.readTable(purchaseOrders),
            supplier: row.readTable(suppliers),
          ),
        )
        .toList();
  }

  /// Récupère les articles d'un bon de commande avec les détails des produits.
  Future<List<PurchaseOrderItemWithProduct>> getPurchaseOrderItemsWithProducts(
    int purchaseOrderId,
  ) {
    final query = select(purchaseOrderItems).join([
      innerJoin(products, products.id.equalsExp(purchaseOrderItems.productId)),
    ])..where(purchaseOrderItems.purchaseOrderId.equals(purchaseOrderId));

    return query.map((row) {
      return PurchaseOrderItemWithProduct(
        item: row.readTable(purchaseOrderItems),
        product: row.readTable(products),
      );
    }).get();
  }

  /// Valide la réception d'un bon de commande, met à jour les stocks et le prix de revient.
  Future<void> validatePurchaseOrderReception({
    required int purchaseOrderId,
    required int userId,
    Map<int, int>? actualQuantities,
  }) async {
    final myShopId = await getSetting('shop_id') ?? '';
    final terminalId = await getSetting('terminal_id') ?? '';

    return transaction(() async {
      // 1. Récupérer le bon de commande
      final po = await (select(
        purchaseOrders,
      )..where((p) => p.id.equals(purchaseOrderId))).getSingle();

      if (po.status == 'received') {
        throw Exception('Ce bon de commande a déjà été réceptionné.');
      }
      if (po.status == 'cancelled') {
        throw Exception('Ce bon de commande est annulé.');
      }

      // 2. Mettre à jour le statut du BC
      await (update(
        purchaseOrders,
      )..where((p) => p.id.equals(purchaseOrderId))).write(
        PurchaseOrdersCompanion(
          status: const Value('received'),
          receivedAt: Value(DateTime.now()),
        ),
      );

      // 3. Récupérer les articles du BC
      final items = await (select(
        purchaseOrderItems,
      )..where((i) => i.purchaseOrderId.equals(purchaseOrderId))).get();

      for (final item in items) {
        // Quantité reçue réelle (ou celle du BC par défaut)
        final receivedQty = actualQuantities?[item.id] ?? item.quantity;

        // A. Mettre à jour la ligne du BC
        await (update(
          purchaseOrderItems,
        )..where((i) => i.id.equals(item.id))).write(
          PurchaseOrderItemsCompanion(quantityReceived: Value(receivedQty)),
        );

        // 4. Mettre à jour le produit (Stock + Prix de revient mis à jour au dernier prix d'achat)
        final product = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingle();
        final newQty = product.stockQty + receivedQty;

        await (update(
          products,
        )..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            stockQty: Value(newQty),
            costPrice: Value(item.unitCost),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // 5. Créer un mouvement de stock de type 'purchase_in' pour l'audit
        final movementId = await into(stockMovements).insert(
          StockMovementsCompanion(
            productId: Value(item.productId),
            shopId: Value(myShopId),
            userId: Value(userId),
            type: const Value('purchase_in'),
            qtyDelta: Value(receivedQty),
            qtyAfter: Value(newQty),
            terminalId: Value(terminalId),
            reason: Value('Réception BC ${po.ref}'),
          ),
        );

        // 6. Synchronisation du mouvement et du produit mis à jour
        final movementData = await (select(
          stockMovements,
        )..where((m) => m.id.equals(movementId))).getSingle();
        await enqueue(
          entityType: 'stock_movement',
          entityId: movementId,
          payload: movementData.toJson(),
          shopId: myShopId,
        );

        final updatedProduct = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingle();
        await enqueue(
          entityType: 'product',
          entityId: item.productId,
          payload: updatedProduct.toJson(),
          shopId: myShopId,
        );

        // Synchronisation de la ligne de commande mise à jour (avec quantity_received)
        final updatedItem = await (select(
          purchaseOrderItems,
        )..where((i) => i.id.equals(item.id))).getSingle();
        await enqueue(
          entityType: 'purchase_order_item',
          entityId: item.id,
          payload: updatedItem.toJson(),
          shopId: myShopId,
        );
      }

      // 7. Synchronisation du bon de commande vers Supabase
      final updatedPo = await (select(
        purchaseOrders,
      )..where((p) => p.id.equals(purchaseOrderId))).getSingle();
      await enqueue(
        entityType: 'purchase_order',
        entityId: purchaseOrderId,
        payload: updatedPo.toJson(),
        shopId: myShopId,
      );
    });
  }

  /// Annule une vente, rembourse le montant et réintègre les produits en stock.
  Future<void> refundSale({required int saleId, required int userId}) async {
    final terminalId = await getSetting('terminal_id') ?? '';

    return transaction(() async {
      // 1. Récupérer la vente originale
      final sale = await (select(
        sales,
      )..where((s) => s.id.equals(saleId))).getSingle();

      if (sale.isRefunded) {
        throw Exception('Cette vente a déjà été remboursée.');
      }

      // Vérification du délai de 30 jours (Local)
      final difference = DateTime.now().difference(sale.createdAt);
      if (difference.inDays > 30) {
        throw Exception('Le délai de remboursement de 30 jours est dépassé.');
      }

      // 2. Mettre à jour le statut de la vente
      await (update(sales)..where((s) => s.id.equals(saleId))).write(
        SalesCompanion(
          isRefunded: const Value(true),
          refundedAmount: Value(sale.totalTtc),
          status: const Value('refunded'),
        ),
      );

      // 3. Récupérer les articles de la vente
      final items = await (select(
        saleItems,
      )..where((si) => si.saleId.equals(saleId))).get();

      for (final item in items) {
        // 4. Réintégrer le stock
        await updateStock(item.productId, item.quantity);

        // 5. Créer un mouvement de stock de type 'refund' pour l'audit
        final productAfter = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingle();
        final movementId = await into(stockMovements).insert(
          StockMovementsCompanion(
            productId: Value(item.productId),
            shopId: Value(sale.shopId),
            userId: Value(userId),
            type: const Value('refund'),
            qtyDelta: Value(item.quantity),
            qtyAfter: Value(productAfter.stockQty),
            terminalId: Value(terminalId),
            reason: Value('Remboursement de la vente ${sale.ref}'),
          ),
        );

        // Synchroniser le mouvement de stock
        final movementData = await (select(
          stockMovements,
        )..where((m) => m.id.equals(movementId))).getSingle();
        await enqueue(
          entityType: 'stock_movement',
          entityId: movementId,
          payload: movementData.toJson(),
          shopId: sale.shopId,
        );
      }

      // 6. Synchronisation atomique via le RPC 'refund'
      // On n'envoie pas le type 'sale' mais 'refund' pour déclencher process_sale_refund sur Supabase.
      await enqueue(
        entityType: 'refund',
        entityId: saleId,
        payload: {
          'local_id': saleId,
          'user_id': userId,
          'terminal_id': terminalId,
          'shop_id': sale.shopId,
          'shop_id_sync': sale.shopId,
        },
        shopId: sale.shopId,
      );
    });
  }

  /// Enregistre un paiement partiel ou total pour une vente à crédit.
  Future<void> recordPayment({
    required int saleId,
    required String paymentMethod,
    required double amountPaid,
    required int userId,
  }) async {
    final terminalId = await getSetting('terminal_id') ?? '';

    return transaction(() async {
      final sale = await (select(
        sales,
      )..where((s) => s.id.equals(saleId))).getSingle();

      if (sale.isRefunded) {
        throw Exception(
          'Cette vente a été remboursée et ne peut pas recevoir de paiement.',
        );
      }
      if (sale.amountDue <= 0) {
        throw Exception('Cette vente est déjà entièrement payée.');
      }

      final newAmountDue = sale.amountDue - amountPaid;
      final newPaymentStatus = newAmountDue <= 0 ? 'paid' : 'partially_paid';

      await (update(sales)..where((s) => s.id.equals(saleId))).write(
        SalesCompanion(
          amountDue: Value(newAmountDue),
          paymentStatus: Value(newPaymentStatus),
        ),
      );

      final paymentId = await into(payments).insert(
        PaymentsCompanion.insert(
          saleId: saleId,
          method: paymentMethod,
          amount: amountPaid,
          terminalId: Value(terminalId),
          paidAt: Value(DateTime.now()),
        ),
      );

      // SYNCHRO : Envoyer le reçu de paiement
      final paymentData = await (select(
        payments,
      )..where((p) => p.id.equals(paymentId))).getSingle();
      await enqueue(
        entityType: 'payment',
        entityId: paymentId,
        payload: paymentData.toJson(),
        shopId: sale.shopId,
      );

      final updatedSale = await (select(
        sales,
      )..where((s) => s.id.equals(saleId))).getSingle();
      await enqueue(
        entityType: 'sale',
        entityId: saleId,
        payload: updatedSale.toJson(),
        shopId: sale.shopId,
      );
    });
  }

  /// Enregistre un paiement pour plusieurs ventes d'un coup.
  /// Le montant est réparti sur les ventes sélectionnées (par ordre chronologique).
  Future<void> recordBulkPayment({
    required List<int> saleIds,
    required String paymentMethod,
    required double totalAmountPaid,
    required int userId,
  }) async {
    final terminalId = await getSetting('terminal_id') ?? '';

    return transaction(() async {
      double remaining = totalAmountPaid;
      final salesList =
          await (select(sales)
                ..where((s) => s.id.isIn(saleIds))
                ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
              .get();

      for (final sale in salesList) {
        if (remaining <= 0) break;
        final toPay = remaining < sale.amountDue ? remaining : sale.amountDue;

        final newAmountDue = sale.amountDue - toPay;
        final newPaymentStatus = newAmountDue <= 0 ? 'paid' : 'partially_paid';

        await (update(sales)..where((s) => s.id.equals(sale.id))).write(
          SalesCompanion(
            amountDue: Value(newAmountDue),
            paymentStatus: Value(newPaymentStatus),
          ),
        );

        final paymentId = await into(payments).insert(
          PaymentsCompanion.insert(
            saleId: sale.id,
            method: paymentMethod,
            amount: toPay,
            terminalId: Value(terminalId),
            paidAt: Value(DateTime.now()),
          ),
        );

        // SYNCHRO : Envoyer le reçu de paiement pour cette ligne de la dette
        final paymentData = await (select(
          payments,
        )..where((p) => p.id.equals(paymentId))).getSingle();
        await enqueue(
          entityType: 'payment',
          entityId: paymentId,
          payload: paymentData.toJson(),
          shopId: sale.shopId,
        );

        final updatedSale = await (select(
          sales,
        )..where((s) => s.id.equals(sale.id))).getSingle();
        await enqueue(
          entityType: 'sale',
          entityId: sale.id,
          payload: updatedSale.toJson(),
          shopId: sale.shopId,
        );

        remaining -= toPay;
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
    int defectiveQty = 0,
    int obsoleteQty = 0,
    int expiredQty = 0,
    String? notes,
  }) async {
    return transaction(() async {
      final line = await (select(
        inventoryLines,
      )..where((l) => l.id.equals(lineId))).getSingle();

      await (update(inventoryLines)..where((l) => l.id.equals(lineId))).write(
        InventoryLinesCompanion(
          countedQty: Value(countedQty),
          difference: Value(countedQty - line.expectedQty),
          defectiveQty: Value(defectiveQty),
          obsoleteQty: Value(obsoleteQty),
          expiredQty: Value(expiredQty),
          isValidated: const Value(true),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // SYNCHRO : Permet aux autres terminaux de voir l'avancement du comptage
      final lineData = await (select(
        inventoryLines,
      )..where((l) => l.id.equals(lineId))).getSingle();
      await enqueue(
        entityType: 'inventory_line',
        entityId: lineId,
        payload: lineData.toJson(),
        shopId: line.shopId,
      );
    });
  }

  /// Enregistre une perte ponctuelle (hors session d'inventaire)
  Future<void> recordLoss({
    required int productId,
    required int quantity,
    required String type, // 'defective', 'obsolete', 'expired'
    required int userId,
    String? notes,
    String? imagePath, // NOUVEAU
  }) async {
    final shopId = await getSetting('shop_id') ?? '';
    final terminalId = await getSetting('terminal_id') ?? '';
    return transaction(() async {
      final product = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();
      final newQty = product.stockQty - quantity;

      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          stockQty: Value(newQty),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Correction de l'insertion du mouvement de stock
      final movementId = await into(stockMovements).insert(
        StockMovementsCompanion(
          productId: Value(productId),
          shopId: Value(shopId),
          userId: Value(userId),
          type: Value('loss_$type'),
          qtyDelta: Value(-quantity),
          qtyAfter: Value(newQty),
          terminalId: Value(terminalId),
          imagePath: Value(imagePath),
          reason: Value('Perte ($type): ${notes ?? ""}'),
        ),
      );

      final movementData = await (select(
        stockMovements,
      )..where((m) => m.id.equals(movementId))).getSingle();
      await enqueue(
        entityType: 'stock_movement',
        entityId: movementId,
        payload: movementData.toJson(),
        shopId: shopId,
      );

      final updatedProduct = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();
      await enqueue(
        entityType: 'product',
        entityId: productId,
        payload: updatedProduct.toJson(),
        shopId: shopId,
      );
    });
  }

  Future<InventoryLine?> getInventoryLineByBarcode(
    int sessionId,
    String barcode,
  ) =>
      (select(inventoryLines)..where(
            (l) => l.sessionId.equals(sessionId) & l.barcode.equals(barcode),
          ))
          .getSingleOrNull();

  Future<void> validateInventorySession({
    required int sessionId,
    required int userId,
  }) async {
    return transaction(() async {
      final session = await (select(
        inventorySessions,
      )..where((s) => s.id.equals(sessionId))).getSingle();
      final lines = await getInventoryLines(sessionId);
      final validated = lines
          .where((l) => l.isValidated && l.countedQty != null)
          .toList();

      int discrepancyCount = 0;
      for (final line in validated) {
        final counted = line.countedQty!;
        final delta =
            counted - line.expectedQty; // Ajout de la définition de delta

        // 1. Traitement de l'ajustement d'inventaire principal (si écart)
        if (delta != 0) {
          discrepancyCount++; // Increment discrepancy count
          await (update(
            products,
          )..where((p) => p.id.equals(line.productId))).write(
            ProductsCompanion(
              stockQty: Value(counted),
              updatedAt: Value(DateTime.now()),
            ),
          );

          final movementId = await into(stockMovements).insert(
            StockMovementsCompanion(
              productId: Value(line.productId),
              shopId: Value(session.shopId),
              userId: Value(userId),
              type: const Value('inventory'),
              qtyDelta: Value(delta),
              qtyAfter: Value(counted),
              reason: Value('Inventaire ${session.ref}'),
              inventoryRef: Value(session.ref), // Envelopper dans Value
            ),
          );

          final movementData = await (select(
            stockMovements,
          )..where((m) => m.id.equals(movementId))).getSingle();
          await enqueue(
            entityType: 'stock_movement',
            entityId: movementId,
            payload: movementData.toJson(),
            shopId: session.shopId,
          );

          // AJOUT : Synchroniser le produit mis à jour même s'il n'y a pas de pertes spécifiques
          final updatedProduct = await (select(
            products,
          )..where((p) => p.id.equals(line.productId))).getSingle();
          await enqueue(
            entityType: 'product',
            entityId: line.productId,
            payload: updatedProduct.toJson(),
            shopId: session.shopId,
          );
        }

        // Sécurité : Ré-envoyer la ligne validée pour garantir que Supabase a le comptage final
        await enqueue(
          entityType: 'inventory_line',
          entityId: line.id,
          payload: line.toJson(),
          shopId: session.shopId,
        );

        // 2. Traitement des pertes spécifiques (défectueux, obsolètes, périmés)
        // Ces produits sont déduits du stock marchandisable final
        if (line.defectiveQty > 0) {
          await recordLoss(
            productId: line.productId,
            quantity: line.defectiveQty,
            type: 'defective',
            userId: userId,
            notes: 'Inventaire ${session.ref}',
          );
        }
        if (line.obsoleteQty > 0) {
          await recordLoss(
            productId: line.productId,
            quantity: line.obsoleteQty,
            type: 'obsolete',
            userId: userId,
            notes: 'Inventaire ${session.ref}',
          );
        }
        if (line.expiredQty > 0) {
          await recordLoss(
            productId: line.productId,
            quantity: line.expiredQty,
            type: 'expired',
            userId: userId,
            notes: 'Inventaire ${session.ref}',
          );
        }
      }

      await (update(
        inventorySessions,
      )..where((s) => s.id.equals(sessionId))).write(
        InventorySessionsCompanion(
          status: const Value('completed'),
          shopId: Value(session.shopId),
          discrepancies: Value(discrepancyCount),
          completedAt: Value(DateTime.now()),
        ),
      );

      // SYNCHRO : Envoyer la mise à jour de la session au cloud
      final updatedSession = await (select(
        inventorySessions,
      )..where((s) => s.id.equals(sessionId))).getSingle();
      await enqueue(
        entityType: 'inventory_session',
        entityId: sessionId,
        payload: updatedSession.toJson(),
        shopId: session.shopId,
      );
    });
  }

  Stream<List<InventorySession>> watchInventorySessions() => (select(
    inventorySessions,
  )..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).watch();

  // ── PARAMÈTRES ────────────────────────────────────────────────

  Future<String?> getSetting(String key) async => (await (select(
    appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) async => into(
    appSettings,
  ).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  /// Supprime un produit localement (soft delete) et planifie la suppression sur Supabase.
  Future<void> deleteProduct(int productId, int actorId) async {
    await transaction(() async {
      // 0. Récupérer le produit pour avoir son nom dans le log d'audit
      final product = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();

      // 1. Désactivation locale. Utiliser ProductsCompanion() et NON ProductsCompanion.insert()
      // pour éviter de devoir fournir tous les champs obligatoires.
      // 1. Désactivation locale et mise à jour de la date
      await (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          isActive: const Value(false),
          shopId: const Value.absent(),
          name: const Value.absent(),
          priceHt: const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      final updatedProduct = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();

      // 2. Enregistrer le log d'audit
      await addAuditLog(
        actorId: actorId,
        action: 'product_deleted',
        targetEntityType: 'product',
        targetEntityId: productId,
        details: jsonEncode({'productName': product.name}),
      );

      // 3. Ajout à la file de synchronisation avec l'action 'upsert' (Soft Delete)
      await enqueue(
        entityType: 'product',
        entityId: productId,
        action: 'upsert',
        shopId: updatedProduct.shopId,
        payload: updatedProduct.toJson(),
      );
    });
  }

  // ── UTILITAIRES ───────────────────────────────────────────────

  String _p(int n) => n.toString().padLeft(2, '0');

  // ── MÉTHODES REQUISES PAR LE SYSTÈME ─────────────────────────

  /// Met à jour le stock d'un produit localement par un delta et l'ajoute à la file de synchronisation.
  Future<void> updateStock(int productId, int qtyDelta) async {
    final product = await (select(
      products,
    )..where((p) => p.id.equals(productId))).getSingle();
    final newQty = product.stockQty + qtyDelta;

    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        stockQty: Value(newQty),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final currentShopId = await getSetting('shop_id');
    await enqueue(
      entityType: 'stock_delta',
      entityId: productId,
      action: 'delta',
      shopId: currentShopId,
      payload: {'product_local_id': productId, 'qty_delta': qtyDelta},
    );
  }

  /// Stream des produits actifs avec filtre texte et catégorie
  Stream<List<Product>> watchProducts({String query = '', int? categoryId}) {
    final queryStmt = select(products);
    queryStmt.where((p) {
      Expression<bool> filter = p.isActive.equals(true);
      if (query.isNotEmpty) {
        filter =
            filter & (p.name.like('%$query%') | p.barcode.like('%$query%'));
      }
      if (categoryId != null) {
        filter = filter & p.categoryId.equals(categoryId);
      }
      return filter;
    });
    queryStmt.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return queryStmt.watch();
  }

  /// Surveille les entrées de la file de synchronisation en erreur.
  Stream<List<SyncQueueData>> watchSyncErrors() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('error'))
          ..orderBy([(q) => OrderingTerm.desc(q.updatedAt)]))
        .watch();
  }

  /// Réinitialise une entrée de synchronisation en erreur pour une nouvelle tentative.
  Future<void> retrySync(String entityType, int entityId) {
    return (update(syncQueue)..where(
          (q) => q.entityType.equals(entityType) & q.entityId.equals(entityId),
        ))
        .write(
          SyncQueueCompanion(
            status: const Value('pending'),
            retryCount: const Value(0),
            errorMessage: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Réinitialise toutes les erreurs de synchronisation liées au réseau ou au serveur.
  Future<void> resetTransientErrors() {
    return (update(syncQueue)..where(
          (q) =>
              q.status.equals('error') &
              (q.errorMessage.like('%connexion%') |
                  q.errorMessage.like('%réseau%') |
                  q.errorMessage.like('%serveur%')),
        ))
        .write(
          SyncQueueCompanion(
            status: const Value('pending'),
            retryCount: const Value(0),
            errorMessage: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Vide complètement la file d'attente de synchronisation.
  Future<void> clearSyncQueue() {
    return delete(syncQueue).go();
  }

  /// Ajoute une opération à la file de synchronisation Supabase.
  Future<int> enqueue({
    required String entityType,
    required int entityId,
    required Map<String, dynamic> payload,
    String action = 'upsert',
    String? shopId,
    String? terminalId,
  }) {
    final encodedPayload = jsonEncode(payload);
    final companion = SyncQueueCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      action: Value(action),
      payload: encodedPayload,
      status: const Value('pending'),
      updatedAt: Value(DateTime.now()),
      shopId: Value.absentIfNull(shopId),
      terminalId: Value.absentIfNull(terminalId),
    );
    return into(syncQueue).insertOnConflictUpdate(companion);
  }
}

extension ProductExtension on Product {
  /// Calcule le prix TTC de manière sécurisée (gère le taux de taxe nul).
  double get priceTtc => priceHt * (1 + (taxRate ?? 0.0));

  /// Retourne vrai si le produit est en alerte de stock.
  bool get isLowStock => stockQty <= stockAlert && stockQty > 0;

  /// Retourne vrai si le produit est en rupture totale.
  bool get isOutOfStock => stockQty <= 0;

  /// Reconstruit le chemin absolu de l'image de manière dynamique.
  /// Indispensable pour la survie des liens après une mise à jour sur iOS.
  Future<String?> get absoluteImagePath async {
    if (imagePath == null || imagePath!.isEmpty) return null;

    // Si le chemin stocké est déjà absolu (ancienne version), on le retourne tel quel
    if (imagePath!.startsWith('/') || imagePath!.contains(':\\')) {
      return imagePath;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'product_images', imagePath);

    return path;
  }
}

// ── EXTENSIONS DE SERVICES ─────────────────────────────────

extension StockPredictorDbExtension on PosDatabase {
  /// Récupère les mouvements de stock d'un produit depuis une date
  Future<List<StockMovement>> getStockMovementsForProduct({
    required int productId,
    required DateTime since,
    String? type,
  }) async {
    final query = select(stockMovements)
      ..where(
        (m) =>
            m.productId.equals(productId) &
            m.movedAt.isBiggerOrEqualValue(since),
      );
    if (type != null) {
      query.where((m) => m.type.equals(type));
    }
    query.orderBy([(m) => OrderingTerm.asc(m.movedAt)]);
    return query.get();
  }

  /// Récupère tous les produits actifs
  Future<List<Product>> getActiveProducts() async {
    return (select(products)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }
}

extension AiReportDbExtension on PosDatabase {
  Future<List<Sale>> getSalesInPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    return (select(sales)..where(
          (s) =>
              s.createdAt.isBiggerOrEqualValue(from) &
              s.createdAt.isSmallerThanValue(to) &
              s.status.equals('completed'),
        ))
        .get();
  }

  Future<List<SaleItem>> getSaleItemsForSales(List<int> saleIds) async {
    if (saleIds.isEmpty) return [];
    return (select(saleItems)..where((i) => i.saleId.isIn(saleIds))).get();
  }

  Future<List<Product>> getLowStockProductsInExtension() async {
    return (select(products)
          ..where(
            (p) =>
                p.isActive.equals(true) &
                p.stockQty.isSmallerOrEqual(p.stockAlert),
          )
          ..orderBy([(p) => OrderingTerm.asc(p.stockQty)]))
        .get();
  }
}

extension LicenseDbExtension on PosDatabase {
  Future<int> getActiveProductsCount() async {
    final result = await (select(
      products,
    )..where((p) => p.isActive.equals(true))).get();
    return result.length;
  }
}
